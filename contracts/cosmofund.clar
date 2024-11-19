;; CosmoFund: Decentralized Crowdfunding for Space Exploration

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_DEADLINE_PASSED (err u104))
(define-constant ERR_GOAL_NOT_REACHED (err u105))
(define-constant ERR_INVALID_INPUT (err u106))
(define-constant ERR_CONTRIBUTIONS_EXIST (err u107))
(define-constant ERR_EXTENSION_NOT_ALLOWED (err u108))

;; Configuration
(define-constant EXTENSION_THRESHOLD u75) ;; 75% of the goal
(define-constant MAX_EXTENSION_DAYS u30)

;; Data Maps
(define-map projects 
  { project-id: uint } 
  { 
    name: (string-ascii 50), 
    creator: principal, 
    goal: uint, 
    deadline: uint, 
    total-raised: uint, 
    is-active: bool,
    extensions-used: uint
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

;; Helper function to check if a project exists
(define-private (project-exists (project-id uint))
  (is-some (map-get? projects { project-id: project-id }))
)

;; Functions

;; Submit a new project
(define-public (submit-project (name (string-ascii 50)) (goal uint) (deadline uint))
  (let (
    (project-id (+ (var-get project-nonce) u1))
    (name-length (len name))
  )
    (asserts! (> deadline block-height) ERR_DEADLINE_PASSED)
    (asserts! (> goal u0) ERR_INSUFFICIENT_FUNDS)
    (asserts! (and (> name-length u0) (<= name-length u50)) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? projects { project-id: project-id })) ERR_ALREADY_EXISTS)
    (map-set projects
      { project-id: project-id }
      { 
        name: name, 
        creator: tx-sender, 
        goal: goal, 
        deadline: deadline, 
        total-raised: u0, 
        is-active: true,
        extensions-used: u0
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
    (asserts! (project-exists project-id) ERR_NOT_FOUND)
    (asserts! (> amount u0) ERR_INSUFFICIENT_FUNDS)
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
    (asserts! (project-exists project-id) ERR_NOT_FOUND)
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
    (asserts! (project-exists project-id) ERR_NOT_FOUND)
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
    (asserts! (project-exists project-id) ERR_NOT_FOUND)
    (asserts! (> block-height (get deadline project)) ERR_DEADLINE_PASSED)
    (asserts! (< (get total-raised project) (get goal project)) ERR_UNAUTHORIZED)
    (try! (as-contract (stx-transfer? (get amount contribution) tx-sender tx-sender)))
    (map-delete contributions { project-id: project-id, contributor: tx-sender })
    (ok true)
  )
)

;; Cancel a project (for project creators)
(define-public (cancel-project (project-id uint))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) ERR_NOT_FOUND))
  )
    (asserts! (project-exists project-id) ERR_NOT_FOUND)
    (asserts! (is-eq tx-sender (get creator project)) ERR_UNAUTHORIZED)
    (asserts! (get is-active project) ERR_UNAUTHORIZED)
    (asserts! (<= block-height (get deadline project)) ERR_DEADLINE_PASSED)
    (asserts! (is-eq (get total-raised project) u0) ERR_CONTRIBUTIONS_EXIST)
    (map-set projects
      { project-id: project-id }
      (merge project { is-active: false })
    )
    (ok true)
  )
)

;; Extend project deadline
(define-public (extend-deadline (project-id uint) (new-deadline uint))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) ERR_NOT_FOUND))
    (current-deadline (get deadline project))
    (extension-days (/ (- new-deadline current-deadline) u144)) ;; Assuming 144 blocks per day
  )
    (asserts! (project-exists project-id) ERR_NOT_FOUND)
    (asserts! (is-eq tx-sender (get creator project)) ERR_UNAUTHORIZED)
    (asserts! (get is-active project) ERR_UNAUTHORIZED)
    (asserts! (<= block-height current-deadline) ERR_DEADLINE_PASSED)
    (asserts! (<= extension-days MAX_EXTENSION_DAYS) ERR_INVALID_INPUT)
    (asserts! (>= (* (get total-raised project) u100) (* (get goal project) EXTENSION_THRESHOLD)) ERR_EXTENSION_NOT_ALLOWED)
    (asserts! (< (get extensions-used project) u3) ERR_EXTENSION_NOT_ALLOWED)
    (map-set projects
      { project-id: project-id }
      (merge project { 
        deadline: new-deadline,
        extensions-used: (+ (get extensions-used project) u1)
      })
    )
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