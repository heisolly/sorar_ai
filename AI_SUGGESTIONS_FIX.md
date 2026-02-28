# AI Suggestions Fix

## Problem

AI suggestions were not generating - the sparkles button showed "Couldn't generate suggestions. Try again!" error.

## Root Cause

When using `jsonMode: true` in the API request, OpenRouter requires the response to be a JSON **object** `{}`, not an array `[]`.

Our prompt was asking for:

```json
[
  {"label": "Playful", "text": "..."},
  ...
]
```

But the API's `json_object` mode requires:

```json
{
  "suggestions": [
    {"label": "Playful", "text": "..."},
    ...
  ]
}
```

## Solution

### Updated Prompt Format

Changed the prompt in `getCoachingSuggestions()` to request a JSON object:

**Before**:

```
Return ONLY valid JSON array:
[
  {"label": "Playful", "text": "..."},
  ...
]
```

**After**:

```
IMPORTANT: Return ONLY valid JSON in this exact format (must be an object, not an array):
{
  "suggestions": [
    {"label": "Playful", "text": "..."},
    ...
  ]
}
```

### Updated Parsing Logic

Changed the order of JSON parsing to check for object first:

**Before**:

1. Check if response is List
2. Check if response is Map with 'suggestions' key

**After**:

1. Check if response is Map with 'suggestions' key ✅
2. Fallback: Check if response is List (for compatibility)

## Code Changes

**File**: `lib/services/ai_service.dart`

```dart
// Prompt now requests object format
final prompt = '''
...
IMPORTANT: Return ONLY valid JSON in this exact format (must be an object, not an array):
{
  "suggestions": [
    {"label": "Playful", "text": "actual reply here"},
    {"label": "Curious", "text": "actual reply here"},
    {"label": "Simple", "text": "actual reply here"}
  ]
}
''';

// Parsing checks for object first
final decoded = jsonDecode(cleaned);
if (decoded is Map && decoded.containsKey('suggestions')) {
  final list = decoded['suggestions'] as List;
  return list.map((e) => Map<String, String>.from(e as Map)).toList();
} else if (decoded is List) {
  // Fallback if it returns array directly
  return decoded.map((e) => Map<String, String>.from(e as Map)).toList();
}
```

## Testing

### How to Test:

1. Start a conversation in Coach Screen
2. Send a few messages back and forth
3. Tap the sparkles (✨) icon
4. Wait for loading indicator
5. Bottom sheet should appear with 3 suggestions:
   - 🎀 Playful (Pink)
   - 🔵 Curious (Blue)
   - 🟢 Simple (Green)

### Expected Behavior:

- ✅ Loading indicator appears
- ✅ API call succeeds
- ✅ JSON parses correctly
- ✅ 3 suggestions display in bottom sheet
- ✅ Tapping suggestion fills input field

### Debug Logging:

The following debug prints help track the flow:

- `Suggestion Raw Response: {...}` - Shows API response
- `JSON Parse Error: ...` - Shows parsing errors if any
- `Suggestion Error: ...` - Shows general errors

## Why This Matters

The OpenRouter API (and OpenAI's API) have specific requirements for `response_format`:

- `json_object` mode → Must return `{...}` (object)
- Default mode → Can return any format

Our code was using `jsonMode: true` which sets `response_format: {type: 'json_object'}`, so we needed to match that requirement.

## Status

✅ **Fixed** - AI suggestions should now generate properly

## Related Files

- `lib/services/ai_service.dart` - Suggestion generation logic
- `lib/screens/coach_screen.dart` - Suggestion UI and handling
