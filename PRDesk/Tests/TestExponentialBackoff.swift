//
//  TestExponentialBackoff.swift
//  PRDesk
//
//  Manual test harness for verifying exponential backoff behavior
//

/*
 MANUAL TEST: Exponential Backoff for Rate Limits

 This test harness documents the expected behavior and verification steps
 for the exponential backoff mechanism.

 ## Expected Behavior

 1. **Normal operation (no failures):**
    - Timer fires every 5 minutes
    - consecutiveFailures = 0
    - currentPollingInterval = 300 seconds

 2. **First failure:**
    - consecutiveFailures increments to 1
    - currentPollingInterval = 300 * 2^1 = 600 seconds (10 minutes)
    - Timer restarted with 10 minute interval
    - Log: "Exponential backoff: 1 consecutive failures, next poll in 10 minutes"

 3. **Second failure:**
    - consecutiveFailures increments to 2
    - currentPollingInterval = 300 * 2^2 = 1200 seconds (20 minutes)
    - Timer restarted with 20 minute interval
    - Log: "Exponential backoff: 2 consecutive failures, next poll in 20 minutes"

 4. **Third failure:**
    - consecutiveFailures increments to 3
    - currentPollingInterval = 300 * 2^3 = 2400 seconds (40 minutes)
    - Timer restarted with 40 minute interval
    - Log: "Exponential backoff: 3 consecutive failures, next poll in 40 minutes"

 5. **Fourth failure:**
    - consecutiveFailures increments to 4
    - currentPollingInterval = 300 * 2^4 = 4800 seconds (80 minutes)
    - BUT: Capped at maxInterval = 3600 seconds (60 minutes)
    - Timer restarted with 60 minute interval
    - Log: "Exponential backoff: 4 consecutive failures, next poll in 60 minutes"

 6. **Success after failures:**
    - consecutiveFailures reset to 0
    - currentPollingInterval reset to basePollingInterval (300 seconds)
    - Timer restarted with 5 minute interval
    - Log: "Resetting backoff (was N failures)"

 ## Verification Steps

 ### 1. Trigger network failure
 ```bash
 # Disconnect wifi or disable gh CLI temporarily
 # OR rename gh binary to simulate command failure
 sudo mv /opt/homebrew/bin/gh /opt/homebrew/bin/gh.bak
 ```

 ### 2. Launch app and monitor console
 ```bash
 open ~/Library/Developer/Xcode/DerivedData/PRDesk-*/Build/Products/Debug/PRDesk.app
 # Watch Console.app or Xcode console
 ```

 ### 3. Expected logs
 ```
 [Polling] Timer fired - refreshing PR data
 [Polling] ⚠️  Periodic refresh failed: ...
 [Polling] Exponential backoff: 1 consecutive failures, next poll in 10 minutes
 [Polling] Timer stopped
 [Polling] Starting periodic polling with 10 minute interval

 # 10 minutes later (or simulate by waiting)
 [Polling] Timer fired - refreshing PR data
 [Polling] ⚠️  Periodic refresh failed: ...
 [Polling] Exponential backoff: 2 consecutive failures, next poll in 20 minutes
 [Polling] Timer stopped
 [Polling] Starting periodic polling with 20 minute interval
 ```

 ### 4. Restore network and verify reset
 ```bash
 # Restore gh binary
 sudo mv /opt/homebrew/bin/gh.bak /opt/homebrew/bin/gh
 ```

 Expected logs:
 ```
 [Polling] Timer fired - refreshing PR data
 [Polling] ✅ Periodic refresh completed successfully
 [Polling] Resetting backoff (was 2 failures)
 [Polling] Timer stopped
 [Polling] Starting periodic polling with 5 minute interval
 ```

 ## Acceptance Criteria

 ✅ Consecutive failures tracked across polling cycles
 ✅ Polling interval increases exponentially: 5min → 10min → 20min → 40min → 60min
 ✅ Polling interval capped at 60 minutes (maxInterval)
 ✅ Backoff resets to 5 minutes after successful refresh
 ✅ Timer restarted with new interval after failures
 ✅ Console logs show backoff behavior clearly
 ✅ Build succeeds
 ✅ Rate limits handled gracefully (no app crash)

 ## Edge Cases

 1. **Many consecutive failures:** Should cap at 60 minutes, not grow indefinitely
 2. **Success after long backoff:** Should reset to 5 minutes immediately
 3. **Failure → Success → Failure:** Second failure should start backoff from scratch (5→10min)

 ## Implementation Notes

 - Uses exponential formula: interval = min(300 * 2^failures, 3600)
 - Timer recreated on interval change (no dynamic timer adjustment)
 - MainActor.run ensures thread-safe state updates
 - Backoff state persists across timer fires but not across app restarts
 */
