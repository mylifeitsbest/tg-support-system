# Set issue Priority on GitHub issue **Fields → Priority** (org issue field).
# Optionally mirrors onto Project Priority. Never use Labels `priority:*`.
#
# Usage: powershell -File scripts/agent/priority.ps1 <issue> <priority>
#   priority: urgent | high | medium | low
param(
  [Parameter(Mandatory = $true)][string]$Issue,
  [Parameter(Mandatory = $true)][string]$Priority
)

$ErrorActionPreference = "Stop"

if ($Issue -notmatch '^\d+$') {
  Write-Error "issue must be a number, got '$Issue'"
}

$key = ($Priority.ToLower() -replace '_', '-')
switch ($key) {
  'p0' { $key = 'urgent' }
  'critical' { $key = 'urgent' }
  'crit' { $key = 'urgent' }
  'p1' { $key = 'high' }
  'p2' { $key = 'medium' }
  'p3' { $key = 'low' }
  'med' { $key = 'medium' }
}

$allowed = @('urgent', 'high', 'medium', 'low')
if ($key -notin $allowed) {
  Write-Error "unknown priority '$Priority' (expected urgent|high|medium|low)"
}

$human = switch ($key) {
  'urgent' { 'Urgent' }
  'high' { 'High' }
  'medium' { 'Medium' }
  'low' { 'Low' }
}

# --- CHANGE_ME ---
$Repo = "CHANGE_ME/CHANGE_ME"
$IssuePriorityFieldId = "CHANGE_ME"
$IssuePriorityOptions = @{
  urgent = "CHANGE_ME"
  high   = "CHANGE_ME"
  medium = "CHANGE_ME"
  low    = "CHANGE_ME"
}
# Optional Project mirror (skip if still CHANGE_ME)
$Owner = "CHANGE_ME"
$ProjectNumber = 1
$ProjectId = "CHANGE_ME"
$ProjectPriorityFieldId = "CHANGE_ME"
$ProjectPriorityOptions = @{
  urgent = "CHANGE_ME"
  high   = "CHANGE_ME"
  medium = "CHANGE_ME"
  low    = "CHANGE_ME"
}

if ($Repo -eq "CHANGE_ME/CHANGE_ME" -or $IssuePriorityFieldId -eq "CHANGE_ME") {
  Write-Error "priority.ps1 still has CHANGE_ME — fill `$Repo and ISSUE_PRIORITY_*"
}

$issueOptionId = $IssuePriorityOptions[$key]
if (-not $issueOptionId -or $issueOptionId -like "CHANGE_ME*") {
  Write-Error "ISSUE_PRIORITY option for '$key' is still CHANGE_ME"
}

$meta = gh issue view $Issue --repo $Repo --json id,labels | ConvertFrom-Json
$issueNodeId = $meta.id
foreach ($lab in @($meta.labels)) {
  if ($lab.name -like 'priority:*') {
    gh issue edit $Issue --repo $Repo --remove-label $lab.name 2>$null | Out-Null
    Write-Host "priority: removed legacy label $($lab.name)"
  }
}

$gqlBody = [ordered]@{
  query = 'mutation($issueId:ID!, $fieldId:ID!, $optionId:ID!) { setIssueFieldValue(input: { issueId: $issueId, issueFields: [{ fieldId: $fieldId, singleSelectOptionId: $optionId }] }) { issue { id } } }'
  variables = [ordered]@{
    issueId = "$issueNodeId"
    fieldId = "$IssuePriorityFieldId"
    optionId = "$issueOptionId"
  }
}
$gqlFile = Join-Path $env:TEMP "agent-workflow-priority-$Issue.json"
[System.IO.File]::WriteAllText(
  $gqlFile,
  ($gqlBody | ConvertTo-Json -Compress -Depth 6),
  (New-Object System.Text.UTF8Encoding $false)
)
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$gqlOut = gh api graphql -H "GraphQL-Features: issue_fields" --input $gqlFile 2>&1
$gqlCode = $LASTEXITCODE
$ErrorActionPreference = $prevEap
Remove-Item -LiteralPath $gqlFile -ErrorAction SilentlyContinue
if ($gqlCode -ne 0 -or ("$gqlOut" -match '"errors"')) {
  Write-Error "priority: failed to set issue Fields Priority for #$Issue : $gqlOut"
}
Write-Host "priority: #$Issue Fields → Priority -> $human"

if ($Owner -eq "CHANGE_ME" -or $ProjectId -eq "CHANGE_ME" -or $ProjectPriorityFieldId -eq "CHANGE_ME") {
  exit 0
}
$pOpt = $ProjectPriorityOptions[$key]
if (-not $pOpt -or $pOpt -like "CHANGE_ME*") { exit 0 }

$itemJson = gh project item-list $ProjectNumber --owner $Owner --format json --limit 200
$items = ($itemJson | ConvertFrom-Json).items
$item = $items | Where-Object { $_.content.number -eq [int]$Issue } | Select-Object -First 1
if (-not $item) {
  Write-Host "priority: Project mirror skipped (#$Issue not on project yet)"
  exit 0
}
$ErrorActionPreference = 'Continue'
$editOut = gh project item-edit `
  --id $item.id `
  --project-id $ProjectId `
  --field-id $ProjectPriorityFieldId `
  --single-select-option-id $pOpt 2>&1
$editCode = $LASTEXITCODE
$ErrorActionPreference = $prevEap
if ($editCode -eq 0 -or ("$editOut" -match 'no changes to make')) {
  Write-Host "priority: #$Issue Project Priority mirrored -> $human"
} else {
  Write-Host "priority: warning: Project Priority mirror failed for #$Issue"
}
