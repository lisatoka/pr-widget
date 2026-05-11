# Manual Test Guide: Customizable Claude Prompts

## Overview
This guide walks through testing the customizable Claude prompts feature.

## Prerequisites
- PRDesk app built successfully
- App is running

## Test 1: Default Config Creation

**Steps:**
1. Delete existing config (if any):
   ```bash
   rm ~/Library/Application\ Support/PRDesk/prompts.json
   ```

2. Launch PRDesk app

3. Open detail window by clicking any PR in a widget

4. Click "Open in Claude" button on any PR

5. Check if config file was created:
   ```bash
   ls -la ~/Library/Application\ Support/PRDesk/prompts.json
   ```

**Expected Result:**
- Config file exists
- File contains JSON with "myPRs" and "reviewRequested" fields
- Each field contains template variables like {pr_number}, {pr_title}, etc.

**Verify:**
```bash
cat ~/Library/Application\ Support/PRDesk/prompts.json
```

Should show:
```json
{
  "myPRs" : "I need help addressing reviewer feedback...",
  "reviewRequested" : "I've been asked to review this pull request..."
}
```

## Test 2: Template Variable Replacement

**Steps:**
1. Launch PRDesk app
2. Click "Open in Claude" button on a PR
3. Check Terminal window that opens
4. Verify the prompt contains actual PR data (not template variables)

**Expected Result:**
- Template variables {pr_number}, {pr_title}, etc. are replaced
- Prompt contains actual PR number (e.g., "PR #897126")
- Prompt contains actual PR title
- Prompt contains actual repository name
- Prompt contains actual PR URL

**Example:**
- Template: "PR #{pr_number}: {pr_title}"
- Result: "PR #897126: Fix authentication bug"

## Test 3: Custom Config File

**Steps:**
1. Edit config file:
   ```bash
   nano ~/Library/Application\ Support/PRDesk/prompts.json
   ```

2. Change myPRs template to:
   ```json
   {
     "myPRs" : "Custom prompt: Help me with PR {pr_number} titled '{pr_title}' in {repo_name}",
     "reviewRequested" : "I've been asked to review this pull request..."
   }
   ```

3. Save and quit (Ctrl+O, Enter, Ctrl+X)

4. Restart PRDesk app (killall PRDesk && open ...)

5. Click "Open in Claude" button on a PR in "My PRs" widget

**Expected Result:**
- Terminal opens with custom prompt
- Custom prompt contains replaced variables
- Example: "Custom prompt: Help me with PR 897126 titled 'Fix auth bug' in Canva/canva"

## Test 4: Invalid Config Fallback

**Steps:**
1. Corrupt the config file:
   ```bash
   echo "invalid json {{{" > ~/Library/Application\ Support/PRDesk/prompts.json
   ```

2. Restart PRDesk app

3. Click "Open in Claude" button

**Expected Result:**
- App doesn't crash
- Falls back to default hardcoded prompts
- Terminal opens with sensible default prompt
- Console log shows: "[ClaudeIntegrationService] Failed to load config: ..."

## Test 5: All Template Variables

**Supported variables:**
- {pr_number} - PR number
- {pr_title} - PR title
- {repo_name} - Repository full name (e.g., "owner/repo")
- {pr_url} - GitHub PR URL
- {pr_author} - PR author username
- {pr_state} - PR state (OPEN, CLOSED, MERGED)
- {pr_draft} - " (Draft)" if draft, empty otherwise

**Test prompt:**
```json
{
  "myPRs" : "PR {pr_number}: {pr_title}\nRepo: {repo_name}\nAuthor: {pr_author}\nState: {pr_state}{pr_draft}\nURL: {pr_url}",
  "reviewRequested" : "..."
}
```

**Steps:**
1. Replace prompts.json with test prompt above
2. Restart app
3. Click "Open in Claude"
4. Verify all variables are replaced correctly

## Success Criteria

✅ Config file created on first ClaudeIntegrationService init
✅ Config file is valid JSON with pretty formatting
✅ Template variables replaced with actual PR data
✅ Custom config file loaded and used
✅ Invalid config falls back to defaults gracefully
✅ All 7 template variables work correctly
✅ App doesn't crash with invalid config
✅ Homebrew users can customize without rebuilding

## Troubleshooting

**Config not created:**
- Make sure you clicked "Open in Claude" button (not just launched app)
- ClaudeIntegrationService.init() only runs when button is clicked

**Variables not replaced:**
- Check config file syntax (must be valid JSON)
- Verify variable names match exactly: {pr_number} not {pr_num}
- Restart app after editing config

**App crashes:**
- Check console logs for error messages
- Verify config file is valid JSON
- Delete config and let app recreate defaults
