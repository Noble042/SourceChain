# SourceChain - Enhanced Supply Chain Tracking Smart Contract

SourceChain is a robust smart contract implementation designed for transparent and secure supply chain management on the Stacks blockchain. It provides comprehensive tracking of product batches from production to delivery using unique tokens, with features like immutable audit logs, stakeholder notifications, and proof of origin verification.

## Features

### Core Functionality
- **Batch Creation and Management**: Create and track product batches with detailed information including origin, certifications, and compliance standards
- **Status Tracking**: Monitor product movement through various stages (created, in_production, in_transit, delivered, verified)
- **Ownership Transfer**: Secure transfer of batch ownership between supply chain participants
- **Verification System**: Built-in product authenticity verification using unique verification codes

### Enhanced Security Features
- **Immutable Audit Logs**: Complete history of all batch-related events and transitions
- **Origin Proof**: Verifiable proof of product origin and manufacturing details
- **Compliance Tracking**: Support for multiple compliance standards and certifications
- **Input Validation**: Comprehensive input validation and sanitization for enhanced security

### Stakeholder Features
- **Event Notifications**: Real-time notifications for stakeholders about batch status changes
- **Subscription System**: Stakeholders can subscribe to receive updates about specific batches
- **Delay Recording**: Transparent recording and tracking of shipping delays
- **Certification Management**: Dynamic addition and verification of product certifications

## Technical Specifications

### Constants
```clarity
err-owner-only (u100)
err-not-found (u101)
err-invalid-status (u102)
err-invalid-certification (u103)
err-invalid-input (u104)
```

### Data Structures

#### Product Batch
- `batch-id`: Unique identifier
- `manufacturer`: Principal address of manufacturer
- `timestamp`: Block height of creation
- `status`: Current status
- `product-details`: Detailed product information
- `current-holder`: Current owner
- `verification-code`: Unique verification hash
- `origin-location`: Manufacturing location
- `certifications`: List of certifications
- `compliance-standards`: Applicable compliance standards

#### Audit Trail
- `batch-id`: Batch identifier
- `index`: Event sequence number
- `from`: Source address
- `to`: Destination address
- `timestamp`: Event timestamp
- `status`: Batch status at time of event
- `event-type`: Type of event
- `event-data`: Additional event information

## Usage

### Creating a New Batch
```clarity
(create-batch 
    product-details
    verification-code
    origin-location
    initial-certifications
    compliance-standards)
```

### Updating Batch Status
```clarity
(update-batch-status batch-id new-status)
```

### Transferring Ownership
```clarity
(transfer-batch batch-id recipient)
```

### Adding Certifications
```clarity
(add-certification batch-id certification)
```

### Recording Delays
```clarity
(record-delay batch-id reason)
```

### Verifying Product Authenticity
```clarity
(verify-batch batch-id verification-code)
```

## Security Considerations

1. **Access Control**
   - Only batch owners can transfer ownership
   - Only manufacturers can add certifications
   - Only current holders can update status

2. **Input Validation**
   - All inputs are validated before processing
   - String lengths are checked and sanitized
   - Status values are verified against allowed list

3. **Error Handling**
   - Comprehensive error checking and reporting
   - Clear error codes for different scenarios
   - Safe handling of map operations

## Getting Started

1. Deploy the contract to the Stacks blockchain
2. Initialize required data structures
3. Create your first batch using the `create-batch` function
4. Monitor batch movement using the audit trail
5. Subscribe stakeholders to relevant batches

## Best Practices

1. Always verify batch existence before operations
2. Use unique and secure verification codes
3. Maintain detailed product information
4. Subscribe relevant stakeholders to notifications
5. Record delays and issues promptly

## Error Codes

- `u100`: Operation restricted to owner
- `u101`: Batch not found
- `u102`: Invalid status provided
- `u103`: Invalid certification
- `u104`: Invalid input data

## Contributing

Contributions are welcome! Please ensure all code changes:
1. Include comprehensive input validation
2. Maintain audit trail integrity
3. Follow existing error handling patterns
4. Include appropriate access controls
