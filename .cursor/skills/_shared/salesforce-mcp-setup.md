# Salesforce MCP Setup Guide

**Purpose**: Step-by-step guide to enable Salesforce MCP integration for real-time org validation.

**Time Required**: 10-15 minutes (one-time setup)

**Phase**: 3a - Metadata & Schema Validation (Read-Only)

---

## What You'll Enable

After setup, your Cursor Skills will be able to:
- ✅ Validate objects and fields exist in your org
- ✅ Get actual picklist values for forms
- ✅ Check SOQL queries against live schema
- ✅ Verify org capacity and governor limits
- ✅ Discover custom objects and relationships

**Important**: MCP is **optional**. Skills work without it (with warnings).

---

## Prerequisites

### 1. Verify Salesforce CLI Installed

```bash
sf --version
```

**Expected Output**: `@salesforce/cli/2.x.x` or higher

**If not installed**:
```bash
# macOS
brew install sf

# Windows
# Download from: https://developer.salesforce.com/tools/sfdxcli

# Linux
npm install -g @salesforce/cli
```

### 2. Have a Salesforce Org
You need access to:
- **Sandbox** (recommended for development)
- **Developer Edition** (free, create at developer.salesforce.com)
- **Production** (NOT recommended until Phase 3d)

**Recommendation**: Use a dedicated sandbox for AI-assisted development.

---

## Setup Steps

### Step 1: Authenticate Your Salesforce Org

Open terminal and run:

```bash
# Authenticate with web browser
sf org login web --set-default --alias MySandbox

# Follow browser prompts to login
# Use your Salesforce credentials
```

**What happens**:
1. Browser opens to Salesforce login
2. Login with your credentials
3. Click "Allow" to grant CLI access
4. Terminal shows "Successfully authorized..."

**Naming Convention**:
- Sandbox: `MySandbox`, `DevSandbox`, `UAT`, etc.
- Developer Edition: `MyDevOrg`, `AIDevOrg`, etc.
- Production: `Production` (only if you understand the risks)

### Step 2: Verify Authentication

```bash
# List authenticated orgs
sf org list
```

**Expected Output**:
```
=== Orgs
     ALIAS       USERNAME                  ORG ID              CONNECTED STATUS
──── ─────────── ───────────────────────── ─────────────────── ────────────────
(D)  MySandbox   you@company.com.sandbox   00D5g000001AbcXXX Connected
```

Look for:
- ✅ Alias you specified (e.g., MySandbox)
- ✅ "Connected" status
- ✅ (D) marker = default org

**If not showing**:
```bash
# Set as default if authentication succeeded but not marked default
sf config set target-org MySandbox
```

### Step 3: Set Environment Variable

**Purpose**: Tells MCP which org to query

**macOS/Linux (zsh)**:
```bash
# Add to shell configuration
echo 'export SALESFORCE_DEFAULT_ORG=MySandbox' >> ~/.zshrc

# Reload configuration
source ~/.zshrc

# Verify
echo $SALESFORCE_DEFAULT_ORG
# Should output: MySandbox
```

**macOS/Linux (bash)**:
```bash
echo 'export SALESFORCE_DEFAULT_ORG=MySandbox' >> ~/.bashrc
source ~/.bashrc
echo $SALESFORCE_DEFAULT_ORG
```

**Windows (PowerShell)**:
```powershell
[System.Environment]::SetEnvironmentVariable('SALESFORCE_DEFAULT_ORG', 'MySandbox', 'User')

# Restart terminal and verify
echo $env:SALESFORCE_DEFAULT_ORG
```

**Important**: Replace `MySandbox` with your actual org alias from Step 1.

### Step 4: Verify MCP Configuration

The `.mcp.json` file should already be configured (Phase 3a implementation). Verify:

```bash
# From project root
cat .mcp.json
```

**Expected content** (should include):
```json
{
  "mcpServers": {
    "salesforce": {
      "command": "npx",
      "args": ["-y", "@salesforce/mcp", "--orgs", "${SALESFORCE_DEFAULT_ORG:-}", "--toolsets", "orgs,metadata,data"],
      "env": {
        "SALESFORCE_DEFAULT_ORG": "${SALESFORCE_DEFAULT_ORG}",
        "READ_ONLY": "true"
      }
    }
  }
}
```

**If salesforce section missing**: Phase 3a may not be implemented yet. Check with system administrator.

### Step 5: Restart Cursor

**Important**: Cursor must be restarted to load new MCP configuration.

1. Close all Cursor windows completely
2. Reopen Cursor
3. Open your project

### Step 6: Verify MCP Connection

In Cursor, check MCP status:

**Method 1: Check MCP Panel**
1. Open Command Palette (Cmd+Shift+P or Ctrl+Shift+P)
2. Search: "MCP: Show MCP Servers"
3. Look for "salesforce" server
4. Status should be "Connected" (green)

**Method 2: Test MCP Command**
Open terminal in Cursor:
```bash
# Test MCP connection
npx -y @salesforce/mcp --orgs MySandbox --toolsets orgs

# Should show org information without errors
```

**Expected Output**:
```json
{
  "orgId": "00D5g000001AbcXXX",
  "name": "MySandbox",
  "instanceUrl": "https://yourdomain--sandbox.sandbox.my.salesforce.com",
  "type": "Sandbox"
}
```

### Step 7: Test with a Skill

Verify integration by testing with Astro:

```
User: "/astro Check if Account object exists in my org"
```

**Expected Response (if setup correct)**:
```
Astro: Hi! I've checked your org (MySandbox).

✓ Account object exists (standard object)
✓ Found 142 fields including:
  - Id, Name, Industry, Phone, Website
  - CustomField__c, AnotherCustom__c (custom fields)
✓ 3 record types configured
✓ 2 existing triggers: AccountTrigger, AccountValidation

Anything specific you'd like to do with Account?
```

**Expected Response (if MCP not working)**:
```
Astro: ⚠️ Could not connect to Salesforce MCP.

I can still help you, but I won't be able to validate against your specific org configuration. Solutions will use standard Salesforce objects and you'll need to verify custom fields manually.

What would you like to build?
```

---

## Troubleshooting

### Issue: "org not authenticated"

**Symptom**: MCP queries fail with "No authenticated org found"

**Solution**:
```bash
# Check org list
sf org list

# If org missing, re-authenticate
sf org login web --set-default --alias MySandbox

# Verify environment variable is set
echo $SALESFORCE_DEFAULT_ORG

# Restart Cursor
```

### Issue: "SALESFORCE_DEFAULT_ORG not set"

**Symptom**: MCP can't find which org to query

**Solution**:
```bash
# Check if variable is set
echo $SALESFORCE_DEFAULT_ORG

# If empty, set it
export SALESFORCE_DEFAULT_ORG=MySandbox

# Make permanent (add to ~/.zshrc or ~/.bashrc)
echo 'export SALESFORCE_DEFAULT_ORG=MySandbox' >> ~/.zshrc
source ~/.zshrc

# Restart Cursor
```

### Issue: "Cannot find module @salesforce/mcp"

**Symptom**: MCP server fails to start

**Solution**:
```bash
# Manually install MCP package (will auto-install on first use)
npx -y @salesforce/mcp --help

# If still fails, clear npm cache
npm cache clean --force
npx -y @salesforce/mcp --help

# Restart Cursor
```

### Issue: MCP Status Shows "Disconnected"

**Symptom**: Salesforce MCP server in Cursor shows disconnected

**Checklist**:
1. ✅ Org authenticated? `sf org list`
2. ✅ Environment variable set? `echo $SALESFORCE_DEFAULT_ORG`
3. ✅ Variable name matches org alias? (case-sensitive)
4. ✅ Restarted Cursor after setup?
5. ✅ `.mcp.json` has salesforce section?

**Solution**:
```bash
# Verify complete setup
sf org list
echo $SALESFORCE_DEFAULT_ORG
cat .mcp.json | grep salesforce

# If all correct, try reconnecting org
sf org logout --target-org MySandbox
sf org login web --set-default --alias MySandbox

# Restart Cursor
```

### Issue: Skills Don't Use MCP

**Symptom**: Skills generate code but don't validate against org

**Possible Causes**:
1. MCP not connected (see above)
2. Skills not yet enhanced (check if Phase 3a complete)
3. Graceful degradation working (you'll see warnings)

**Expected Behavior**:
- If MCP working: "✓ Validated against your org: MySandbox"
- If MCP unavailable: "⚠️ Salesforce MCP unavailable. Using standard knowledge."

### Issue: Session Expired

**Symptom**: MCP worked before, now fails with "session expired"

**Solution**:
```bash
# Refresh authentication
sf org login web --target-org MySandbox

# No need to restart Cursor - MCP will use refreshed session
```

**Note**: Salesforce sessions expire after ~2 hours of inactivity. Just re-authenticate.

### Issue: Wrong Org Being Queried

**Symptom**: MCP queries different org than expected

**Solution**:
```bash
# Check which org is default
sf org list
# Look for (D) marker

# If wrong org is default, change it
sf config set target-org CorrectOrgAlias

# Update environment variable
export SALESFORCE_DEFAULT_ORG=CorrectOrgAlias

# Update permanently
echo 'export SALESFORCE_DEFAULT_ORG=CorrectOrgAlias' >> ~/.zshrc

# Restart Cursor
```

---

## Switching Orgs

To work with a different org:

### Temporary Switch (Current Session Only)
```bash
# Switch default org
sf config set target-org DifferentOrg

# Update environment variable for current terminal
export SALESFORCE_DEFAULT_ORG=DifferentOrg

# Restart Cursor to pick up change
```

### Permanent Switch
```bash
# Set new default
sf config set target-org DifferentOrg

# Update shell configuration
# macOS/Linux
echo 'export SALESFORCE_DEFAULT_ORG=DifferentOrg' >> ~/.zshrc
source ~/.zshrc

# Windows
[System.Environment]::SetEnvironmentVariable('SALESFORCE_DEFAULT_ORG', 'DifferentOrg', 'User')

# Restart Cursor
```

### Quick Test Different Org (Without Changing Default)
```bash
# Test MCP with specific org
SALESFORCE_DEFAULT_ORG=OtherOrg npx -y @salesforce/mcp --orgs OtherOrg --toolsets orgs
```

---

## Multiple Org Workflow

If you work with multiple orgs (Dev, QA, UAT, Production):

### Authenticate All Orgs Once
```bash
sf org login web --alias DevSandbox
sf org login web --alias QASandbox
sf org login web --alias UATSandbox
sf org login web --alias Production

# Verify all authenticated
sf org list
```

### Switch Between Orgs
```bash
# Switch to QA
sf config set target-org QASandbox
export SALESFORCE_DEFAULT_ORG=QASandbox
# Restart Cursor

# Switch to UAT
sf config set target-org UATSandbox
export SALESFORCE_DEFAULT_ORG=UATSandbox
# Restart Cursor
```

**Pro Tip**: Create shell aliases for quick switching:
```bash
# Add to ~/.zshrc
alias sf-dev='sf config set target-org DevSandbox && export SALESFORCE_DEFAULT_ORG=DevSandbox'
alias sf-qa='sf config set target-org QASandbox && export SALESFORCE_DEFAULT_ORG=QASandbox'
alias sf-uat='sf config set target-org UATSandbox && export SALESFORCE_DEFAULT_ORG=UATSandbox'

# Usage
sf-dev
# Restart Cursor
```

---

## Security Best Practices

### 1. Use Sandbox for Development
- ✅ Authenticate sandboxes for AI-assisted development
- ⚠️ Production requires additional safeguards (Phase 3d)

### 2. Read-Only Mode (Phase 3a)
Current configuration is read-only:
- ✅ Can query metadata
- ✅ Can validate SOQL
- ❌ Cannot execute Apex
- ❌ Cannot deploy code
- ❌ Cannot modify data

**This is intentional** for safety during Phase 3a.

### 3. Revoke Access
To revoke AI assistant access to your org:
```bash
# Remove authentication
sf org logout --target-org MySandbox

# Or revoke from Salesforce UI:
# Setup → Apps → Connected Apps → Manage Connected Apps
# Find "Salesforce CLI" → Revoke
```

### 4. Session Management
- Sessions expire after ~2 hours inactivity (Salesforce default)
- Re-authenticate when needed (see Troubleshooting)
- No credentials stored in project files

### 5. What MCP Can Access (Phase 3a)
- ✅ Object and field metadata (names, types, descriptions)
- ✅ Picklist values
- ✅ Record types
- ✅ Org limits and usage
- ❌ Actual record data
- ❌ User credentials
- ❌ Production data (unless you explicitly authenticate production)

---

## Uninstalling / Disabling MCP

### Temporary Disable (Keep Configuration)
```bash
# Logout org
sf org logout --target-org MySandbox

# MCP will gracefully fallback
# Skills will show: "⚠️ Salesforce MCP unavailable"
```

### Permanent Disable
```bash
# 1. Remove from .mcp.json
# Delete the "salesforce" section

# 2. Remove environment variable
# Remove from ~/.zshrc or ~/.bashrc:
# export SALESFORCE_DEFAULT_ORG=MySandbox

# 3. Logout org
sf org logout --target-org MySandbox

# 4. Restart Cursor
```

### Re-enable Later
Just follow Setup Steps again. Your previous authentication may still be valid.

---

## Verifying Phase 3a Status

Check if Phase 3a is fully implemented:

```bash
# 1. Check .mcp.json has salesforce section
grep -A 10 '"salesforce"' .mcp.json

# 2. Check knowledge registry exists
ls -l .cursor/skills/_shared/salesforce-mcp-knowledge.md

# 3. Check skills enhanced
grep -r "salesforce-mcp-knowledge" .cursor/skills/*/SKILL.md

# Expected: 4 skills reference salesforce-mcp-knowledge.md
```

---

## Getting Help

### Check Phase 3a Documentation
- Knowledge Registry: `.cursor/skills/_shared/salesforce-mcp-knowledge.md`
- This Setup Guide: `.cursor/skills/_shared/salesforce-mcp-setup.md`
- Implementation Plan: Check project documentation

### Salesforce CLI Help
```bash
# CLI help
sf --help

# Org commands
sf org --help

# Check CLI version
sf version
```

### MCP Server Help
```bash
# MCP help
npx -y @salesforce/mcp --help

# Test connection
npx -y @salesforce/mcp --orgs MySandbox --toolsets orgs
```

### Report Issues
If setup fails after following this guide:
1. Collect troubleshooting output (see Troubleshooting section)
2. Note your OS and Salesforce CLI version
3. Report to system administrator

---

## Next Steps After Setup

Once MCP is working:

1. **Test with Astro**: Ask to validate objects in your org
2. **Try Apex Developer**: Generate SOQL and see field validation
3. **Use LWC Developer**: Create forms with actual picklist values
4. **Check Solution Architect**: Design solutions validated against your org

**You'll know it's working when skills say**:
- "✓ Validated against your org: MySandbox"
- "Found X existing triggers..."
- "Object has Y fields including..."

---

## Summary

**Quick Setup Checklist**:
- [ ] Salesforce CLI installed (`sf --version`)
- [ ] Org authenticated (`sf org login web --alias MySandbox`)
- [ ] Environment variable set (`export SALESFORCE_DEFAULT_ORG=MySandbox`)
- [ ] Variable persisted (added to ~/.zshrc or ~/.bashrc)
- [ ] Cursor restarted
- [ ] MCP status "Connected" in Cursor
- [ ] Test with a skill shows org validation

**Time**: 10-15 minutes
**Difficulty**: Beginner-friendly
**Risk**: Zero (read-only, sandbox recommended)

**Benefits**:
- Catch field/object errors before code generation
- Get actual picklist values for forms
- Validate designs against your specific org
- Faster development with live feedback

---

**Version**: 1.0 (Phase 3a)
**Last Updated**: 2026-03-01
**Maintained By**: Salesforce Development Expert System
