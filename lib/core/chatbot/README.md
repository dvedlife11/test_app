# BUDDY Chatbot System

## Overview

BUDDY is a behavioral performance chatbot built on the **Johnson Master v11** framework. It tracks user behavior, detects patterns, and delivers contextual, pressure-calibrated responses designed to drive execution not motivation.

**Core Principle:** Behavior > Words | Execution > Emotion | Consistency > Intensity

---

## Architecture

### Directory Structure

```
lib/core/chatbot/
├── models/
│   ├── chatbot_state.dart          # Current user state assessment
│   ├── detection_signals.dart      # Behavioral signals extracted from data
│   ├── chatbot_response.dart       # Final response structure & modes
│   ├── chatbot_message.dart        # Conversation messages & history
│   └── chatbot_response_memory.dart # Memory to avoid repetition
├── detection/
│   └── behavioral_detector.dart    # Extracts signals from core data
├── interpretation/
│   └── interpretation_engine.dart  # Converts signals → insights
├── override/
│   └── override_system.dart        # HIGH_REACTIVITY & OUT_OF_SCOPE overrides
├── generation/
│   └── message_generator.dart      # State → message mapping
├── openai/
│   └── openai_integration.dart     # OpenAI API integration (TODO)
├── memory/
│   └── chatbot_memory_store.dart   # Persistence & CRM sync
├── ui/
│   ├── buddy_chatbot_widget.dart   # Chat UI component
│   └── buddy_chat_page.dart        # Full-screen chat page
└── johnson_chatbot_engine.dart     # Main orchestrator
```

---

## Execution Pipeline

BUDDY follows the exact **Johnson Master execution order**:

### 1. **EXECUTION LAYER**
- Check: `minimum_standard_met` (app used OR core action completed OR counters partially met)
- If FALSE → "off track" (no discussion)
- If TRUE → proceed to detection

### 2. **DETECTION**
Extract signals from user behavior:
- **Counter signals:** manipulation, avoidance, low confidence
- **Catch signals:** trigger reactions, catch distribution
- **Pattern signals:** overfocus, neglect, fragmentation, pressure avoidance
- **Reactivity signals:** recent edits, catches, venting, low execution

### 3. **INTERPRETATION**
Convert signals into structured insights:
- **Manipulation intensity:** LOW / MEDIUM / HIGH
- **Dominant catch pattern:** TRIGGER_3D / MENTAL_DIET / DWELLING
- **Override state:** HIGH_REACTIVITY / OUT_OF_SCOPE / NONE
- **State vs behavior mismatch:** detected from quiz vs actual behavior

### 4. **OVERRIDE AUTHORITY** (if applicable)
- **HIGH_REACTIVITY**: De-escalate + refocus (user reacting, not executing)
  - Mode: STABILIZE
  - Pressure: MEDIUM
  - Message: "Pause. You're reacting. Pick one and continue."
  
- **OUT_OF_SCOPE**: Simplify + restore (fragmented, chaotic, low execution)
  - Mode: PUSH
  - Pressure: HIGH
  - Message: "Drop everything else. Just the umbrella today."

### 5. **OUTPUT MODULATION**
Generate final response:
- **Ground truth:** execution/behavior reality
- **Movement:** forward / stagnant / slipping
- **Direction:** actionable next step
- **Mode:** push / stabilize / call_out
- **Pressure:** low / medium / high
- **Boost:** short message (no input needed)

### 6. **FINAL VALIDATION**
Check for contradictions:
- No mixed tones
- All signals resolved into ONE direction

---

## Response Modes

```
PUSH       → Movement forward, expand ceiling
STABILIZE  → Fragile improvement, lock behavior  
CALL_OUT   → No execution, inconsistency
```

## Pressure Levels

```
LOW        → Guide (compassionate)
MEDIUM     → Push (firm)
HIGH       → Call out hard (no excuses)
```

## Boost Messages (No-Input Correction)

Tap BOOST button for instant redirect:
- **Push:** "Stop thinking. Do the reps."
- **Reassurance:** "You're not off. Stay in it."
- **Call-out:** "You already know what to do."
- **Momentum:** "Keep going. Don't break the chain."
- **Identity:** "You're not the version that quits now."

---

## Mode Protection

Each mode has boundaries to prevent abuse:

### CATCH Mode
- No long analysis
- No explanation loops
- Blocks: "Why did this happen?"

### DAILY Mode
- No emotional dumping
- Max input length: 500 chars
- Blocks: Long venting texts

### COACHING Mode
- No interruption logic
- No real-time correction
- Coaching is short, precise, action-focused

### Misuse Handling
1. 1st misuse → educate
2. 2nd misuse → correct
3. 3rd misuse → block

---

## Integration Points

### Wire to Existing Core Data

Update `BehavioralDetector.detect()` to read from actual core models:
- `DailyCompiledState` → execution, instability, counters
- `BehaviorPatterns` → edits, consistency, triggers
- `DailyEventRecord` → catches, reactions, system changes

### Use Actual State

```dart
// In JohnsonChatbotEngine.processMessage()
final actualSignals = BehavioralDetector.detect(
  todayState: coreData.todayCompiledState,
  patterns: coreData.behaviorPatterns,
  recentEvents: coreData.recentEvents,
);
```

### CRM Sync

After each response, update core CRM:
```dart
await chatbotMemoryStore.syncToCRM(
  userID: userId,
  detectionSignals: signals.toMap(),
  responseDirection: response.direction,
);
```

---

## OpenAI Integration (TODO)

Currently using rule-based responses. To enable OpenAI:

1. Get API key from OpenAI
2. Update `OpenAIIntegration.callOpenAI()`
3. Pass system prompt + context messages
4. Parse response into `ChatbotResponse`

Example flow:
```dart
final response = await openAI.generateConversationalResponse(
  userMessage: userInput,
  systemState: currentState,
  mode: finalMode,
  pressure: finalPressure,
  conversationContext: conversation.getRecentContext(),
);
```

---

## Data Flow Example

```
User types: "I switched my affirmation again"

↓ [DETECTION]
- affirmation_edited detected
- editFrequency > 3
- executionScore < 50
→ affirmationAvoidanceSignal = TRUE

↓ [INTERPRETATION]
- manipulationIntensity = MEDIUM
- multiple signals present
- InstabilityScore > 60, no umbrella
→ fragmentationPattern = TRUE

↓ [OVERRIDE CHECK]
- recentEdits > 2 ✓
- recentCatches > 1 ✓
- lowExecution ✓
→ HIGH_REACTIVITY triggered

↓ [OUTPUT] (override suppresses normal logic)
- Mode: STABILIZE (lock, don't change)
- Pressure: MEDIUM (firm but supportive)
- Boost: "You're overcorrecting. Stop adjusting. Start doing."

↓ [RESPONSE]
"You're overcorrecting. Stop adjusting. Start doing.
Nothing needs to change right now. Stay with what you chose."
```

---

## Memory & Prevention of Repetition

BUDDY remembers:
- `last_direction_given` → don't repeat samma message
- `repeated_trigger_counter` → escalate if same issue happens again
- `anchor_rotation` → rotate through different anchors

Rules:
- If user ignores direction → increment counter
- If repeat ignored → escalate pressure OR redirect to library/coaching
- Anchors rotate to prevent "that again?" feeling

---

## Testing Checklist

- [ ] Detection signals correctly extracted
- [ ] HIGH_REACTIVITY triggers on multi-edit + catches
- [ ] OUT_OF_SCOPE triggers on fragmentation
- [ ] Messages map correctly to states
- [ ] Boost system works (no input required)
- [ ] Mode protection blocks misuse
- [ ] CRM sync updates user profile
- [ ] OpenAI integration works (when API key added)
- [ ] Conversation history persists
- [ ] Memory prevents repetition

---

## Future Enhancements

1. **OpenAI Integration**: Replace rule-based with conversational LLM
2. **Real CRM Sync**: Persist to actual database
3. **Analytics Dashboard**: Track boost usage, response effectiveness
4. **A/B Testing**: Test different message variants
5. **Voice Integration**: Voice-based chat (transcribe → response)
6. **Coaching Handoff**: Smart redirect to library or coaching mode
7. **Behavioral Coaching**: Coach specific patterns detected

---

## Key Files to Modify

1. `lib/main.dart` → Add chatbot route
2. `lib/navigation_grid.dart` → Add "Chat with BUDDY" tile
3. `lib/app_repository.dart` → Add methods to get core data for detection
4. `pubspec.yaml` → Add OpenAI package (when ready)

---

## Version: BUDDY v1.0 (MVP)

Based on: Johnson Master v11
Build Date: 30 May 2026
Status: Production-ready (OpenAI integration pending)
