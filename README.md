# FitQuest - Decentralized Fitness Training Platform

## Overview

FitQuest is a blockchain-based fitness tracking and community engagement platform built on the Stacks blockchain using Clarity smart contracts. The platform enables athletes to create workout routines, log training sessions, share feedback, and earn FPT (FitQuest Power Tokens) for their fitness achievements.

## Features

### 🏋️ Core Functionality

- **Workout Routine Creation**: Users can design and share comprehensive workout routines with detailed specifications
- **Training Session Logging**: Track individual workout sessions with metrics like effort, form quality, and goal achievement
- **Community Feedback System**: Rate and review workout routines created by other athletes
- **Token Incentives**: Earn FPT tokens for participation and achievements
- **Achievement System**: Unlock milestones based on training consistency and community contributions
- **Athlete Profiles**: Customizable profiles tracking fitness progress and training focus

### 💪 Token Economics

**FitQuest Power Token (FPT)**
- Symbol: `FPT`
- Decimals: 6
- Max Supply: 51,000 FPT
- Purpose: Incentivize platform participation and reward fitness achievements

**Earning Rewards:**
- Complete a training session: 2.1 FPT
- Create a workout routine: 3.5 FPT
- Unlock an achievement: 8.4 FPT
- Partial reward for incomplete sessions: 0.7 FPT

## Smart Contract Architecture

### Data Structures

#### Athlete Profiles
Stores comprehensive athlete information including:
- Display name (up to 24 characters)
- Training focus (strength, cardio, HIIT, yoga, crossfit)
- Session count and routines created
- Fitness rank (1-5 scale)
- Total training duration
- Registration block height

#### Workout Routines
Detailed workout specifications containing:
- Routine title and intensity level
- Exercise type and required equipment
- Duration and target heart rate
- Creator address and usage statistics
- Average community score

#### Training Sessions
Individual workout logs with:
- Associated routine reference
- Session metrics (warm-up time, reps, heart rate)
- Effort and form quality ratings (1-5)
- Goal achievement status
- Session notes

#### Routine Feedback
Community reviews including:
- Numerical score (1-10)
- Written feedback
- Effectiveness rating
- Kudos count from other users

#### Athlete Achievements
Milestone tracking for:
- Achievement type identifier
- Unlock timestamp
- Associated session count

## Public Functions

### Workout Management

#### `create-workout-routine`
```clarity
(create-workout-routine 
  (routine-title (string-ascii 14))
  (intensity (string-ascii 8))
  (exercise-type (string-ascii 10))
  (gear-needed (string-ascii 14))
  (duration-mins uint)
  (heart-rate-target uint))
```
Creates a new workout routine and rewards the creator with 3.5 FPT.

**Parameters:**
- `routine-title`: Short name for the routine
- `intensity`: "beginner", "moderate", or "intense"
- `exercise-type`: "cardio", "weights", "stretch", "core", or "mixed"
- `gear-needed`: Required equipment description
- `duration-mins`: Total routine duration in minutes
- `heart-rate-target`: Target heart rate in BPM (0 if not applicable)

**Returns:** `(ok routine-index)`

---

#### `record-training-session`
```clarity
(record-training-session
  (routine-index uint)
  (session-title (string-ascii 14))
  (warm-up-mins uint)
  (target-heart-rate uint)
  (reps-completed uint)
  (effort-rating uint)
  (form-quality uint)
  (session-memo (string-ascii 40))
  (goal-achieved bool))
```
Logs a completed training session and awards tokens based on success.

**Parameters:**
- `routine-index`: Reference to the workout routine used
- `session-title`: Name for this training session
- `warm-up-mins`: Warm-up duration in minutes
- `target-heart-rate`: Target heart rate during workout
- `reps-completed`: Number of repetitions/sets completed
- `effort-rating`: Self-assessed effort level (1-5)
- `form-quality`: Self-assessed form quality (1-5)
- `session-memo`: Personal notes about the session
- `goal-achieved`: Whether session goals were met

**Returns:** `(ok session-index)`

**Rewards:**
- Successful session: 2.1 FPT
- Incomplete session: 0.7 FPT

---

### Community Interaction

#### `submit-feedback`
```clarity
(submit-feedback
  (routine-index uint)
  (score uint)
  (feedback-memo (string-ascii 40))
  (effectiveness (string-ascii 6)))
```
Submit a review for a workout routine (one review per user per routine).

**Parameters:**
- `routine-index`: The routine being reviewed
- `score`: Rating from 1-10
- `feedback-memo`: Written feedback
- `effectiveness`: "great", "good", or "poor"

**Returns:** `(ok true)`

---

#### `award-kudos`
```clarity
(award-kudos
  (routine-index uint)
  (evaluator principal))
```
Give kudos to another user's feedback (cannot kudos your own feedback).

**Returns:** `(ok true)`

---

### Profile Management

#### `modify-display-name`
```clarity
(modify-display-name (new-display-name (string-ascii 24)))
```
Update your athlete display name.

**Returns:** `(ok true)`

---

#### `modify-training-focus`
```clarity
(modify-training-focus (new-training-focus (string-ascii 12)))
```
Change your primary training focus.

**Valid options:** "strength", "cardio", "hiit", "yoga", "crossfit", "mixed"

**Returns:** `(ok true)`

---

### Achievements

#### `unlock-achievement`
```clarity
(unlock-achievement (achievement-type (string-ascii 12)))
```
Claim an achievement milestone and receive 8.4 FPT reward.

**Available achievements:**
- `"train-95"`: Complete 95+ training sessions
- `"coach-18"`: Create 18+ workout routines

**Returns:** `(ok true)`

---

## Read-Only Functions

### Token Information
- `get-name()`: Returns token name
- `get-symbol()`: Returns token symbol
- `get-decimals()`: Returns token decimals
- `get-balance(account)`: Returns token balance for an account

### Data Queries
- `fetch-athlete-profile(athlete)`: Retrieves athlete profile data
- `fetch-workout-routine(routine-index)`: Gets workout routine details
- `fetch-training-session(session-index)`: Retrieves session log
- `fetch-routine-feedback(routine-index, evaluator)`: Gets specific feedback
- `fetch-achievement(athlete, achievement-type)`: Checks achievement status

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `err-deployer-only` | Action restricted to contract deployer |
| u101 | `err-record-not-found` | Requested record does not exist |
| u102 | `err-duplicate-entry` | Entry already exists (e.g., duplicate feedback) |
| u103 | `err-access-denied` | User not authorized for this action |
| u104 | `err-validation-failed` | Input validation failed |

## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for deployment

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd fitquest
```

2. Install Clarinet (if not already installed):
```bash
curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz | tar xz
```

3. Check the contract:
```bash
clarinet check
```

4. Run tests:
```bash
clarinet test
```

### Deployment

1. Configure your deployment settings in `Clarinet.toml`

2. Deploy to testnet:
```bash
clarinet deploy --testnet
```

3. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

## Usage Examples

### Creating Your First Workout Routine

```clarity
(contract-call? .fitquest create-workout-routine
  "HIIT Cardio"
  "intense"
  "cardio"
  "Jump rope"
  u30
  u150)
```

### Logging a Training Session

```clarity
(contract-call? .fitquest record-training-session
  u1  ;; routine-index
  "Morning HIIT"
  u10  ;; warm-up-mins
  u155  ;; target-heart-rate
  u3  ;; reps-completed
  u4  ;; effort-rating
  u4  ;; form-quality
  "Great session, felt strong!"
  true)  ;; goal-achieved
```

### Submitting Feedback

```clarity
(contract-call? .fitquest submit-feedback
  u1  ;; routine-index
  u9  ;; score
  "Excellent routine! Really challenging."
  "great")
```

## Security Considerations

- **Input Validation**: All user inputs are validated for length and range
- **Duplicate Prevention**: Mechanisms prevent duplicate feedback and achievement claims
- **Access Control**: Users cannot manipulate others' data or kudos their own feedback
- **Token Supply**: Hard cap on token supply prevents inflation
- **No Token Transfer**: Tokens are non-transferable (mint-only design)

## Development Roadmap

- [ ] Implement workout routine categories and filtering
- [ ] Add social features (following, workout buddies)
- [ ] Create leaderboards for various metrics
- [ ] Implement workout streak tracking
- [ ] Add nutrition tracking integration
- [ ] Build mobile-friendly frontend interface
- [ ] Integrate with fitness wearables
- [ ] Add NFT badges for achievements

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Testing

Run the full test suite:
```bash
clarinet test
```

Run specific test file:
```bash
clarinet test tests/fitquest_test.ts
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or feature requests:
- Open an issue on GitHub
- Join our Discord community
- Email: support@fitquest.io

## Acknowledgments

- Built on the Stacks blockchain
- Powered by Clarity smart contracts
- Inspired by the fitness and Web3 communities

---

**Stay fit, stay blockchain!** 💪⛓️
