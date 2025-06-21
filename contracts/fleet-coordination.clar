;; Fleet Coordination Contract
;; Manages autonomous vehicle fleets and their operations

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_FLEET_EXISTS (err u201))
(define-constant ERR_FLEET_NOT_FOUND (err u202))
(define-constant ERR_VEHICLE_NOT_FOUND (err u203))

;; Fleet data structure
(define-map fleets
  { fleet-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    total-vehicles: uint,
    active-vehicles: uint,
    created-at: uint
  }
)

;; Vehicle data structure
(define-map vehicles
  { vehicle-id: uint }
  {
    fleet-id: uint,
    manufacturer-id: uint,
    status: (string-ascii 20),
    current-location: (string-ascii 100),
    battery-level: uint,
    last-updated: uint
  }
)

(define-data-var next-fleet-id uint u1)
(define-data-var next-vehicle-id uint u1)

;; Create a new fleet
(define-public (create-fleet (name (string-ascii 50)))
  (let ((fleet-id (var-get next-fleet-id)))
    (asserts! (is-none (map-get? fleets { fleet-id: fleet-id })) ERR_FLEET_EXISTS)

    (map-set fleets
      { fleet-id: fleet-id }
      {
        owner: tx-sender,
        name: name,
        total-vehicles: u0,
        active-vehicles: u0,
        created-at: block-height
      }
    )

    (var-set next-fleet-id (+ fleet-id u1))
    (ok fleet-id)
  )
)

;; Add vehicle to fleet
(define-public (add-vehicle-to-fleet (fleet-id uint) (manufacturer-id uint) (location (string-ascii 100)))
  (let
    (
      (fleet (unwrap! (map-get? fleets { fleet-id: fleet-id }) ERR_FLEET_NOT_FOUND))
      (vehicle-id (var-get next-vehicle-id))
    )
    (asserts! (is-eq tx-sender (get owner fleet)) ERR_UNAUTHORIZED)

    (map-set vehicles
      { vehicle-id: vehicle-id }
      {
        fleet-id: fleet-id,
        manufacturer-id: manufacturer-id,
        status: "idle",
        current-location: location,
        battery-level: u100,
        last-updated: block-height
      }
    )

    (map-set fleets
      { fleet-id: fleet-id }
      (merge fleet { total-vehicles: (+ (get total-vehicles fleet) u1) })
    )

    (var-set next-vehicle-id (+ vehicle-id u1))
    (ok vehicle-id)
  )
)

;; Update vehicle status
(define-public (update-vehicle-status (vehicle-id uint) (status (string-ascii 20)) (location (string-ascii 100)) (battery-level uint))
  (let ((vehicle (unwrap! (map-get? vehicles { vehicle-id: vehicle-id }) ERR_VEHICLE_NOT_FOUND)))
    (map-set vehicles
      { vehicle-id: vehicle-id }
      (merge vehicle {
        status: status,
        current-location: location,
        battery-level: battery-level,
        last-updated: block-height
      })
    )
    (ok true)
  )
)

;; Get fleet details
(define-read-only (get-fleet (fleet-id uint))
  (map-get? fleets { fleet-id: fleet-id })
)

;; Get vehicle details
(define-read-only (get-vehicle (vehicle-id uint))
  (map-get? vehicles { vehicle-id: vehicle-id })
)
