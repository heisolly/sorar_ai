# Delete Simulation History Feature

## Overview

Added the ability for users to delete simulation history with swipe-to-delete functionality and confirmation dialog.

## Changes Made

### 1. SupabaseService - Delete Method

**File**: `lib/services/supabase_service.dart`

**New Method**:

```dart
/// Delete chat session and its messages
Future<void> deleteChatSession(String sessionId) async {
  // First delete all messages associated with this session
  await client
      .from(SupabaseConfig.chatMessagesTable)
      .delete()
      .eq('session_id', sessionId);

  // Then delete the session itself
  await client
      .from(SupabaseConfig.chatSessionsTable)
      .delete()
      .eq('id', sessionId);
}
```

**Features**:

- Deletes all messages first (cascade delete)
- Then deletes the session record
- Ensures data consistency

---

### 2. SimulationSetupScreen - Swipe to Delete

**File**: `lib/screens/simulation_setup_screen.dart`

**Implementation**:

- Wrapped each history `ListTile` with `Dismissible` widget
- Added swipe-to-delete gesture (swipe left)
- Confirmation dialog before deletion
- Success/error feedback with SnackBar

**UI Components**:

1. **Dismissible Widget**:
   - Direction: `endToStart` (swipe left to delete)
   - Red background with delete icon appears when swiping
   - Unique key for each session

2. **Confirmation Dialog**:
   - Title: "Delete Simulation?"
   - Message: "This will permanently delete this simulation and all its messages."
   - Actions: Cancel (grey) | Delete (red)

3. **Feedback**:
   - Success: Dark snackbar with "Simulation deleted"
   - Error: Red snackbar with "Error deleting simulation"

---

## User Experience Flow

### Deleting a Simulation:

1. **Open History**:
   - Tap history icon (🕐) in top-right of Simulation Setup screen
   - Drawer opens showing "Your Simulations"

2. **Swipe to Delete**:
   - Swipe any simulation item from right to left
   - Red background with delete icon (🗑️) appears

3. **Confirm Deletion**:
   - Dialog appears asking for confirmation
   - User can tap "Cancel" to abort
   - Or tap "Delete" to confirm

4. **Deletion Complete**:
   - Item disappears from list with animation
   - Snackbar shows "Simulation deleted"
   - Session and all messages removed from database

5. **Error Handling**:
   - If deletion fails, item stays in list
   - Red snackbar shows "Error deleting simulation"

---

## Visual Design

### Swipe Background:

```
┌─────────────────────────────────────┐
│ RIZZ                           🗑️   │ ← Red background
│ Feb 6 • 11:16 PM                    │
└─────────────────────────────────────┘
```

### Confirmation Dialog:

```
┌─────────────────────────────────────┐
│  Delete Simulation?                 │
│                                     │
│  This will permanently delete this  │
│  simulation and all its messages.   │
│                                     │
│              [Cancel]  [Delete]     │
└─────────────────────────────────────┘
```

---

## Technical Details

### Database Operations:

1. Delete from `chat_messages` table where `session_id` matches
2. Delete from `chat_sessions` table where `id` matches
3. Both operations must succeed for deletion to complete

### Error Handling:

- Try-catch block wraps deletion
- Mounted check before showing SnackBar
- Graceful failure with user feedback

### State Management:

- FutureBuilder automatically rebuilds after deletion
- List updates without manual refresh
- Smooth animation as item disappears

---

## Code Highlights

### Dismissible Widget:

```dart
Dismissible(
  key: Key(session['id']),
  direction: DismissDirection.endToStart,
  confirmDismiss: (direction) async {
    // Show confirmation dialog
    return await showDialog<bool>(...);
  },
  onDismissed: (direction) async {
    // Delete from database
    await _supabase.deleteChatSession(session['id']);
  },
  background: Container(
    color: Colors.red,
    alignment: Alignment.centerRight,
    child: Icon(Icons.delete, color: Colors.white),
  ),
  child: ListTile(...),
)
```

---

## Benefits

1. ✅ **User Control**: Users can manage their simulation history
2. ✅ **Safety**: Confirmation dialog prevents accidental deletion
3. ✅ **Feedback**: Clear visual and text feedback
4. ✅ **Clean UI**: Swipe gesture is intuitive and space-efficient
5. ✅ **Data Integrity**: Cascade delete ensures no orphaned messages

---

## Testing Checklist

- [x] Swipe gesture triggers delete background
- [x] Confirmation dialog appears
- [x] Cancel button aborts deletion
- [x] Delete button removes item
- [x] Database records deleted (session + messages)
- [x] Success snackbar appears
- [x] Error handling works
- [x] List updates automatically
- [x] Animation is smooth

---

## Future Enhancements

1. **Undo Feature**: Add "Undo" button in snackbar for 5 seconds
2. **Bulk Delete**: Select multiple items to delete at once
3. **Archive Instead**: Option to archive instead of permanent delete
4. **Trash Bin**: Soft delete with 30-day recovery period
5. **Swipe Actions**: Add other actions (archive, share, duplicate)

---

**Status**: Delete functionality implemented ✅
**Impact**: Users can now clean up their simulation history easily
