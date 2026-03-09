"""
Salesforce REST API Client

Core client for all Salesforce operations:
- CRUD operations
- SOQL queries
- Composite requests
- Metadata operations
"""

import json
import requests
from typing import Any, Dict, List, Optional, Union
from dataclasses import dataclass
from tenacity import retry, stop_after_attempt, wait_exponential
import structlog

from ..auth.oauth import SalesforceAuth

logger = structlog.get_logger()


@dataclass
class QueryResult:
    """SOQL query result"""
    total_size: int
    done: bool
    records: List[Dict[str, Any]]
    next_records_url: Optional[str] = None


class SalesforceClient:
    """
    Salesforce REST API client.

    Handles all CRUD operations, queries, and composite requests.
    Optimized for high-volume autonomous operations.
    """

    API_VERSION = "v59.0"

    def __init__(self, auth: SalesforceAuth):
        self.auth = auth
        self._session = requests.Session()

    @property
    def base_url(self) -> str:
        """Get base URL for API requests"""
        return f"{self.auth.token.instance_url}/services/data/{self.API_VERSION}"

    @property
    def headers(self) -> dict:
        """Get headers for API requests"""
        return self.auth.headers

    # ==================== CRUD Operations ====================

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=10))
    def create(self, sobject: str, data: Dict[str, Any]) -> str:
        """
        Create a new record.

        Args:
            sobject: Salesforce object name (e.g., 'Client_Household__c')
            data: Field values for the new record

        Returns:
            ID of the created record
        """
        url = f"{self.base_url}/sobjects/{sobject}"

        response = self._session.post(url, headers=self.headers, json=data)

        if response.status_code == 201:
            result = response.json()
            logger.info("record_created", sobject=sobject, id=result['id'])
            return result['id']
        else:
            self._handle_error(response, "create", sobject)

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=10))
    def get(self, sobject: str, record_id: str, fields: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        Get a record by ID.

        Args:
            sobject: Salesforce object name
            record_id: Record ID
            fields: Optional list of fields to retrieve

        Returns:
            Record data
        """
        url = f"{self.base_url}/sobjects/{sobject}/{record_id}"

        if fields:
            url += f"?fields={','.join(fields)}"

        response = self._session.get(url, headers=self.headers)

        if response.status_code == 200:
            return response.json()
        else:
            self._handle_error(response, "get", sobject, record_id)

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=10))
    def update(self, sobject: str, record_id: str, data: Dict[str, Any]) -> bool:
        """
        Update an existing record.

        Args:
            sobject: Salesforce object name
            record_id: Record ID
            data: Field values to update

        Returns:
            True if successful
        """
        url = f"{self.base_url}/sobjects/{sobject}/{record_id}"

        response = self._session.patch(url, headers=self.headers, json=data)

        if response.status_code == 204:
            logger.info("record_updated", sobject=sobject, id=record_id)
            return True
        else:
            self._handle_error(response, "update", sobject, record_id)

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=10))
    def delete(self, sobject: str, record_id: str) -> bool:
        """
        Delete a record.

        Args:
            sobject: Salesforce object name
            record_id: Record ID

        Returns:
            True if successful
        """
        url = f"{self.base_url}/sobjects/{sobject}/{record_id}"

        response = self._session.delete(url, headers=self.headers)

        if response.status_code == 204:
            logger.info("record_deleted", sobject=sobject, id=record_id)
            return True
        else:
            self._handle_error(response, "delete", sobject, record_id)

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=10))
    def upsert(self, sobject: str, external_id_field: str, external_id: str, data: Dict[str, Any]) -> str:
        """
        Upsert a record using an external ID.

        Args:
            sobject: Salesforce object name
            external_id_field: External ID field name
            external_id: External ID value
            data: Field values

        Returns:
            Record ID
        """
        url = f"{self.base_url}/sobjects/{sobject}/{external_id_field}/{external_id}"

        response = self._session.patch(url, headers=self.headers, json=data)

        if response.status_code in (200, 201, 204):
            if response.status_code == 204:
                # Update - no body returned
                return external_id
            result = response.json()
            return result.get('id', external_id)
        else:
            self._handle_error(response, "upsert", sobject, external_id)

    # ==================== Query Operations ====================

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=10))
    def query(self, soql: str) -> QueryResult:
        """
        Execute a SOQL query.

        Args:
            soql: SOQL query string

        Returns:
            QueryResult with records
        """
        url = f"{self.base_url}/query"

        response = self._session.get(url, headers=self.headers, params={'q': soql})

        if response.status_code == 200:
            data = response.json()
            return QueryResult(
                total_size=data['totalSize'],
                done=data['done'],
                records=data['records'],
                next_records_url=data.get('nextRecordsUrl')
            )
        else:
            self._handle_error(response, "query", soql=soql)

    def query_all(self, soql: str) -> List[Dict[str, Any]]:
        """
        Execute a SOQL query and return all records (handles pagination).

        Args:
            soql: SOQL query string

        Returns:
            List of all matching records
        """
        all_records = []
        result = self.query(soql)
        all_records.extend(result.records)

        while not result.done and result.next_records_url:
            result = self._query_more(result.next_records_url)
            all_records.extend(result.records)

        logger.info("query_completed", total_records=len(all_records))
        return all_records

    def _query_more(self, next_url: str) -> QueryResult:
        """Get next page of query results"""
        url = f"{self.auth.token.instance_url}{next_url}"

        response = self._session.get(url, headers=self.headers)

        if response.status_code == 200:
            data = response.json()
            return QueryResult(
                total_size=data['totalSize'],
                done=data['done'],
                records=data['records'],
                next_records_url=data.get('nextRecordsUrl')
            )
        else:
            self._handle_error(response, "query_more")

    def search(self, sosl: str) -> List[Dict[str, Any]]:
        """
        Execute a SOSL search.

        Args:
            sosl: SOSL search string

        Returns:
            Search results
        """
        url = f"{self.base_url}/search"

        response = self._session.get(url, headers=self.headers, params={'q': sosl})

        if response.status_code == 200:
            return response.json().get('searchRecords', [])
        else:
            self._handle_error(response, "search", sosl=sosl)

    # ==================== Composite Operations ====================

    def composite(self, requests: List[Dict[str, Any]], all_or_none: bool = False) -> List[Dict[str, Any]]:
        """
        Execute multiple operations in a single API call.

        Args:
            requests: List of subrequest definitions
            all_or_none: If True, roll back all if any fails

        Returns:
            List of subrequest results
        """
        url = f"{self.base_url}/composite"

        payload = {
            'allOrNone': all_or_none,
            'compositeRequest': requests
        }

        response = self._session.post(url, headers=self.headers, json=payload)

        if response.status_code == 200:
            return response.json().get('compositeResponse', [])
        else:
            self._handle_error(response, "composite")

    def composite_tree(self, sobject: str, records: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Create multiple related records in a single call.

        Args:
            sobject: Parent object type
            records: Parent records with nested child records

        Returns:
            Creation results
        """
        url = f"{self.base_url}/composite/tree/{sobject}"

        payload = {'records': records}

        response = self._session.post(url, headers=self.headers, json=payload)

        if response.status_code == 201:
            return response.json()
        else:
            self._handle_error(response, "composite_tree", sobject)

    # ==================== Metadata Operations ====================

    def describe(self, sobject: str) -> Dict[str, Any]:
        """Get object metadata"""
        url = f"{self.base_url}/sobjects/{sobject}/describe"

        response = self._session.get(url, headers=self.headers)

        if response.status_code == 200:
            return response.json()
        else:
            self._handle_error(response, "describe", sobject)

    def get_limits(self) -> Dict[str, Any]:
        """Get org limits"""
        url = f"{self.base_url}/limits"

        response = self._session.get(url, headers=self.headers)

        if response.status_code == 200:
            return response.json()
        else:
            self._handle_error(response, "limits")

    # ==================== Error Handling ====================

    def _handle_error(self, response: requests.Response, operation: str, sobject: str = None, record_id: str = None, **kwargs):
        """Handle API errors"""
        try:
            error_data = response.json()
        except:
            error_data = {'message': response.text}

        logger.error(
            "salesforce_api_error",
            operation=operation,
            sobject=sobject,
            record_id=record_id,
            status_code=response.status_code,
            error=error_data,
            **kwargs
        )

        raise SalesforceAPIError(
            f"API Error ({response.status_code}): {error_data}",
            status_code=response.status_code,
            error_data=error_data
        )


class SalesforceAPIError(Exception):
    """Salesforce API error"""
    def __init__(self, message: str, status_code: int = None, error_data: dict = None):
        super().__init__(message)
        self.status_code = status_code
        self.error_data = error_data or {}
