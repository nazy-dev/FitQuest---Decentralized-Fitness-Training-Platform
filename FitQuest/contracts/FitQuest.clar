;; FitQuest - Decentralized Fitness Training & Community Platform
;; A blockchain-based platform for workout routines, exercise logs,
;; and fitness community incentives

;; Contract constants
(define-constant deployer tx-sender)
(define-constant err-deployer-only (err u100))
(define-constant err-record-not-found (err u101))
(define-constant err-duplicate-entry (err u102))
(define-constant err-access-denied (err u103))
(define-constant err-validation-failed (err u104))

;; Token constants
(define-constant token-name "FitQuest Power Token")
(define-constant token-symbol "FPT")
(define-constant token-decimals u6)
(define-constant token-max-supply u51000000000) ;; 51k tokens with 6 decimals

;; Incentive amounts (in micro-tokens)
(define-constant incentive-workout u2100000) ;; 2.1 FPT
(define-constant incentive-routine u3500000) ;; 3.5 FPT
(define-constant incentive-achievement u8400000) ;; 8.4 FPT

;; State variables
(define-data-var circulating-supply uint u0)
(define-data-var next-routine-index uint u1)
(define-data-var next-session-index uint u1)

;; Token ledger
(define-map token-ledger principal uint)

;; Athlete profiles
(define-map athlete-profiles
  principal
  {
    display-name: (string-ascii 24),
    training-focus: (string-ascii 12), ;; "strength", "cardio", "hiit", "yoga", "crossfit"
    sessions-completed: uint,
    routines-created: uint,
    fitness-rank: uint, ;; 1-5
    total-duration: uint, ;; minutes
    registration-height: uint
  }
)

;; Workout routines
(define-map workout-routines
  uint
  {
    routine-title: (string-ascii 14),
    intensity: (string-ascii 8), ;; "beginner", "moderate", "intense"
    exercise-type: (string-ascii 10), ;; "cardio", "weights", "stretch", "core", "mixed"
    gear-needed: (string-ascii 14),
    duration-mins: uint, ;; minutes
    heart-rate-target: uint, ;; bpm (0 if not applicable)
    creator: principal,
    times-performed: uint,
    avg-score: uint
  }
)

;; Training sessions
(define-map training-sessions
  uint
  {
    routine-index: uint,
    athlete: principal,
    session-title: (string-ascii 14),
    warm-up-mins: uint, ;; minutes
    target-heart-rate: uint, ;; bpm
    reps-completed: uint,
    effort-rating: uint, ;; 1-5
    form-quality: uint, ;; 1-5
    session-memo: (string-ascii 40),
    session-height: uint,
    goal-achieved: bool
  }
)

;; Routine feedback
(define-map routine-feedback
  { routine-index: uint, evaluator: principal }
  {
    score: uint, ;; 1-10
    feedback-memo: (string-ascii 40),
    effectiveness: (string-ascii 6), ;; "great", "good", "poor"
    feedback-height: uint,
    kudos-count: uint
  }
)

;; Athlete achievements
(define-map athlete-achievements
  { athlete: principal, achievement-type: (string-ascii 12) }
  {
    unlocked-height: uint,
    session-total: uint
  }
)

;; Helper function to retrieve or initialize profile
(define-private (fetch-or-init-profile (athlete principal))
  (match (map-get? athlete-profiles athlete)
    existing-profile existing-profile
    {
      display-name: "",
      training-focus: "mixed",
      sessions-completed: u0,
      routines-created: u0,
      fitness-rank: u1,
      total-duration: u0,
      registration-height: stacks-block-height
    }
  )
)

;; Token interface functions
(define-read-only (get-name)
  (ok token-name)
)

(define-read-only (get-symbol)
  (ok token-symbol)
)

(define-read-only (get-decimals)
  (ok token-decimals)
)

(define-read-only (get-balance (account principal))
  (ok (default-to u0 (map-get? token-ledger account)))
)

(define-private (issue-tokens (recipient principal) (quantity uint))
  (let (
    (existing-balance (default-to u0 (map-get? token-ledger recipient)))
    (updated-balance (+ existing-balance quantity))
    (updated-supply (+ (var-get circulating-supply) quantity))
  )
    (asserts! (<= updated-supply token-max-supply) err-validation-failed)
    (map-set token-ledger recipient updated-balance)
    (var-set circulating-supply updated-supply)
    (ok quantity)
  )
)

;; Create workout routine
(define-public (create-workout-routine (routine-title (string-ascii 14)) (intensity (string-ascii 8)) (exercise-type (string-ascii 10)) (gear-needed (string-ascii 14)) (duration-mins uint) (heart-rate-target uint))
  (let (
    (routine-index (var-get next-routine-index))
    (current-profile (fetch-or-init-profile tx-sender))
  )
    (asserts! (> (len routine-title) u0) err-validation-failed)
    (asserts! (> duration-mins u0) err-validation-failed)
    (asserts! (<= heart-rate-target u300) err-validation-failed)
    
    (map-set workout-routines routine-index {
      routine-title: routine-title,
      intensity: intensity,
      exercise-type: exercise-type,
      gear-needed: gear-needed,
      duration-mins: duration-mins,
      heart-rate-target: heart-rate-target,
      creator: tx-sender,
      times-performed: u0,
      avg-score: u0
    })
    
    ;; Update athlete profile
    (map-set athlete-profiles tx-sender
      (merge current-profile {routines-created: (+ (get routines-created current-profile) u1)})
    )
    
    ;; Reward routine creation
    (try! (issue-tokens tx-sender incentive-routine))
    
    (var-set next-routine-index (+ routine-index u1))
    (print {event: "routine-created", routine-index: routine-index, creator: tx-sender})
    (ok routine-index)
  )
)

;; Record training session
(define-public (record-training-session (routine-index uint) (session-title (string-ascii 14)) (warm-up-mins uint) (target-heart-rate uint) (reps-completed uint) (effort-rating uint) (form-quality uint) (session-memo (string-ascii 40)) (goal-achieved bool))
  (let (
    (session-index (var-get next-session-index))
    (routine-data (unwrap! (map-get? workout-routines routine-index) err-record-not-found))
    (current-profile (fetch-or-init-profile tx-sender))
  )
    (asserts! (> (len session-title) u0) err-validation-failed)
    (asserts! (> warm-up-mins u0) err-validation-failed)
    (asserts! (> reps-completed u0) err-validation-failed)
    (asserts! (and (>= effort-rating u1) (<= effort-rating u5)) err-validation-failed)
    (asserts! (and (>= form-quality u1) (<= form-quality u5)) err-validation-failed)
    
    (map-set training-sessions session-index {
      routine-index: routine-index,
      athlete: tx-sender,
      session-title: session-title,
      warm-up-mins: warm-up-mins,
      target-heart-rate: target-heart-rate,
      reps-completed: reps-completed,
      effort-rating: effort-rating,
      form-quality: form-quality,
      session-memo: session-memo,
      session-height: stacks-block-height,
      goal-achieved: goal-achieved
    })
    
    ;; Update routine usage statistics if successful
    (if goal-achieved
      (map-set workout-routines routine-index
        (merge routine-data {times-performed: (+ (get times-performed routine-data) u1)})
      )
      true
    )
    
    ;; Update athlete profile
    (if goal-achieved
      (begin
        (map-set athlete-profiles tx-sender
          (merge current-profile {
            sessions-completed: (+ (get sessions-completed current-profile) u1),
            total-duration: (+ (get total-duration current-profile) warm-up-mins),
            fitness-rank: (+ (get fitness-rank current-profile) (/ (+ effort-rating form-quality) u10))
          })
        )
        (try! (issue-tokens tx-sender incentive-workout))
        true
      )
      (begin
        (try! (issue-tokens tx-sender (/ incentive-workout u3)))
        true
      )
    )
    
    (var-set next-session-index (+ session-index u1))
    (print {event: "session-recorded", session-index: session-index, routine-index: routine-index})
    (ok session-index)
  )
)

;; Submit routine feedback
(define-public (submit-feedback (routine-index uint) (score uint) (feedback-memo (string-ascii 40)) (effectiveness (string-ascii 6)))
  (let (
    (routine-data (unwrap! (map-get? workout-routines routine-index) err-record-not-found))
    (current-profile (fetch-or-init-profile tx-sender))
  )
    (asserts! (and (>= score u1) (<= score u10)) err-validation-failed)
    (asserts! (> (len feedback-memo) u0) err-validation-failed)
    (asserts! (is-none (map-get? routine-feedback {routine-index: routine-index, evaluator: tx-sender})) err-duplicate-entry)
    
    (map-set routine-feedback {routine-index: routine-index, evaluator: tx-sender} {
      score: score,
      feedback-memo: feedback-memo,
      effectiveness: effectiveness,
      feedback-height: stacks-block-height,
      kudos-count: u0
    })
    
    ;; Update routine average score (simplified calculation)
    (let (
      (existing-avg (get avg-score routine-data))
      (performance-count (get times-performed routine-data))
      (updated-avg (if (> performance-count u0)
                 (/ (+ (* existing-avg performance-count) score) (+ performance-count u1))
                 score))
    )
      (map-set workout-routines routine-index (merge routine-data {avg-score: updated-avg}))
    )
    
    (print {event: "feedback-submitted", routine-index: routine-index, evaluator: tx-sender})
    (ok true)
  )
)

;; Award kudos to feedback
(define-public (award-kudos (routine-index uint) (evaluator principal))
  (let (
    (feedback-data (unwrap! (map-get? routine-feedback {routine-index: routine-index, evaluator: evaluator}) err-record-not-found))
  )
    (asserts! (not (is-eq tx-sender evaluator)) err-access-denied)
    
    (map-set routine-feedback {routine-index: routine-index, evaluator: evaluator}
      (merge feedback-data {kudos-count: (+ (get kudos-count feedback-data) u1)})
    )
    
    (print {event: "kudos-awarded", routine-index: routine-index, evaluator: evaluator})
    (ok true)
  )
)

;; Modify training focus
(define-public (modify-training-focus (new-training-focus (string-ascii 12)))
  (let (
    (current-profile (fetch-or-init-profile tx-sender))
  )
    (asserts! (> (len new-training-focus) u0) err-validation-failed)
    
    (map-set athlete-profiles tx-sender (merge current-profile {training-focus: new-training-focus}))
    
    (print {event: "training-focus-modified", athlete: tx-sender, focus: new-training-focus})
    (ok true)
  )
)

;; Unlock achievement
(define-public (unlock-achievement (achievement-type (string-ascii 12)))
  (let (
    (current-profile (fetch-or-init-profile tx-sender))
  )
    (asserts! (is-none (map-get? athlete-achievements {athlete: tx-sender, achievement-type: achievement-type})) err-duplicate-entry)
    
    ;; Verify achievement criteria
    (let (
      (criteria-satisfied
        (if (is-eq achievement-type "train-95") (>= (get sessions-completed current-profile) u95)
        (if (is-eq achievement-type "coach-18") (>= (get routines-created current-profile) u18)
        false)))
    )
      (asserts! criteria-satisfied err-access-denied)
      
      ;; Store achievement
      (map-set athlete-achievements {athlete: tx-sender, achievement-type: achievement-type} {
        unlocked-height: stacks-block-height,
        session-total: (get sessions-completed current-profile)
      })
      
      ;; Grant achievement reward
      (try! (issue-tokens tx-sender incentive-achievement))
      
      (print {event: "achievement-unlocked", athlete: tx-sender, achievement-type: achievement-type})
      (ok true)
    )
  )
)

;; Modify display name
(define-public (modify-display-name (new-display-name (string-ascii 24)))
  (let (
    (current-profile (fetch-or-init-profile tx-sender))
  )
    (asserts! (> (len new-display-name) u0) err-validation-failed)
    (map-set athlete-profiles tx-sender (merge current-profile {display-name: new-display-name}))
    (print {event: "display-name-modified", athlete: tx-sender})
    (ok true)
  )
)

;; Query functions
(define-read-only (fetch-athlete-profile (athlete principal))
  (map-get? athlete-profiles athlete)
)

(define-read-only (fetch-workout-routine (routine-index uint))
  (map-get? workout-routines routine-index)
)

(define-read-only (fetch-training-session (session-index uint))
  (map-get? training-sessions session-index)
)

(define-read-only (fetch-routine-feedback (routine-index uint) (evaluator principal))
  (map-get? routine-feedback {routine-index: routine-index, evaluator: evaluator})
)

(define-read-only (fetch-achievement (athlete principal) (achievement-type (string-ascii 12)))
  (map-get? athlete-achievements {athlete: athlete, achievement-type: achievement-type})
)