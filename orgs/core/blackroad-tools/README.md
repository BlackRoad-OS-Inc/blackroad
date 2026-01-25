# BlackRoad Prism Console - Tools

Production-grade integration tools for CRM, ERP, and automation workflows.

## Overview

This directory contains enterprise integration adapters that enable seamless connectivity between the Prism Console and external business systems.

## Available Tools

### CRM Adapter (`crm.py`)

Multi-backend Customer Relationship Management adapter with support for:

- **Salesforce**: Full CRUD operations via REST API
- **HubSpot**: Contact management and CRM operations
- **Mock**: In-memory adapter for testing

#### Quick Start

```python
from tools import crm

# Configure backend via environment
import os
os.environ['CRM_BACKEND'] = 'salesforce'
os.environ['SALESFORCE_INSTANCE_URL'] = 'https://na1.salesforce.com'
os.environ['SALESFORCE_ACCESS_TOKEN'] = 'your-token'

# Create a record
result = crm.create({
    'type': 'Account',
    'Name': 'Acme Corp',
    'Industry': 'Technology'
})
print(f"Created account: {result['id']}")

# Update a record
crm.update({
    'Id': result['id'],
    'type': 'Account',
    'Industry': 'Software'
})

# Retrieve a record
account = crm.get(result['id'], record_type='Account')

# Delete a record
crm.delete(result['id'], record_type='Account')
```

#### Environment Variables

**Salesforce:**
- `CRM_BACKEND=salesforce`
- `SALESFORCE_INSTANCE_URL`: Your Salesforce instance URL
- `SALESFORCE_ACCESS_TOKEN`: OAuth access token

**HubSpot:**
- `CRM_BACKEND=hubspot`
- `HUBSPOT_API_KEY`: HubSpot API key

**Mock (Testing):**
- `CRM_BACKEND=mock` (default)

#### API Reference

##### `crm.create(record: Dict[str, Any]) -> Dict[str, Any]`

Create a new CRM record.

**Returns:** Created record with ID

##### `crm.update(record: Dict[str, Any]) -> Dict[str, Any]`

Update an existing CRM record (requires ID field).

**Returns:** Update confirmation

##### `crm.get(record_id: str, **kwargs) -> Dict[str, Any]`

Retrieve a CRM record by ID.

**Returns:** Record data

##### `crm.delete(record_id: str, **kwargs) -> bool`

Delete a CRM record.

**Returns:** True if successful

##### Error Handling

All operations raise `CRMError` on failure:

```python
from tools.crm import CRMError

try:
    result = crm.create(record)
except CRMError as e:
    print(f"CRM operation failed: {e}")
```

---

### ERP Adapter (`erp.py`)

Multi-backend Enterprise Resource Planning adapter with support for:

- **SAP**: OData API integration for sales orders and inventory
- **Oracle NetSuite**: RESTlet API for order management
- **Mock**: In-memory adapter for testing

#### Quick Start

```python
from tools import erp

# Configure backend
import os
os.environ['ERP_BACKEND'] = 'sap'
os.environ['SAP_BASE_URL'] = 'https://your-sap-system.com'
os.environ['SAP_USERNAME'] = 'your-username'
os.environ['SAP_PASSWORD'] = 'your-password'

# Send a sales order
order = erp.send({
    'customer_id': '1000',
    'po_number': 'PO-12345',
    'items': [
        {
            'material_id': 'MAT-001',
            'quantity': 10,
            'unit': 'EA'
        }
    ]
})
print(f"Order created: {order['order_id']}")

# Retrieve order status
order_data = erp.get_order(order['order_id'])

# Update inventory
erp.update_inventory(item_id='MAT-001', quantity=100)

# Check inventory levels
inventory = erp.get_inventory(item_id='MAT-001')
print(f"Available: {inventory['quantity_available']}")
```

#### Environment Variables

**SAP:**
- `ERP_BACKEND=sap`
- `SAP_BASE_URL`: SAP OData service base URL
- `SAP_USERNAME`: SAP username
- `SAP_PASSWORD`: SAP password

**NetSuite:**
- `ERP_BACKEND=netsuite`
- `NETSUITE_ACCOUNT_ID`: NetSuite account ID
- `NETSUITE_CONSUMER_KEY`: OAuth consumer key
- `NETSUITE_CONSUMER_SECRET`: OAuth consumer secret
- `NETSUITE_TOKEN_ID`: OAuth token ID
- `NETSUITE_TOKEN_SECRET`: OAuth token secret

**Mock (Testing):**
- `ERP_BACKEND=mock` (default)

#### API Reference

##### `erp.send(order: Dict[str, Any]) -> Dict[str, Any]`

Send a sales order to ERP system.

**Parameters:**
- `order`: Order data with customer_id, items, etc.

**Returns:** Order confirmation with order_id

##### `erp.get_order(order_id: str) -> Dict[str, Any]`

Retrieve order details.

**Returns:** Complete order data

##### `erp.update_inventory(item_id: str, quantity: int) -> Dict[str, Any]`

Adjust inventory levels (positive or negative).

**Returns:** Updated inventory confirmation

##### `erp.get_inventory(item_id: str) -> Dict[str, Any]`

Get current inventory levels.

**Returns:** Inventory data with quantities

##### Error Handling

All operations raise `ERPError` on failure:

```python
from tools.erp import ERPError

try:
    result = erp.send(order)
except ERPError as e:
    print(f"ERP operation failed: {e}")
```

---

### Lucidia Autotester

GitHub issue automation tools for test result tracking.

#### Tools

**`bin/open_issue.py`**: Create GitHub issues from test results

```bash
echo '{
  "repository": "owner/repo",
  "title": "Test failure in module X",
  "body": "Detailed error log...",
  "labels": ["bug", "test-failure"],
  "assignees": ["developer"]
}' | GITHUB_TOKEN=ghp_xxx python bin/open_issue.py
```

**`bin/update_issue.py`**: Update existing issues

```bash
echo '{
  "repository": "owner/repo",
  "issue_number": 123,
  "state": "closed",
  "comment": "Fixed in commit abc123"
}' | GITHUB_TOKEN=ghp_xxx python bin/update_issue.py
```

#### Environment Variables

- `GITHUB_TOKEN`: GitHub personal access token with `repo` scope

## Installation

```bash
cd tools
pip install -r requirements.txt
```

## Testing

### Unit Tests

```bash
pytest tests/ -v
```

### Integration Tests

Set environment variables and run:

```bash
# Test CRM with mock backend
CRM_BACKEND=mock pytest tests/test_crm.py

# Test ERP with mock backend
ERP_BACKEND=mock pytest tests/test_erp.py
```

### Manual Testing

```python
# Test CRM
from tools import crm
import os

os.environ['CRM_BACKEND'] = 'mock'

# Create and test
record = crm.create({'name': 'Test Corp'})
print(f"Created: {record}")

retrieved = crm.get(record['id'])
print(f"Retrieved: {retrieved}")

# Test ERP
from tools import erp

os.environ['ERP_BACKEND'] = 'mock'

order = erp.send({
    'customer_id': '1000',
    'items': [{'item_id': 'ITEM-1', 'quantity': 5}]
})
print(f"Order: {order}")
```

## Production Deployment

### Retry Logic

Both CRM and ERP adapters include automatic retry with exponential backoff for:
- Network timeouts
- Rate limiting (429)
- Server errors (500-504)

Default: 3 retries with 1-second backoff factor

### Logging

Configure structured logging:

```python
import logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

### Security Best Practices

1. **Never hardcode credentials** - use environment variables or secret managers
2. **Rotate API tokens** regularly
3. **Use least-privilege access** - request only necessary permissions
4. **Monitor API usage** - track rate limits and quotas
5. **Encrypt credentials** in transit and at rest

### Rate Limiting

Monitor and respect API rate limits:

- **Salesforce**: 15,000 API calls per 24 hours (varies by edition)
- **HubSpot**: 100 requests per 10 seconds
- **SAP**: Varies by system configuration
- **NetSuite**: 1,000 requests per 60 seconds (varies by account)

## Architecture

```
┌────────────────┐
│ Prism Console  │
└────────┬───────┘
         │
    ┌────▼────┐
    │  Tools  │
    └────┬────┘
         │
    ┌────┼────┬─────────┬──────────┐
    │    │    │         │          │
┌───▼┐ ┌─▼──┐ ┌▼────┐ ┌─▼────┐ ┌──▼──┐
│CRM │ │ERP │ │Mock │ │GitHub│ │Etc  │
└────┘ └────┘ └─────┘ └──────┘ └─────┘
```

## Contributing

When adding new adapters:

1. Extend the abstract base class (`CRMAdapter` or `ERPAdapter`)
2. Implement all required methods
3. Add comprehensive error handling
4. Include retry logic for network operations
5. Write unit tests with mocks
6. Document environment variables
7. Update this README

## Troubleshooting

### CRM Issues

**"SALESFORCE_ACCESS_TOKEN not set"**
- Ensure environment variable is exported
- Token may be expired - regenerate in Salesforce

**"Failed to update record"**
- Check record ID exists
- Verify field names match Salesforce schema
- Ensure user has write permissions

### ERP Issues

**"SAP requires SAP_BASE_URL"**
- Set all required SAP environment variables
- Verify URL is accessible from your network

**"NetSuite requires all OAuth credentials"**
- All 5 NetSuite environment variables must be set
- Verify OAuth setup in NetSuite account

### GitHub Issues

**"GITHUB_TOKEN environment variable not set"**
- Create personal access token in GitHub settings
- Token needs `repo` scope for private repos

**"Issue #123 not found"**
- Verify repository name format: "owner/repo"
- Check issue number exists
- Ensure token has access to repository

## License

Copyright 2025 BlackRoad. All rights reserved.

## Support

- Issues: https://github.com/blackboxprogramming/blackroad-prism-console/issues
- Documentation: https://docs.blackroad.dev/tools
- Email: support@blackroad.dev

---

## 📜 License & Copyright

**Copyright © 2026 BlackRoad OS, Inc. All Rights Reserved.**

**CEO:** Alexa Amundson | **PROPRIETARY AND CONFIDENTIAL**

This software is NOT for commercial resale. Testing purposes only.

### 🏢 Enterprise Scale:
- 30,000 AI Agents
- 30,000 Human Employees
- CEO: Alexa Amundson

**Contact:** blackroad.systems@gmail.com

See [LICENSE](LICENSE) for complete terms.
