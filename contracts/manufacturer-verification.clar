;; Manufacturer Verification Contract
;; Validates and manages autonomous vehicle manufacturers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_MANUFACTURER_EXISTS (err u101))
(define-constant ERR_MANUFACTURER_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Manufacturer data structure
(define-map manufacturers
  { manufacturer-id: uint }
  {
    name: (string-ascii 50),
    wallet-address: principal,
    certification-level: uint,
    verified: bool,
    registration-date: uint
  }
)

(define-data-var next-manufacturer-id uint u1)

;; Register a new manufacturer
(define-public (register-manufacturer (name (string-ascii 50)) (certification-level uint))
  (let ((manufacturer-id (var-get next-manufacturer-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? manufacturers { manufacturer-id: manufacturer-id })) ERR_MANUFACTURER_EXISTS)

    (map-set manufacturers
      { manufacturer-id: manufacturer-id }
      {
        name: name,
        wallet-address: tx-sender,
        certification-level: certification-level,
        verified: false,
        registration-date: block-height
      }
    )

    (var-set next-manufacturer-id (+ manufacturer-id u1))
    (ok manufacturer-id)
  )
)

;; Verify a manufacturer
(define-public (verify-manufacturer (manufacturer-id uint))
  (let ((manufacturer (unwrap! (map-get? manufacturers { manufacturer-id: manufacturer-id }) ERR_MANUFACTURER_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set manufacturers
      { manufacturer-id: manufacturer-id }
      (merge manufacturer { verified: true })
    )
    (ok true)
  )
)

;; Get manufacturer details
(define-read-only (get-manufacturer (manufacturer-id uint))
  (map-get? manufacturers { manufacturer-id: manufacturer-id })
)

;; Check if manufacturer is verified
(define-read-only (is-manufacturer-verified (manufacturer-id uint))
  (match (map-get? manufacturers { manufacturer-id: manufacturer-id })
    manufacturer (get verified manufacturer)
    false
  )
)
