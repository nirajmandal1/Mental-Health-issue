;; title: mentalhealthissue
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

;; Mental Health Community Support Contract
;; Community-funded mental health services with privacy protection and peer support networks

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-funds (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-service-not-found (err u104))

;; Data Variables
(define-data-var total-community-fund uint u0)
(define-data-var next-service-id uint u1)

;; Data Maps
(define-map community-contributions principal uint)
(define-map mental-health-services uint {
  service-provider: principal,
  service-type: (string-ascii 50),
  cost-per-session: uint,
  is-active: bool,
  total-sessions-provided: uint
})

;; Function 1: Contribute to Community Mental Health Fund
;; Allows community members to contribute STX to fund mental health services
;; Maintains privacy by not storing personal information
(define-public (contribute-to-fund (amount uint))
  (begin
    ;; Validate contribution amount
    (asserts! (> amount u0) err-invalid-amount)
    
    ;; Transfer STX from contributor to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Update contributor's total contribution (for transparency)
    (map-set community-contributions tx-sender
             (+ (default-to u0 (map-get? community-contributions tx-sender)) amount))
    
    ;; Update total community fund
    (var-set total-community-fund (+ (var-get total-community-fund) amount))
    
    ;; Log contribution event (without personal details)
    (print {
      event: "fund-contribution",
      amount: amount,
      total-fund: (var-get total-community-fund)
    })
    
    (ok true)))

;; Function 2: Register Mental Health Service Provider
;; Allows qualified mental health professionals to register their services
;; Services are funded by the community pool
(define-public (register-service (service-type (string-ascii 50)) (cost-per-session uint))
  (begin
    ;; Validate inputs
    (asserts! (> cost-per-session u0) err-invalid-amount)
    (asserts! (> (len service-type) u0) err-invalid-amount)
    
    ;; Get current service ID and increment for next use
    (let ((service-id (var-get next-service-id)))
      ;; Register the mental health service
      (map-set mental-health-services service-id {
        service-provider: tx-sender,
        service-type: service-type,
        cost-per-session: cost-per-session,
        is-active: true,
        total-sessions-provided: u0
      })
      
      ;; Increment service ID for next registration
      (var-set next-service-id (+ service-id u1))
      
      ;; Log service registration
      (print {
        event: "service-registered",
        service-id: service-id,
        service-type: service-type,
        cost-per-session: cost-per-session
      })
      
      (ok service-id))))

;; Read-only functions for transparency

;; Get total community fund amount
(define-read-only (get-total-fund)
  (ok (var-get total-community-fund)))

;; Get individual contribution (for contributor transparency)
(define-read-only (get-my-contribution)
  (ok (default-to u0 (map-get? community-contributions tx-sender))))

;; Get service details by ID
(define-read-only (get-service-details (service-id uint))
  (ok (map-get? mental-health-services service-id)))

;; Get current service ID counter
(define-read-only (get-total-services)
  (ok (- (var-get next-service-id) u1)))

;; Emergency withdrawal function (contract owner only)
(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= amount (var-get total-community-fund)) err-insufficient-funds)
    (try! (stx-transfer? amount tx-sender contract-owner))
    (var-set total-community-fund (- (var-get total-community-fund) amount))
    (print {
      event: "emergency-withdrawal",
      amount: amount,
      remaining-fund: (var-get total-community-fund)
    })
    (ok true)))