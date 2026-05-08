# Step 2 GitHub Data Layer - Plan

## Current Task: fetch-my-prs

### TDD Approach
1. **RED**: Write failing tests for GHClient
2. **GREEN**: Implement minimal code to pass
3. **REFACTOR**: Clean up while keeping tests green

### Implementation Plan

#### 1. Create PR Model (PullRequest.swift)
- Codable struct for PR data
- Fields: number, title, url, author, state, isDraft, repository, updatedAt

#### 2. Create GHClient (GitHubClient.swift)
- Method: `fetchMyPRs() async throws -> [PullRequest]`
- Execute `gh pr list --author @me --json <fields>`
- Parse JSON response
- Return array of PullRequest models

#### 3. Create Tests (GitHubClientTests.swift)
- Test successful PR fetch and parse
- Test empty response
- Test gh CLI not available
- Test malformed JSON

#### 4. Integration with ContentView (later tasks)
- This task focuses only on the gh CLI wrapper
- UI integration is a separate task

### Acceptance Criteria
- Successfully fetches and parses PR list OR returns empty array
- Tests pass
- Build succeeds
