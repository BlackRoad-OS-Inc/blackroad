"""
Production-grade CRM adapter with support for multiple CRM backends.

Supported backends:
- Salesforce
- HubSpot
- Generic REST API
- Mock (for testing)
"""
import logging
import os
from abc import ABC, abstractmethod
from typing import Any, Dict, Optional
from enum import Enum
import time

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger(__name__)


class CRMBackend(Enum):
    """Supported CRM backends."""
    SALESFORCE = "salesforce"
    HUBSPOT = "hubspot"
    GENERIC = "generic"
    MOCK = "mock"


class CRMError(Exception):
    """Base exception for CRM operations."""
    pass


class CRMAdapter(ABC):
    """Abstract base class for CRM adapters."""

    @abstractmethod
    def update(self, record: Dict[str, Any]) -> Dict[str, Any]:
        """Update a CRM record."""
        pass

    @abstractmethod
    def create(self, record: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new CRM record."""
        pass

    @abstractmethod
    def get(self, record_id: str) -> Dict[str, Any]:
        """Retrieve a CRM record."""
        pass

    @abstractmethod
    def delete(self, record_id: str) -> bool:
        """Delete a CRM record."""
        pass


class SalesforceAdapter(CRMAdapter):
    """Salesforce CRM adapter."""

    def __init__(self, instance_url: str, access_token: str):
        """
        Initialize Salesforce adapter.

        Args:
            instance_url: Salesforce instance URL (e.g., https://na1.salesforce.com)
            access_token: OAuth access token
        """
        self.instance_url = instance_url.rstrip('/')
        self.access_token = access_token
        self.session = self._create_session()
        logger.info(f"Initialized Salesforce adapter for {instance_url}")

    def _create_session(self) -> requests.Session:
        """Create requests session with retry logic."""
        session = requests.Session()
        retry = Retry(
            total=3,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504]
        )
        adapter = HTTPAdapter(max_retries=retry)
        session.mount('https://', adapter)
        session.headers.update({
            'Authorization': f'Bearer {self.access_token}',
            'Content-Type': 'application/json'
        })
        return session

    def update(self, record: Dict[str, Any]) -> Dict[str, Any]:
        """Update a Salesforce record."""
        record_id = record.get('Id')
        record_type = record.get('type', 'Account')

        if not record_id:
            raise CRMError("Record must have 'Id' field")

        url = f"{self.instance_url}/services/data/v58.0/sobjects/{record_type}/{record_id}"

        # Remove metadata fields
        data = {k: v for k, v in record.items() if k not in ['Id', 'type']}

        try:
            response = self.session.patch(url, json=data)
            response.raise_for_status()
            logger.info(f"Updated Salesforce {record_type} record {record_id}")
            return {'success': True, 'id': record_id}
        except requests.RequestException as e:
            logger.error(f"Failed to update Salesforce record: {e}")
            raise CRMError(f"Failed to update record: {e}")

    def create(self, record: Dict[str, Any]) -> Dict[str, Any]:
        """Create a Salesforce record."""
        record_type = record.get('type', 'Account')
        url = f"{self.instance_url}/services/data/v58.0/sobjects/{record_type}"

        data = {k: v for k, v in record.items() if k != 'type'}

        try:
            response = self.session.post(url, json=data)
            response.raise_for_status()
            result = response.json()
            logger.info(f"Created Salesforce {record_type} record {result['id']}")
            return result
        except requests.RequestException as e:
            logger.error(f"Failed to create Salesforce record: {e}")
            raise CRMError(f"Failed to create record: {e}")

    def get(self, record_id: str, record_type: str = 'Account') -> Dict[str, Any]:
        """Retrieve a Salesforce record."""
        url = f"{self.instance_url}/services/data/v58.0/sobjects/{record_type}/{record_id}"

        try:
            response = self.session.get(url)
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Failed to get Salesforce record: {e}")
            raise CRMError(f"Failed to get record: {e}")

    def delete(self, record_id: str, record_type: str = 'Account') -> bool:
        """Delete a Salesforce record."""
        url = f"{self.instance_url}/services/data/v58.0/sobjects/{record_type}/{record_id}"

        try:
            response = self.session.delete(url)
            response.raise_for_status()
            logger.info(f"Deleted Salesforce {record_type} record {record_id}")
            return True
        except requests.RequestException as e:
            logger.error(f"Failed to delete Salesforce record: {e}")
            raise CRMError(f"Failed to delete record: {e}")


class HubSpotAdapter(CRMAdapter):
    """HubSpot CRM adapter."""

    def __init__(self, api_key: str):
        """
        Initialize HubSpot adapter.

        Args:
            api_key: HubSpot API key
        """
        self.api_key = api_key
        self.base_url = "https://api.hubapi.com"
        self.session = self._create_session()
        logger.info("Initialized HubSpot adapter")

    def _create_session(self) -> requests.Session:
        """Create requests session with retry logic."""
        session = requests.Session()
        retry = Retry(
            total=3,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504]
        )
        adapter = HTTPAdapter(max_retries=retry)
        session.mount('https://', adapter)
        session.headers.update({
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json'
        })
        return session

    def update(self, record: Dict[str, Any]) -> Dict[str, Any]:
        """Update a HubSpot contact."""
        record_id = record.get('id')
        if not record_id:
            raise CRMError("Record must have 'id' field")

        url = f"{self.base_url}/crm/v3/objects/contacts/{record_id}"
        properties = {k: v for k, v in record.items() if k != 'id'}

        try:
            response = self.session.patch(url, json={'properties': properties})
            response.raise_for_status()
            logger.info(f"Updated HubSpot contact {record_id}")
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Failed to update HubSpot contact: {e}")
            raise CRMError(f"Failed to update contact: {e}")

    def create(self, record: Dict[str, Any]) -> Dict[str, Any]:
        """Create a HubSpot contact."""
        url = f"{self.base_url}/crm/v3/objects/contacts"
        properties = {k: v for k, v in record.items()}

        try:
            response = self.session.post(url, json={'properties': properties})
            response.raise_for_status()
            result = response.json()
            logger.info(f"Created HubSpot contact {result['id']}")
            return result
        except requests.RequestException as e:
            logger.error(f"Failed to create HubSpot contact: {e}")
            raise CRMError(f"Failed to create contact: {e}")

    def get(self, record_id: str) -> Dict[str, Any]:
        """Retrieve a HubSpot contact."""
        url = f"{self.base_url}/crm/v3/objects/contacts/{record_id}"

        try:
            response = self.session.get(url)
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Failed to get HubSpot contact: {e}")
            raise CRMError(f"Failed to get contact: {e}")

    def delete(self, record_id: str) -> bool:
        """Delete a HubSpot contact."""
        url = f"{self.base_url}/crm/v3/objects/contacts/{record_id}"

        try:
            response = self.session.delete(url)
            response.raise_for_status()
            logger.info(f"Deleted HubSpot contact {record_id}")
            return True
        except requests.RequestException as e:
            logger.error(f"Failed to delete HubSpot contact: {e}")
            raise CRMError(f"Failed to delete contact: {e}")


class MockAdapter(CRMAdapter):
    """Mock CRM adapter for testing."""

    def __init__(self):
        """Initialize mock adapter."""
        self.records = {}
        self.next_id = 1
        logger.info("Initialized Mock CRM adapter")

    def update(self, record: Dict[str, Any]) -> Dict[str, Any]:
        """Update a mock record."""
        record_id = record.get('id', record.get('Id'))
        if not record_id or record_id not in self.records:
            raise CRMError(f"Record {record_id} not found")

        self.records[record_id].update(record)
        logger.info(f"Updated mock record {record_id}")
        return {'success': True, 'id': record_id}

    def create(self, record: Dict[str, Any]) -> Dict[str, Any]:
        """Create a mock record."""
        record_id = str(self.next_id)
        self.next_id += 1
        record['id'] = record_id
        self.records[record_id] = record
        logger.info(f"Created mock record {record_id}")
        return {'id': record_id, **record}

    def get(self, record_id: str) -> Dict[str, Any]:
        """Retrieve a mock record."""
        if record_id not in self.records:
            raise CRMError(f"Record {record_id} not found")
        return self.records[record_id]

    def delete(self, record_id: str) -> bool:
        """Delete a mock record."""
        if record_id not in self.records:
            raise CRMError(f"Record {record_id} not found")
        del self.records[record_id]
        logger.info(f"Deleted mock record {record_id}")
        return True


# Global adapter instance
_adapter: Optional[CRMAdapter] = None


def _get_adapter() -> CRMAdapter:
    """Get or create CRM adapter based on environment configuration."""
    global _adapter

    if _adapter is not None:
        return _adapter

    # Determine backend from environment
    backend = os.getenv('CRM_BACKEND', 'mock').lower()

    if backend == 'salesforce':
        instance_url = os.getenv('SALESFORCE_INSTANCE_URL')
        access_token = os.getenv('SALESFORCE_ACCESS_TOKEN')

        if not instance_url or not access_token:
            raise CRMError("Salesforce requires SALESFORCE_INSTANCE_URL and SALESFORCE_ACCESS_TOKEN")

        _adapter = SalesforceAdapter(instance_url, access_token)

    elif backend == 'hubspot':
        api_key = os.getenv('HUBSPOT_API_KEY')

        if not api_key:
            raise CRMError("HubSpot requires HUBSPOT_API_KEY")

        _adapter = HubSpotAdapter(api_key)

    elif backend == 'mock':
        _adapter = MockAdapter()

    else:
        raise CRMError(f"Unknown CRM backend: {backend}")

    return _adapter


# Public API
def update(record: Dict[str, Any]) -> Dict[str, Any]:
    """
    Update a CRM record.

    Args:
        record: Record data to update (must include ID field)

    Returns:
        Updated record result

    Raises:
        CRMError: If update fails

    Environment Variables:
        CRM_BACKEND: Backend to use (salesforce, hubspot, mock)
        SALESFORCE_INSTANCE_URL: Salesforce instance URL
        SALESFORCE_ACCESS_TOKEN: Salesforce OAuth token
        HUBSPOT_API_KEY: HubSpot API key
    """
    adapter = _get_adapter()
    return adapter.update(record)


def create(record: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create a new CRM record.

    Args:
        record: Record data to create

    Returns:
        Created record with ID

    Raises:
        CRMError: If creation fails
    """
    adapter = _get_adapter()
    return adapter.create(record)


def get(record_id: str, **kwargs) -> Dict[str, Any]:
    """
    Retrieve a CRM record.

    Args:
        record_id: ID of record to retrieve
        **kwargs: Additional backend-specific parameters

    Returns:
        Record data

    Raises:
        CRMError: If retrieval fails
    """
    adapter = _get_adapter()
    return adapter.get(record_id, **kwargs)


def delete(record_id: str, **kwargs) -> bool:
    """
    Delete a CRM record.

    Args:
        record_id: ID of record to delete
        **kwargs: Additional backend-specific parameters

    Returns:
        True if successful

    Raises:
        CRMError: If deletion fails
    """
    adapter = _get_adapter()
    return adapter.delete(record_id, **kwargs)
