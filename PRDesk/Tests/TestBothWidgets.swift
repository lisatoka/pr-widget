//
//  TestBothWidgets.swift
//  PRDesk
//
//  Manual visual verification test for both widgets
//
//  INSTRUCTIONS:
//  1. Build and launch the app
//  2. Verify TWO widgets appear on screen:
//     - Widget 1 (left): "My PRs" at x=100
//     - Widget 2 (right): "PRs I'm Tagged In" at x=420
//  3. Verify Widget 2 shows review-requested PRs (not "My PRs")
//  4. Verify both widgets have independent data
//  5. Verify highlight logic works in both:
//     - Open non-draft PRs = bright (opacity 1.0)
//     - Draft or closed PRs = dimmed (opacity 0.5)
//
//  ACCEPTANCE CRITERIA:
//  ✅ Widget 2 title is "PRs I'm Tagged In"
//  ✅ Widget 2 loads data from reviewRequestedPRs.json
//  ✅ Widget 2 uses same compact layout (title, repo, time)
//  ✅ Widget 2 applies highlight logic correctly
//  ✅ Both widgets are visible simultaneously
//  ✅ No overlap between widgets
//

import Foundation

print("""

=== Manual Visual Verification Test ===

This test requires manual verification. Follow these steps:

1. Launch the app:
   open ~/Library/Developer/Xcode/DerivedData/PRDesk-*/Build/Products/Debug/PRDesk.app

2. Verify both widgets appear:
   - Left widget: "My PRs" header
   - Right widget: "PRs I'm Tagged In" header

3. Check Widget 2 content:
   - Should show review-requested PRs (different from Widget 1)
   - Should have same layout: PR title, repo name, time
   - Should apply highlight logic (bright vs dimmed)

4. Verify positioning:
   - Widget 1 at x=100, y=100
   - Widget 2 at x=420, y=100
   - No overlap (320px horizontal gap)

5. Test highlight states:
   - Open non-draft PRs should be bright (full opacity)
   - Draft or closed PRs should be dimmed (50% opacity)

Expected outcome: Both widgets display correctly with independent data and proper highlighting.

===

""")
