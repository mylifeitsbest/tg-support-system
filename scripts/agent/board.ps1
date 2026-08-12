# Move a GitHub Issue card on the team board (Windows-friendly).
#
# Usage: powershell -File scripts/agent/board.ps1 <issue> <status>
#   status: backlog | ready | in-progress | in-review | done
#   optional: important (fill CHANGE_ME_IMPORTANT if your board has that column)
param(
  [Parameter(Mandatory = $true)][string]$Issue,
  [Parameter(Mandatory = $true)][string]$Status
)

$ErrorActionPreference = "Stop"
if ($Issue -notmatch '^\d+$') {
  Write-Error "issue must be a number, got '$Issue'"
}

# --- CHANGE_ME ---
$Owner = "mylifeitsbest"
$ProjectNumber = 2
$ProjectId = "PVT_kwHOC3yBd84BgJQP"
$StatusFieldId = "PVTSSF_lAHOC3yBd84BgJQPzhaXDTM"
$Repo = "mylifeitsbest/tg-support-system"
$StatusOptions = @{
  backlog      = "f75ad846"
  ready        = "47fc9ee4"
  "in-progress"= "98236657"
  "in-review"  = "165ec71f"
  done         = "73d5b50b"
  # important  = "CHANGE_ME_IMPORTANT"   # uncomment if you have this column
}

if ($Owner -eq "CHANGE_ME" -or $ProjectId -eq "CHANGE_ME" -or $StatusFieldId -eq "CHANGE_ME" -or $Repo -eq "CHANGE_ME/CHANGE_ME") {
  Write-Error "board.ps1 still has CHANGE_ME placeholders"
}

$statusKey = ($Status.ToLower() -replace '_', '-')
switch ($statusKey) {
  'progress' { $statusKey = 'in-progress' }
  'review' { $statusKey = 'in-review' }
}

$optionId = $StatusOptions[$statusKey]
if (-not $optionId -or $optionId -like "CHANGE_ME*") {
  Write-Error "unknown status '$Status' or option still CHANGE_ME"
}

$human = switch ($statusKey) {
  'backlog' { 'Backlog' }
  'important' { 'Important tasks' }
  'ready' { 'Ready' }
  'in-progress' { 'In progress' }
  'in-review' { 'In review' }
  'done' { 'Done' }
  default { $statusKey }
}

$itemJson = gh project item-list $ProjectNumber --owner $Owner --format json --limit 500
$items = ($itemJson | ConvertFrom-Json).items
$item = $items | Where-Object { $_.content.number -eq [int]$Issue } | Select-Object -First 1
if (-not $item) {
  $url = "https://github.com/$Repo/issues/$Issue"
  Write-Host "board: adding #$Issue to project $ProjectNumber"
  gh project item-add $ProjectNumber --owner $Owner --url $url | Out-Null
  $itemJson = gh project item-list $ProjectNumber --owner $Owner --format json --limit 500
  $items = ($itemJson | ConvertFrom-Json).items
  $item = $items | Where-Object { $_.content.number -eq [int]$Issue } | Select-Object -First 1
}
if (-not $item) {
  Write-Error "could not resolve project item for #$Issue"
}

gh project item-edit `
  --project-id $ProjectId `
  --id $item.id `
  --field-id $StatusFieldId `
  --single-select-option-id $optionId | Out-Null

Write-Host "board: #$Issue -> $human"

# Project rule: Done cards go to the TOP of the column (newest finished first).
if ($statusKey -eq 'done') {
  $posBodyObj = [ordered]@{
    query = 'mutation($projectId:ID!, $itemId:ID!) { updateProjectV2ItemPosition(input: { projectId: $projectId, itemId: $itemId }) { clientMutationId } }'
    variables = [ordered]@{
      projectId = "$ProjectId"
      itemId = "$($item.id)"
    }
  }
  $posFile = Join-Path $env:TEMP "agent-workflow-board-pos-$Issue.json"
  [System.IO.File]::WriteAllText(
    $posFile,
    ($posBodyObj | ConvertTo-Json -Compress -Depth 5),
    (New-Object System.Text.UTF8Encoding $false)
  )
  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  gh api graphql --input $posFile 2>$null | Out-Null
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prevEap
  Remove-Item -LiteralPath $posFile -ErrorAction SilentlyContinue
  if ($code -eq 0) {
    Write-Host "board: project Done -> moved to top"
  } else {
    Write-Host "board: warning: failed to move #$Issue to top of Done"
  }
}
