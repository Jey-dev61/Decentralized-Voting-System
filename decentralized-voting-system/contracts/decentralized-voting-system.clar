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