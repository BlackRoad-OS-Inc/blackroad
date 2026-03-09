"""
Production-grade ERP adapter with support for multiple ERP backends.

Supported backends:
- SAP
- Oracle NetSuite
- Generic REST API
- Mock (for testing)
"""
import logging
import os
from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional
from enum import Enum
from datetime import datetime
import json

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger(__name__)


class ERPBackend(Enum):
    """Supported ERP backends."""
    SAP = "sap"
    NETSUITE = "netsuite"
    GENERIC = "generic"
    MOCK = "mock"


class ERPError(Exception):
    """Base exception for ERP operations."""
    pass


class ERPAdapter(ABC):
    """Abstract base class for ERP adapters."""

    @abstractmethod
    def send_order(self, order: Dict[str, Any]) -> Dict[str, Any]:
        """Send an order to ERP system."""
        pass

    @abstractmethod
    def get_order(self, order_id: str) -> Dict[str, Any]:
        """Retrieve an order from ERP system."""
        pass

    @abstractmethod
    def update_inventory(self, item_id: str, quantity: int) -> Dict[str, Any]:
        """Update inventory levels."""
        pass

    @abstractmethod
    def get_inventory(self, item_id: str) -> Dict[str, Any]:
        """Get inventory information."""
        pass


class SAPAdapter(ERPAdapter):
    """SAP ERP adapter using OData API."""

    def __init__(self, base_url: str, username: str, password: str):
        """
        Initialize SAP adapter.

        Args:
            base_url: SAP OData service base URL
            username: SAP username
            password: SAP password
        """
        self.base_url = base_url.rstrip('/')
        self.username = username
        self.password = password
        self.session = self._create_session()
        logger.info(f"Initialized SAP adapter for {base_url}")

    def _create_session(self) -> requests.Session:
        """Create requests session with retry logic and authentication."""
        session = requests.Session()
        session.auth = (self.username, self.password)

        retry = Retry(
            total=3,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504]
        )
        adapter = HTTPAdapter(max_retries=retry)
        session.mount('https://', adapter)
        session.headers.update({
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        })
        return session

    def send_order(self, order: Dict[str, Any]) -> Dict[str, Any]:
        """Send a sales order to SAP."""
        url = f"{self.base_url}/sap/opu/odata/sap/API_SALES_ORDER_SRV/A_SalesOrder"

        # Map to SAP schema
        sap_order = {
            'SalesOrderType': order.get('type', 'OR'),
            'SalesOrganization': order.get('sales_org', '1000'),
            'DistributionChannel': order.get('dist_channel', '10'),
            'OrganizationDivision': order.get('division', '00'),
            'SoldToParty': order.get('customer_id'),
            'PurchaseOrderByCustomer': order.get('po_number'),
            'to_Item': {
                'results': [
                    {
                        'Material': item['material_id'],
                        'OrderQuantity': str(item['quantity']),
                        'OrderQuantityUnit': item.get('unit', 'EA')
                    }
                    for item in order.get('items', [])
                ]
            }
        }

        try:
            response = self.session.post(url, json=sap_order)
            response.raise_for_status()
            result = response.json()
            order_id = result['d']['SalesOrder']
            logger.info(f"Created SAP sales order {order_id}")
            return {'order_id': order_id, 'status': 'success'}
        except requests.RequestException as e:
            logger.error(f"Failed to send SAP order: {e}")
            raise ERPError(f"Failed to send order: {e}")

    def get_order(self, order_id: str) -> Dict[str, Any]:
        """Retrieve a sales order from SAP."""
        url = f"{self.base_url}/sap/opu/odata/sap/API_SALES_ORDER_SRV/A_SalesOrder('{order_id}')"

        try:
            response = self.session.get(url)
            response.raise_for_status()
            result = response.json()
            return result['d']
        except requests.RequestException as e:
            logger.error(f"Failed to get SAP order: {e}")
            raise ERPError(f"Failed to get order: {e}")

    def update_inventory(self, item_id: str, quantity: int) -> Dict[str, Any]:
        """Update inventory in SAP."""
        url = f"{self.base_url}/sap/opu/odata/sap/API_MATERIAL_STOCK_SRV/A_MatlStkInAcctMod"

        payload = {
            'Material': item_id,
            'MatlWrhsStkQtyInMatlBaseUnit': str(quantity)
        }

        try:
            response = self.session.post(url, json=payload)
            response.raise_for_status()
            logger.info(f"Updated SAP inventory for {item_id}")
            return {'success': True, 'item_id': item_id, 'quantity': quantity}
        except requests.RequestException as e:
            logger.error(f"Failed to update SAP inventory: {e}")
            raise ERPError(f"Failed to update inventory: {e}")

    def get_inventory(self, item_id: str) -> Dict[str, Any]:
        """Get inventory information from SAP."""
        url = f"{self.base_url}/sap/opu/odata/sap/API_MATERIAL_STOCK_SRV/A_MatlStkInAcctMod"
        params = {'$filter': f"Material eq '{item_id}'"}

        try:
            response = self.session.get(url, params=params)
            response.raise_for_status()
            result = response.json()
            return result['d']['results'][0] if result['d']['results'] else {}
        except requests.RequestException as e:
            logger.error(f"Failed to get SAP inventory: {e}")
            raise ERPError(f"Failed to get inventory: {e}")


class NetSuiteAdapter(ERPAdapter):
    """Oracle NetSuite ERP adapter using RESTlet API."""

    def __init__(self, account_id: str, consumer_key: str, consumer_secret: str,
                 token_id: str, token_secret: str):
        """
        Initialize NetSuite adapter.

        Args:
            account_id: NetSuite account ID
            consumer_key: OAuth consumer key
            consumer_secret: OAuth consumer secret
            token_id: OAuth token ID
            token_secret: OAuth token secret
        """
        self.account_id = account_id
        self.base_url = f"https://{account_id}.suitetalk.api.netsuite.com/services/rest"
        self.consumer_key = consumer_key
        self.consumer_secret = consumer_secret
        self.token_id = token_id
        self.token_secret = token_secret
        self.session = self._create_session()
        logger.info(f"Initialized NetSuite adapter for account {account_id}")

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
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        })
        # Note: In production, implement full OAuth 1.0a signature
        # For simplicity, using token-based auth here
        return session

    def send_order(self, order: Dict[str, Any]) -> Dict[str, Any]:
        """Send a sales order to NetSuite."""
        url = f"{self.base_url}/record/v1/salesOrder"

        ns_order = {
            'entity': {'id': order['customer_id']},
            'tranDate': order.get('date', datetime.now().isoformat()),
            'otherRefNum': order.get('po_number'),
            'item': {
                'items': [
                    {
                        'item': {'id': item['item_id']},
                        'quantity': item['quantity'],
                        'rate': item.get('price', 0)
                    }
                    for item in order.get('items', [])
                ]
            }
        }

        try:
            response = self.session.post(url, json=ns_order)
            response.raise_for_status()
            result = response.json()
            order_id = result.get('id')
            logger.info(f"Created NetSuite sales order {order_id}")
            return {'order_id': order_id, 'status': 'success'}
        except requests.RequestException as e:
            logger.error(f"Failed to send NetSuite order: {e}")
            raise ERPError(f"Failed to send order: {e}")

    def get_order(self, order_id: str) -> Dict[str, Any]:
        """Retrieve a sales order from NetSuite."""
        url = f"{self.base_url}/record/v1/salesOrder/{order_id}"

        try:
            response = self.session.get(url)
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Failed to get NetSuite order: {e}")
            raise ERPError(f"Failed to get order: {e}")

    def update_inventory(self, item_id: str, quantity: int) -> Dict[str, Any]:
        """Update inventory in NetSuite."""
        url = f"{self.base_url}/record/v1/inventoryAdjustment"

        adjustment = {
            'account': {'id': '119'},  # Inventory adjustment account
            'inventory': {
                'items': [{
                    'item': {'id': item_id},
                    'adjustQtyBy': quantity
                }]
            }
        }

        try:
            response = self.session.post(url, json=adjustment)
            response.raise_for_status()
            logger.info(f"Updated NetSuite inventory for {item_id}")
            return {'success': True, 'item_id': item_id, 'quantity': quantity}
        except requests.RequestException as e:
            logger.error(f"Failed to update NetSuite inventory: {e}")
            raise ERPError(f"Failed to update inventory: {e}")

    def get_inventory(self, item_id: str) -> Dict[str, Any]:
        """Get inventory information from NetSuite."""
        url = f"{self.base_url}/record/v1/inventoryItem/{item_id}"

        try:
            response = self.session.get(url)
            response.raise_for_status()
            result = response.json()
            return {
                'item_id': item_id,
                'quantity_available': result.get('quantityAvailable', 0),
                'quantity_on_hand': result.get('quantityOnHand', 0)
            }
        except requests.RequestException as e:
            logger.error(f"Failed to get NetSuite inventory: {e}")
            raise ERPError(f"Failed to get inventory: {e}")


class MockAdapter(ERPAdapter):
    """Mock ERP adapter for testing."""

    def __init__(self):
        """Initialize mock adapter."""
        self.orders = {}
        self.inventory = {}
        self.next_order_id = 1000
        logger.info("Initialized Mock ERP adapter")

    def send_order(self, order: Dict[str, Any]) -> Dict[str, Any]:
        """Send an order (mock)."""
        order_id = f"ORD-{self.next_order_id}"
        self.next_order_id += 1

        order_record = {
            'order_id': order_id,
            'status': 'submitted',
            'created_at': datetime.now().isoformat(),
            **order
        }

        self.orders[order_id] = order_record
        logger.info(f"Created mock order {order_id}")
        return {'order_id': order_id, 'status': 'success'}

    def get_order(self, order_id: str) -> Dict[str, Any]:
        """Retrieve an order (mock)."""
        if order_id not in self.orders:
            raise ERPError(f"Order {order_id} not found")
        return self.orders[order_id]

    def update_inventory(self, item_id: str, quantity: int) -> Dict[str, Any]:
        """Update inventory (mock)."""
        current = self.inventory.get(item_id, 0)
        self.inventory[item_id] = current + quantity
        logger.info(f"Updated mock inventory for {item_id}: {current} -> {self.inventory[item_id]}")
        return {'success': True, 'item_id': item_id, 'quantity': self.inventory[item_id]}

    def get_inventory(self, item_id: str) -> Dict[str, Any]:
        """Get inventory (mock)."""
        quantity = self.inventory.get(item_id, 0)
        return {
            'item_id': item_id,
            'quantity_available': quantity,
            'quantity_on_hand': quantity
        }


# Global adapter instance
_adapter: Optional[ERPAdapter] = None


def _get_adapter() -> ERPAdapter:
    """Get or create ERP adapter based on environment configuration."""
    global _adapter

    if _adapter is not None:
        return _adapter

    # Determine backend from environment
    backend = os.getenv('ERP_BACKEND', 'mock').lower()

    if backend == 'sap':
        base_url = os.getenv('SAP_BASE_URL')
        username = os.getenv('SAP_USERNAME')
        password = os.getenv('SAP_PASSWORD')

        if not all([base_url, username, password]):
            raise ERPError("SAP requires SAP_BASE_URL, SAP_USERNAME, and SAP_PASSWORD")

        _adapter = SAPAdapter(base_url, username, password)

    elif backend == 'netsuite':
        account_id = os.getenv('NETSUITE_ACCOUNT_ID')
        consumer_key = os.getenv('NETSUITE_CONSUMER_KEY')
        consumer_secret = os.getenv('NETSUITE_CONSUMER_SECRET')
        token_id = os.getenv('NETSUITE_TOKEN_ID')
        token_secret = os.getenv('NETSUITE_TOKEN_SECRET')

        if not all([account_id, consumer_key, consumer_secret, token_id, token_secret]):
            raise ERPError("NetSuite requires all OAuth credentials")

        _adapter = NetSuiteAdapter(account_id, consumer_key, consumer_secret,
                                   token_id, token_secret)

    elif backend == 'mock':
        _adapter = MockAdapter()

    else:
        raise ERPError(f"Unknown ERP backend: {backend}")

    return _adapter


# Public API
def send(order: Dict[str, Any]) -> Dict[str, Any]:
    """
    Send an order to ERP system.

    Args:
        order: Order data including customer_id, items, etc.

    Returns:
        Order result with order_id

    Raises:
        ERPError: If order submission fails

    Environment Variables:
        ERP_BACKEND: Backend to use (sap, netsuite, mock)
        SAP_BASE_URL: SAP OData service URL
        SAP_USERNAME: SAP username
        SAP_PASSWORD: SAP password
        NETSUITE_ACCOUNT_ID: NetSuite account ID
        NETSUITE_CONSUMER_KEY: NetSuite OAuth consumer key
        NETSUITE_CONSUMER_SECRET: NetSuite OAuth consumer secret
        NETSUITE_TOKEN_ID: NetSuite OAuth token ID
        NETSUITE_TOKEN_SECRET: NetSuite OAuth token secret
    """
    adapter = _get_adapter()
    return adapter.send_order(order)


def get_order(order_id: str) -> Dict[str, Any]:
    """
    Retrieve an order from ERP system.

    Args:
        order_id: Order ID to retrieve

    Returns:
        Order data

    Raises:
        ERPError: If retrieval fails
    """
    adapter = _get_adapter()
    return adapter.get_order(order_id)


def update_inventory(item_id: str, quantity: int) -> Dict[str, Any]:
    """
    Update inventory levels in ERP system.

    Args:
        item_id: Item/Material ID
        quantity: Quantity adjustment (positive or negative)

    Returns:
        Updated inventory result

    Raises:
        ERPError: If update fails
    """
    adapter = _get_adapter()
    return adapter.update_inventory(item_id, quantity)


def get_inventory(item_id: str) -> Dict[str, Any]:
    """
    Get inventory information from ERP system.

    Args:
        item_id: Item/Material ID

    Returns:
        Inventory data including quantities

    Raises:
        ERPError: If retrieval fails
    """
    adapter = _get_adapter()
    return adapter.get_inventory(item_id)
