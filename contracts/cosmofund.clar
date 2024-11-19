;; CosmoFund: Decentralized Crowdfunding for Space Exploration

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_DEADLINE_PASSED (err u104))
(define-constant ERR_GOAL_NOT_REACHED (err u105))

;; Data Maps
(define-map projects 
  { project-id: uint } 
  { 
    name: (string-ascii 50), 
    creator: principal, 
    goal: uint, 
    deadline: uint, 
    total-raised: uint, 
    is-active: bool 
  }
)

(define-map contributions 
  { project-id: uint, contributor: principal } 
  { amount: uint }
)

(define-map votes
  { project-id: uint, voter: principal }
  { in-favor: bool }
)

;; Variables
(define-data-var project-nonce uint u0)

;; Functions

;; Submit a new project
(define-public (submit-project (name (string-ascii 50)) (goal uint) (deadline uint))
  (let ((project-id (+ (var-get project-nonce) u1)))
    (asserts! (> deadline block-height) ERR_DEADLINE_PASSED)
    (asserts! (is-none (map-get? projects { project-id: project-id })) ERR_ALREADY_EXISTS)
    (map-set projects
      { project-id: project-id }
      { 
        name: name, 
        creator: tx-sender, 
        goal: goal, 
        deadline: deadline, 
        total-raised: u0, 
        is-active: true 
      }
    )
    (var-set project-nonce project-id)
    (ok project-id)
  )
)

;; Contribute to a project
(define-public (contribute (project-id uint) (amount uint))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) ERR_NOT_FOUND))
    (current-contribution (default-to { amount: u0 } (map-get? contributions { project-id: project-id, contributor: tx-sender })))
  )
    (asserts! (get is-active project) ERR_UNAUTHORIZED)
    (asserts! (<= block-height (get deadline project)) ERR_DEADLINE_PASSED)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set contributions
      { project-id: project-id, contributor: tx-sender }
      { amount: (+ (get amount current-contribution) amount) }
    )
    (map-set projects
      { project-id: project-id }
      (merge project { total-raised: (+ (get total-raised project) amount) })
    )
    (ok true)
  )
)

;; Vote on a project
(define-public (vote (project-id uint) (in-favor bool))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) ERR_NOT_FOUND))
    (contribution (unwrap! (map-get? contributions { project-id: project-id, contributor: tx-sender }) ERR_UNAUTHORIZED))
  )
    (asserts! (get is-active project) ERR_UNAUTHORIZED)
    (asserts! (<= block-height (get deadline project)) ERR_DEADLINE_PASSED)
    (map-set votes
      { project-id: project-id, voter: tx-sender }
      { in-favor: in-favor }
    )
    (ok true)
  )
)

;; Withdraw funds (for project creators)
(define-public (withdraw-funds (project-id uint))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) ERR_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get creator project)) ERR_UNAUTHORIZED)
    (asserts! (>= (get total-raised project) (get goal project)) ERR_GOAL_NOT_REACHED)
    (asserts! (> block-height (get deadline project)) ERR_DEADLINE_PASSED)
    (try! (as-contract (stx-transfer? (get total-raised project) tx-sender (get creator project))))
    (map-set projects
      { project-id: project-id }
      (merge project { is-active: false })
    )
    (ok true)
  )
)

;; Refund (for contributors if a project fails)
(define-public (refund (project-id uint))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) ERR_NOT_FOUND))
    (contribution (unwrap! (map-get? contributions { project-id: project-id, contributor: tx-sender }) ERR_NOT_FOUND))
  )
    (asserts! (> block-height (get deadline project)) ERR_DEADLINE_PASSED)
    (asserts! (< (get total-raised project) (get goal project)) ERR_UNAUTHORIZED)
    (try! (as-contract (stx-transfer? (get amount contribution) tx-sender tx-sender)))
    (map-delete contributions { project-id: project-id, contributor: tx-sender })
    (ok true)
  )
)

;; Read-only functions

(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

(define-read-only (get-contribution (project-id uint) (contributor principal))
  (map-get? contributions { project-id: project-id, contributor: contributor })
)

(define-read-only (get-vote (project-id uint) (voter principal))
  (map-get? votes { project-id: project-id, voter: voter })
)