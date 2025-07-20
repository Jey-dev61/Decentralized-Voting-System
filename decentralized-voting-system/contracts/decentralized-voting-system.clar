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
          (current-height stacks-block-height)
          (expiry-height (+ stacks-block-height duration)))
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

;; Vote on a poll
(define-public (vote (poll-id uint) (is-yes bool))
  (let ((poll (unwrap! (map-get? polls { poll-id: poll-id }) ERR_INVALID_POLL))
        (current-height stacks-block-height))
    (begin
      ;; Check if poll is still active
      (asserts! (get is-active poll) ERR_POLL_CLOSED)
      ;; Check if poll hasn't expired
      (asserts! (<= current-height (get expires-at poll)) ERR_POLL_EXPIRED)
      ;; Check if user hasn't voted already
      (asserts! (is-none (map-get? votes { poll-id: poll-id, voter: tx-sender })) ERR_ALREADY_VOTED)
      
      ;; Record the vote
      (map-insert votes 
        { poll-id: poll-id, voter: tx-sender } 
        { voted: true, vote-choice: is-yes, voted-at: current-height }
      )
      
      ;; Update poll vote counts and voter list
      (let ((updated-voters (unwrap-panic (as-max-len? 
                              (append (default-to (list) (get voters (map-get? poll-voters { poll-id: poll-id }))) tx-sender) 
                              u100))))
        (map-set poll-voters { poll-id: poll-id } { voters: updated-voters })
        (if is-yes
          (map-set polls 
            { poll-id: poll-id } 
            (merge poll { 
              yes-votes: (+ (get yes-votes poll) u1),
              total-voters: (+ (get total-voters poll) u1)
            })
          )
          (map-set polls 
            { poll-id: poll-id } 
            (merge poll { 
              no-votes: (+ (get no-votes poll) u1),
              total-voters: (+ (get total-voters poll) u1)
            })
          )
        )
      )
      (ok true)
    )
  )
)

;; Close a poll (only owner can close)
(define-public (close-poll (poll-id uint))
  (let ((poll (unwrap! (map-get? polls { poll-id: poll-id }) ERR_INVALID_POLL)))
    (begin
      (asserts! (is-eq tx-sender (get owner poll)) ERR_NOT_AUTHORIZED)
      (asserts! (get is-active poll) ERR_POLL_CLOSED)
      (map-set polls 
        { poll-id: poll-id } 
        (merge poll { is-active: false })
      )
      (ok true)
    )
  )
)

;; Delete a poll (only owner can delete, and only if no votes)
(define-public (delete-poll (poll-id uint))
  (let ((poll (unwrap! (map-get? polls { poll-id: poll-id }) ERR_INVALID_POLL)))
    (begin
      (asserts! (is-eq tx-sender (get owner poll)) ERR_NOT_AUTHORIZED)
      (asserts! (is-eq (get total-voters poll) u0) ERR_NOT_AUTHORIZED)
      (map-delete polls { poll-id: poll-id })
      (map-delete poll-voters { poll-id: poll-id })
      (ok true)
    )
  )
)

;; Emergency close all polls (contract owner only)
(define-public (emergency-close-all)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    ;; This would need to be implemented with a helper function in practice
    ;; to iterate through all polls
    (ok true)
  )
)

;; Read-only functions

;; Get poll details
(define-read-only (get-poll (poll-id uint))
  (map-get? polls { poll-id: poll-id })
)

;; Get total number of polls created
(define-read-only (get-total-polls)
  (var-get poll-counter)
)

;; Get contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

;; Get polls by owner (helper function - would need additional implementation for full functionality)
(define-read-only (get-poll-owner (poll-id uint))
  (match (map-get? polls { poll-id: poll-id })
    poll (some (get owner poll))
    none
  )
)

;; Get poll with status information
(define-read-only (get-poll-status (poll-id uint))
  (match (map-get? polls { poll-id: poll-id })
    poll (let ((current-height stacks-block-height)
               (is-expired (> current-height (get expires-at poll)))
               (is-active (and (get is-active poll) (not is-expired))))
           (ok {
             poll: poll,
             is-expired: is-expired,
             is-currently-active: is-active,
             blocks-remaining: (if is-expired u0 (- (get expires-at poll) current-height))
           }))
    ERR_POLL_NOT_FOUND
  )
)

;; Check if poll is active (not closed and not expired)
(define-read-only (is-poll-active (poll-id uint))
  (match (map-get? polls { poll-id: poll-id })
    poll (and 
           (get is-active poll) 
           (<= stacks-block-height (get expires-at poll)))
    false
  )
)

;; Check if user has voted on a poll
(define-read-only (has-voted (poll-id uint) (user principal))
  (is-some (map-get? votes { poll-id: poll-id, voter: user }))
)

;; Get user's vote on a poll
(define-read-only (get-user-vote (poll-id uint) (user principal))
  (map-get? votes { poll-id: poll-id, voter: user })
)

;; Get all voters for a poll (up to 100)
(define-read-only (get-poll-voters (poll-id uint))
  (default-to (list) (get voters (map-get? poll-voters { poll-id: poll-id })))
)

;; Get poll results with percentages
(define-read-only (get-poll-results (poll-id uint))
  (match (map-get? polls { poll-id: poll-id })
    poll (let ((total-votes (+ (get yes-votes poll) (get no-votes poll))))
           (if (> total-votes u0)
             (ok {
               poll-id: poll-id,
               question: (get question poll),
               yes-votes: (get yes-votes poll),
               no-votes: (get no-votes poll),
               total-votes: total-votes,
               yes-percentage: (/ (* (get yes-votes poll) u100) total-votes),
               no-percentage: (/ (* (get no-votes poll) u100) total-votes),
               is-active: (get is-active poll)
             })
             (ok {
               poll-id: poll-id,
               question: (get question poll),
               yes-votes: u0,
               no-votes: u0,
               total-votes: u0,
               yes-percentage: u0,
               no-percentage: u0,
               is-active: (get is-active poll)
             })
           ))
    ERR_POLL_NOT_FOUND
  )
)
