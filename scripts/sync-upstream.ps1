<#
ai-agent-hub-zh 上游更新检测

对 data/tools.json 中 url 指向 github.com 的条目，通过 GitHub REST API 拉取
star 数、最近 push 时间、是否归档，写回字段：
  stars / pushed_at / archived / synced_at

用法：
  ./scripts/sync-upstream.ps1                       # 匿名（60 次/小时，31 条够用）
  ./scripts/sync-upstream.ps1 -Token $env:GITHUB_TOKEN   # CI 用，5000 次/小时
  ./scripts/sync-upstream.ps1 -WhatIf              # 只打印不写文件

说明：
  - 非 GitHub 链接（官网、文档站）不查，保留已有字段；
  - 单个仓库查失败不中断整轮，只打印警告并跳过；
  - -MaxItems 同样只限制探测条数，不会截断数据文件（见 check_links.ps1 的教训）。
#>
[CmdletBinding()]
param(
    [string]$Token,
    [string]$DataPath,
    [int]$MaxItems = 0,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
if (-not $DataPath) { $DataPath = Join-Path $root 'data/tools.json' }
if (-not $Token) { $Token = $env:GITHUB_TOKEN }
if (-not $Token) { $Token = $env:GH_TOKEN }

$today = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
$tools = @(Get-Content -LiteralPath $DataPath -Raw -Encoding UTF8 | ConvertFrom-Json)
$probeSet = $tools
if ($MaxItems -gt 0 -and $probeSet.Count -gt $MaxItems) { $probeSet = @($probeSet[0..($MaxItems - 1)]) }

$headers = @{
    'Accept'               = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
    'User-Agent'           = 'ai-agent-hub-zh-sync'
}
if ($Token) { $headers['Authorization'] = 'Bearer ' + $Token }

function Get-UpstreamInfo {
    param([string]$RepoUrl)

    # 只处理形如 https://github.com/owner/repo[/...] 的链接
    if ($RepoUrl -notmatch '^https?://(?:www\.)?github\.com/([^/]+)/([^/#?]+)') { return $null }
    $owner = $Matches[1]
    $repo  = $Matches[2] -replace '\.git$', ''
    $api   = "https://api.github.com/repos/$owner/$repo"

    try {
        $resp = Invoke-RestMethod -Uri $api -Headers $headers -TimeoutSec 20 -ErrorAction Stop
        return @{
            stars       = [int]$resp.stargazers_count
            pushed_at   = [string]$resp.pushed_at
            archived    = [bool]$resp.archived
            description = [string]$resp.description
            full_name   = [string]$resp.full_name
        }
    }
    catch {
        $code = 0
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        Write-Host ("  ! 查询失败 {0}/{1}：HTTP {2} {3}" -f $owner, $repo, $code, $_.Exception.Message.Split([char]10)[0])
        return $null
    }
}

function Set-Field($obj, [string]$name, $value) {
    if ($obj.PSObject.Properties.Name -contains $name) { $obj.$name = $value }
    else { $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value -Force }
}

$synced = 0; $skipped = 0; $failed = 0
foreach ($t in $probeSet) {
    $u = [string]$t.url
    $info = Get-UpstreamInfo -RepoUrl $u
    if ($null -eq $info) {
        # 非 GitHub 链接静默跳过；GitHub 链接查询失败在 Get-UpstreamInfo 里已打印
        if ($u -notmatch 'github\.com') { $skipped++ }
        else { $failed++ }
        continue
    }
    Set-Field $t 'stars'     $info.stars
    Set-Field $t 'pushed_at' $info.pushed_at
    Set-Field $t 'archived'  $info.archived
    Set-Field $t 'synced_at' $today
    # 上游归档的项目，即使链接还活着，也标记成需要人工复核
    if ($info.archived -and [string]$t.status -eq 'ok') {
        Write-Host ("  ! {0} 上游已归档，status -> unknown 待人工复核" -f $info.full_name)
        $t.status = 'unknown'
    }
    Write-Host ("{0,-32} ★{1,-8} pushed={2}" -f $info.full_name, $info.stars, $info.pushed_at)
    $synced++
}

if (-not $WhatIf) {
    [System.IO.File]::WriteAllText($DataPath, (ConvertTo-Json -InputObject $tools -Depth 8), (New-Object System.Text.UTF8Encoding($false)))
}
Write-Host ("上游同步完成：更新 {0}，非 GitHub 跳过 {1}，失败 {2}{3}" -f $synced, $skipped, $failed, $(if ($WhatIf) { '（WhatIf，未写文件）' } else { '' }))

if ($env:GITHUB_STEP_SUMMARY) {
    $md = @()
    $md += "### 上游更新检测（$today）"
    $md += ''
    $md += "更新 **$synced** 个 GitHub 仓库 / 非 GitHub 跳过 **$skipped** / 查询失败 **$failed**"
    Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value ($md -join "`n") -Encoding utf8
}
