"""
Salesforce Bulk API 2.0 Client

For high-volume operations: 10,000+ records at a time.
Essential for autonomous agent swarms processing at scale.
"""

import time
import csv
import io
from typing import List, Dict, Any, Optional
from enum import Enum
from dataclasses import dataclass
import requests
import structlog

from ..auth.oauth import SalesforceAuth

logger = structlog.get_logger()


class BulkOperation(Enum):
    INSERT = "insert"
    UPDATE = "update"
    UPSERT = "upsert"
    DELETE = "delete"
    HARD_DELETE = "hardDelete"


class JobState(Enum):
    OPEN = "Open"
    UPLOAD_COMPLETE = "UploadComplete"
    IN_PROGRESS = "InProgress"
    ABORTED = "Aborted"
    JOB_COMPLETE = "JobComplete"
    FAILED = "Failed"


@dataclass
class BulkJobResult:
    """Result of a bulk job"""
    job_id: str
    state: JobState
    records_processed: int
    records_failed: int
    successful_results: List[Dict[str, Any]]
    failed_results: List[Dict[str, Any]]
    processing_time_ms: int


class BulkClient:
    """
    Salesforce Bulk API 2.0 client.

    Optimized for:
    - Processing 10,000+ records per batch
    - Autonomous operation (poll until complete)
    - Error handling and retry logic
    """

    API_VERSION = "v59.0"

    def __init__(self, auth: SalesforceAuth):
        self.auth = auth
        self._session = requests.Session()

    @property
    def base_url(self) -> str:
        return f"{self.auth.token.instance_url}/services/data/{self.API_VERSION}/jobs/ingest"

    @property
    def headers(self) -> dict:
        return {
            **self.auth.headers,
            'Content-Type': 'application/json'
        }

    def insert(self, sobject: str, records: List[Dict[str, Any]]) -> BulkJobResult:
        """Insert records in bulk"""
        return self._execute_job(sobject, BulkOperation.INSERT, records)

    def update(self, sobject: str, records: List[Dict[str, Any]]) -> BulkJobResult:
        """Update records in bulk (must include Id field)"""
        return self._execute_job(sobject, BulkOperation.UPDATE, records)

    def upsert(self, sobject: str, external_id_field: str, records: List[Dict[str, Any]]) -> BulkJobResult:
        """Upsert records in bulk using external ID"""
        return self._execute_job(sobject, BulkOperation.UPSERT, records, external_id_field)

    def delete(self, sobject: str, record_ids: List[str]) -> BulkJobResult:
        """Delete records in bulk"""
        records = [{"Id": rid} for rid in record_ids]
        return self._execute_job(sobject, BulkOperation.DELETE, records)

    def _execute_job(
        self,
        sobject: str,
        operation: BulkOperation,
        records: List[Dict[str, Any]],
        external_id_field: Optional[str] = None
    ) -> BulkJobResult:
        """Execute a complete bulk job"""
        start_time = time.time()

        # 1. Create job
        job_id = self._create_job(sobject, operation, external_id_field)
        logger.info("bulk_job_created", job_id=job_id, sobject=sobject, operation=operation.value)

        try:
            # 2. Upload data
            self._upload_data(job_id, records)
            logger.info("bulk_data_uploaded", job_id=job_id, record_count=len(records))

            # 3. Close job to start processing
            self._close_job(job_id)

            # 4. Poll until complete
            final_state = self._poll_job_status(job_id)

            # 5. Get results
            successful, failed = self._get_results(job_id)

            processing_time = int((time.time() - start_time) * 1000)

            result = BulkJobResult(
                job_id=job_id,
                state=final_state,
                records_processed=len(records),
                records_failed=len(failed),
                successful_results=successful,
                failed_results=failed,
                processing_time_ms=processing_time
            )

            logger.info(
                "bulk_job_complete",
                job_id=job_id,
                processed=result.records_processed,
                failed=result.records_failed,
                time_ms=processing_time
            )

            return result

        except Exception as e:
            # Abort job on error
            try:
                self._abort_job(job_id)
            except:
                pass
            raise

    def _create_job(
        self,
        sobject: str,
        operation: BulkOperation,
        external_id_field: Optional[str] = None
    ) -> str:
        """Create a bulk job"""
        payload = {
            "object": sobject,
            "operation": operation.value,
            "contentType": "CSV",
            "lineEnding": "LF"
        }

        if external_id_field:
            payload["externalIdFieldName"] = external_id_field

        response = self._session.post(self.base_url, headers=self.headers, json=payload)

        if response.status_code == 200:
            return response.json()["id"]
        else:
            raise BulkAPIError(f"Failed to create job: {response.text}")

    def _upload_data(self, job_id: str, records: List[Dict[str, Any]]):
        """Upload CSV data to the job"""
        # Convert to CSV
        csv_data = self._records_to_csv(records)

        url = f"{self.base_url}/{job_id}/batches"
        headers = {
            'Authorization': self.auth.headers['Authorization'],
            'Content-Type': 'text/csv'
        }

        response = self._session.put(url, headers=headers, data=csv_data)

        if response.status_code != 201:
            raise BulkAPIError(f"Failed to upload data: {response.text}")

    def _close_job(self, job_id: str):
        """Close job to start processing"""
        url = f"{self.base_url}/{job_id}"
        payload = {"state": "UploadComplete"}

        response = self._session.patch(url, headers=self.headers, json=payload)

        if response.status_code != 200:
            raise BulkAPIError(f"Failed to close job: {response.text}")

    def _abort_job(self, job_id: str):
        """Abort a job"""
        url = f"{self.base_url}/{job_id}"
        payload = {"state": "Aborted"}

        self._session.patch(url, headers=self.headers, json=payload)

    def _poll_job_status(self, job_id: str, timeout: int = 600) -> JobState:
        """Poll job status until complete"""
        url = f"{self.base_url}/{job_id}"
        start_time = time.time()

        while True:
            response = self._session.get(url, headers=self.headers)

            if response.status_code != 200:
                raise BulkAPIError(f"Failed to get job status: {response.text}")

            data = response.json()
            state = JobState(data["state"])

            if state in (JobState.JOB_COMPLETE, JobState.FAILED, JobState.ABORTED):
                return state

            if time.time() - start_time > timeout:
                raise BulkAPIError(f"Job timed out after {timeout}s")

            # Exponential backoff: 1s, 2s, 4s, max 30s
            elapsed = time.time() - start_time
            sleep_time = min(30, 2 ** (elapsed // 10))
            time.sleep(sleep_time)

    def _get_results(self, job_id: str) -> tuple:
        """Get successful and failed results"""
        successful = self._get_result_set(job_id, "successfulResults")
        failed = self._get_result_set(job_id, "failedResults")
        return successful, failed

    def _get_result_set(self, job_id: str, result_type: str) -> List[Dict[str, Any]]:
        """Get a specific result set"""
        url = f"{self.base_url}/{job_id}/{result_type}"
        headers = {
            'Authorization': self.auth.headers['Authorization'],
            'Accept': 'text/csv'
        }

        response = self._session.get(url, headers=headers)

        if response.status_code != 200:
            return []

        return self._csv_to_records(response.text)

    def _records_to_csv(self, records: List[Dict[str, Any]]) -> str:
        """Convert records to CSV string"""
        if not records:
            return ""

        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=records[0].keys())
        writer.writeheader()
        writer.writerows(records)
        return output.getvalue()

    def _csv_to_records(self, csv_text: str) -> List[Dict[str, Any]]:
        """Convert CSV string to records"""
        if not csv_text.strip():
            return []

        reader = csv.DictReader(io.StringIO(csv_text))
        return list(reader)


class BulkAPIError(Exception):
    """Bulk API error"""
    pass
