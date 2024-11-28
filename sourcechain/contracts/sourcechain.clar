;; SourceChain - Enhanced Supply Chain Tracking Smart Contract
;; Tracks product batches from production to delivery using unique tokens
;; Added features: Immutable audit logs, event notifications, and proof of origin

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-status (err u102))
(define-constant err-invalid-certification (err u103))
(define-constant err-invalid-input (err u104))

;; Product status types
(define-data-var status-types (list 10 (string-ascii 20))
  (list "created" "in_production" "in_transit" "delivered" "verified"))

;; Event types for notifications
(define-data-var event-types (list 10 (string-ascii 20))
  (list "status_update" "transfer" "delay" "certification_added" "verification"))

;; Product batch structure with added origin proof and certifications
(define-map product-batches
  { batch-id: uint }
  {
    manufacturer: principal,
    timestamp: uint,
    status: (string-ascii 20),
    product-details: (string-ascii 500),
    current-holder: principal,
    verification-code: (buff 32),
    origin-location: (string-ascii 50),
    certifications: (list 10 (string-ascii 50)),
    compliance-standards: (list 5 (string-ascii 50))
  }
)

;; Enhanced audit trail with event logging
(define-map batch-history
  { batch-id: uint, index: uint }
  {
    from: principal,
    to: principal,
    timestamp: uint,
    status: (string-ascii 20),
    event-type: (string-ascii 20),
    event-data: (string-ascii 500)
  }
)

;; Stakeholder notifications
(define-map stakeholder-subscriptions
  { batch-id: uint, stakeholder: principal }
  { notifications-enabled: bool }
)

(define-data-var batch-counter uint u0)
(define-map batch-history-counters { batch-id: uint } uint)

;; Helper function to validate string length
(define-private (validate-string-length (input (string-ascii 500)) (max-length uint))
  (<= (len input) max-length)
)

;; Helper function to validate list length
(define-private (validate-list-length (input (list 10 (string-ascii 50))) (max-length uint))
  (<= (len input) max-length)
)

;; Create new product batch with origin details
(define-public (create-batch 
    (product-details (string-ascii 500))
    (verification-code (buff 32))
    (origin-location (string-ascii 50))
    (initial-certifications (list 10 (string-ascii 50)))
    (compliance-standards (list 5 (string-ascii 50))))
  (let
    (
      (new-batch-id (+ (var-get batch-counter) u1))
    )
    (if (and
          (validate-string-length product-details u500)
          (validate-string-length origin-location u50)
          (validate-list-length initial-certifications u10)
          (validate-list-length compliance-standards u5))
      (begin
        (map-set product-batches
          { batch-id: new-batch-id }
          {
            manufacturer: tx-sender,
            timestamp: block-height,
            status: "created",
            product-details: product-details,
            current-holder: tx-sender,
            verification-code: verification-code,
            origin-location: origin-location,
            certifications: initial-certifications,
            compliance-standards: compliance-standards
          }
        )
        (var-set batch-counter new-batch-id)
        (map-set batch-history-counters { batch-id: new-batch-id } u0)
        ;; Log creation event
        (log-event new-batch-id "status_update" "Batch created with origin certification")
        (ok new-batch-id)
      )
      (err err-invalid-input)
    )
  )
)

;; Helper function to log events to the audit trail
(define-private (log-event (batch-id uint) (event-type (string-ascii 20)) (event-data (string-ascii 500)))
  (let
    (
      (current-index (default-to u0 (map-get? batch-history-counters { batch-id: batch-id })))
    )
    (begin
      (map-set batch-history
        { batch-id: batch-id, index: current-index }
        {
          from: tx-sender,
          to: (get-current-holder batch-id),
          timestamp: block-height,
          status: (get-current-status batch-id),
          event-type: event-type,
          event-data: event-data
        }
      )
      (map-set batch-history-counters { batch-id: batch-id } (+ current-index u1))
      (notify-stakeholders batch-id event-type event-data)
    )
  )
)

;; Helper function to get current holder
(define-private (get-current-holder (batch-id uint))
  (get current-holder (unwrap-panic (map-get? product-batches { batch-id: batch-id })))
)

;; Helper function to get current status
(define-private (get-current-status (batch-id uint))
  (get status (unwrap-panic (map-get? product-batches { batch-id: batch-id })))
)

;; Update batch status with enhanced logging
(define-public (update-batch-status (batch-id uint) (new-status (string-ascii 20)))
  (match (map-get? product-batches { batch-id: batch-id })
    batch (if (and (is-eq (get current-holder batch) tx-sender)
                   (validate-string-length new-status u20))
      (begin
        (map-set product-batches
          { batch-id: batch-id }
          (merge batch { status: new-status })
        )
        (log-event batch-id "status_update" (concat "Status updated to: " new-status))
        (ok true)
      )
      (err err-owner-only))
    (err err-not-found)
  )
)

;; Transfer batch with enhanced logging
(define-public (transfer-batch (batch-id uint) (recipient principal))
  (match (map-get? product-batches { batch-id: batch-id })
    batch (if (is-eq (get current-holder batch) tx-sender)
      (begin
        (map-set product-batches
          { batch-id: batch-id }
          (merge batch { current-holder: recipient })
        )
        (log-event batch-id "transfer" "Ownership transferred to new recipient")
        (ok true)
      )
      (err err-owner-only))
    (err err-not-found)
  )
)

;; Subscribe stakeholder to notifications
(define-public (subscribe-to-notifications (batch-id uint))
  (begin
    (map-set stakeholder-subscriptions
      { batch-id: batch-id, stakeholder: tx-sender }
      { notifications-enabled: true }
    )
    (ok true)
  )
)

;; Helper function to notify stakeholders
(define-private (notify-stakeholders (batch-id uint) (event-type (string-ascii 20)) (event-data (string-ascii 500)))
  (print { batch-id: batch-id, 
          event-type: event-type, 
          event-data: event-data, 
          timestamp: block-height })
)

;; Add or update certifications
(define-public (add-certification (batch-id uint) (certification (string-ascii 50)))
  (match (map-get? product-batches { batch-id: batch-id })
    batch (if (and (is-eq (get manufacturer batch) tx-sender)
                   (validate-string-length certification u50))
      (let
        (
          (current-certs (get certifications batch))
          (new-certs (unwrap! (as-max-len? (append current-certs certification) u10) (err err-invalid-certification)))
        )
        (begin
          (map-set product-batches
            { batch-id: batch-id }
            (merge batch { certifications: new-certs })
          )
          (log-event batch-id "certification_added" (concat "Added certification: " certification))
          (ok true)
        )
      )
      (err err-owner-only))
    (err err-not-found)
  )
)

;; Record shipping delay
(define-public (record-delay (batch-id uint) (reason (string-ascii 500)))
  (match (map-get? product-batches { batch-id: batch-id })
    batch (if (and (is-eq (get current-holder batch) tx-sender)
                   (validate-string-length reason u500))
      (begin
        (log-event batch-id "delay" reason)
        (ok true)
      )
      (err err-owner-only))
    (err err-not-found)
  )
)

;; Get full audit trail for a batch
(define-read-only (get-full-audit-trail (batch-id uint))
  (let
    (
      (history-count (default-to u0 (map-get? batch-history-counters { batch-id: batch-id })))
    )
    (map-get? batch-history { batch-id: batch-id, index: (- history-count u1) })
  )
)

;; Get batch details with origin information
(define-read-only (get-batch-details (batch-id uint))
  (map-get? product-batches { batch-id: batch-id })
)

;; Verify product authenticity with enhanced logging
(define-read-only (verify-batch (batch-id uint) (verification-code (buff 32)))
  (match (map-get? product-batches { batch-id: batch-id })
    batch (begin
      (print { event: "verification_attempt", 
              batch-id: batch-id,
              timestamp: block-height,
              result: (is-eq (get verification-code batch) verification-code) })
      (ok (is-eq (get verification-code batch) verification-code)))
    (err err-not-found)
  )
)