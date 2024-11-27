;; SourceChain - Supply Chain Tracking Smart Contract
;; Tracks product batches from production to delivery using unique tokens

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-status (err u102))

;; Product status types
(define-data-var status-types (list 10 (string-ascii 20))
  (list "created" "in_production" "in_transit" "delivered" "verified"))

;; Product batch structure
(define-map product-batches
  { batch-id: uint }
  {
    manufacturer: principal,
    timestamp: uint,
    status: (string-ascii 20),
    product-details: (string-utf8 500),
    current-holder: principal,
    verification-code: (buff 32)
  }
)

;; Track batch transfers
(define-map batch-history
  { batch-id: uint, index: uint }
  {
    from: principal,
    to: principal,
    timestamp: uint,
    status: (string-ascii 20)
  }
)

(define-data-var batch-counter uint u0)
(define-map batch-history-counters { batch-id: uint } uint)

;; Create new product batch
(define-public (create-batch (product-details (string-utf8 500)) (verification-code (buff 32)))
  (let
    (
      (new-batch-id (+ (var-get batch-counter) u1))
    )
    (begin
      (map-set product-batches
        { batch-id: new-batch-id }
        {
          manufacturer: tx-sender,
          timestamp: block-height,
          status: "created",
          product-details: product-details,
          current-holder: tx-sender,
          verification-code: verification-code
        }
      )
      (var-set batch-counter new-batch-id)
      (map-set batch-history-counters { batch-id: new-batch-id } u0)
      (ok new-batch-id)
    )
  )
)

;; Update batch status
(define-public (update-batch-status (batch-id uint) (new-status (string-ascii 20)))
  (match (map-get? product-batches { batch-id: batch-id })
    batch (if (is-eq (get current-holder batch) tx-sender)
      (begin
        (map-set product-batches
          { batch-id: batch-id }
          (merge batch { status: new-status })
        )
        (map-set batch-history
          { batch-id: batch-id, index: (default-to u0 (map-get? batch-history-counters { batch-id: batch-id })) }
          {
            from: tx-sender,
            to: tx-sender,
            timestamp: block-height,
            status: new-status
          }
        )
        (map-set batch-history-counters { batch-id: batch-id } 
          (+ (default-to u0 (map-get? batch-history-counters { batch-id: batch-id })) u1))
        (ok true)
      )
      (err err-owner-only))
    (err err-not-found)
  )
)

;; Transfer batch to new holder
(define-public (transfer-batch (batch-id uint) (recipient principal))
  (match (map-get? product-batches { batch-id: batch-id })
    batch (if (is-eq (get current-holder batch) tx-sender)
      (begin
        (map-set product-batches
          { batch-id: batch-id }
          (merge batch { current-holder: recipient })
        )
        (map-set batch-history
          { batch-id: batch-id, index: (default-to u0 (map-get? batch-history-counters { batch-id: batch-id })) }
          {
            from: tx-sender,
            to: recipient,
            timestamp: block-height,
            status: (get status batch)
          }
        )
        (map-set batch-history-counters { batch-id: batch-id }
          (+ (default-to u0 (map-get? batch-history-counters { batch-id: batch-id })) u1))
        (ok true)
      )
      (err err-owner-only))
    (err err-not-found)
  )
)

;; Verify product authenticity
(define-read-only (verify-batch (batch-id uint) (verification-code (buff 32)))
  (match (map-get? product-batches { batch-id: batch-id })
    batch (ok (is-eq (get verification-code batch) verification-code))
    (err err-not-found)
  )
)

;; Get batch details
(define-read-only (get-batch-details (batch-id uint))
  (map-get? product-batches { batch-id: batch-id })
)

;; Get batch history
(define-read-only (get-batch-history (batch-id uint))
  (let
    (
      (history-count (default-to u0 (map-get? batch-history-counters { batch-id: batch-id })))
    )
    (map-get? batch-history { batch-id: batch-id, index: (- history-count u1) })
  )
)