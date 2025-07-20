;; Enhanced Voting Poll Contract

;; Error constants
(define-constant ERR_INVALID_POLL (err u100))
(define-constant ERR_NOT_AUTHORIZED (err u101))
(define-constant ERR_POLL_CLOSED (err u102))
(define-constant ERR_POLL_NOT_FOUND (err u103))
(define-constant ERR_ALREADY_VOTED (err u104))
(define-constant ERR_POLL_EXPIRED (err u105))
(define-constant ERR_INVALID_DURATION (err u106))
(define-constant ERR_POLL_STILL_ACTIVE (err u107))

;; Data variables
(define-data-var poll-counter uint u0)
(define-data-var contract-owner principal tx-sender)

;; Data maps
(define-map polls 
  { poll-id: uint } 
  { 
    question: (string-ascii 100), 
    yes-votes: uint, 
    no-votes: uint, 
    owner: principal,
    is-active: bool,
    created-at: uint,
    expires-at: uint,
    total-voters: uint
  }
)

(define-map votes 
  { poll-id: uint, voter: principal } 
  { voted: bool, vote-choice: bool, voted-at: uint }
)

(define-map poll-voters
  { poll-id: uint }
  { voters: (list 100 principal) }
)

;; Public functions

;; Create a new poll with expiration time (in blocks)
(define-public (create-poll (question (string-ascii 100)) (duration uint))
  (begin
    (asserts! (> duration u0) ERR_INVALID_DURATION)
    (let ((poll-id (var-get poll-counter))
          (current-height block-height)
          (expiry-height (+ block-height duration)))
      (begin
        (map-insert polls 
          { poll-id: poll-id } 
          { 
            question: question, 
            yes-votes: u0, 
            no-votes: u0, 
            owner: tx-sender,
            is-active: true,
            created-at: current-height,
            expires-at: expiry-height,
            total-voters: u0
          }
        )
        (map-insert poll-voters { poll-id: poll-id } { voters: (list) })
        (var-set poll-counter (+ poll-id u1))
        (ok poll-id)
      )
    )
  )
)