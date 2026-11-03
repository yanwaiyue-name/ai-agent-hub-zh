<#
ai-agent-hub-zh 每周链接体检（复用 airport-nav 的两振出局 + 异地复核逻辑）

用法：
  ./scripts/check_links.ps1                          # 本地预检：无响应不判死，只标 unknown
  ./scripts/check_links.ps1 -Runner github-actions   # CI 环境：无响应才判 dead
  ./scripts/check_links.ps1 -ProxyUrl 127.0.0.1:7897  # 本机代理复核口径
  ./scripts/check_links.ps1 -SecondOpinion           # 准备判 dead 时换两个境外位置复核

判死规则：CI 环境下单次无响应不会直接判死 —— 上轮 ok 的降为 unknown，
上轮已是 unknown/dead 的才判 dead。加 -SecondOpinion 时再换 r.jina.ai 与
check-host.net 多国节点问一遍，只要有一处能看到就记 unknown，避免误杀。
#>
[CmdletBinding()]
param(
    [ValidateSet('local', 'github-actions')]
    [string]$Runner = 'local',
    [int]$TimeoutSec = 10,
    [int]$Retry = 2,
    [switch]$SecondOpinion,
    [int]$OpinionNodes = 3,
    [string]$ProxyUrl,
    [string]$DataPath,
    [int]$MaxItems = 0
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
if (-not $DataPath) { $DataPath = Join-Path $root 'data/tools.json' }
if (-not (Test-Path -LiteralPath $DataPath)) { throw "找不到数据文件：$DataPath" }

$today = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
$NL = [string][char]10
$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36'

# 本地默认清空代理环境变量：残留失效代理会误判活站为无响应
foreach ($v in @('HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'http_proxy', 'https_proxy', 'all_proxy')) {
    Remove-Item -Path "env:$v" -ErrorAction SilentlyContinue
}

function New-ProbeClient {
    param([int]$Timeout, [string]$Proxy)
    Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
    $h = [System.Net.Http.HttpClientHandler]::new()
    $h.AllowAutoRedirect = $true
    $h.MaxAutomaticRedirections = 5
    if ($Proxy) {
        $h.Proxy = [System.Net.WebProxy]::new($Proxy)
        $h.UseProxy = $true
    }
    else { $h.UseProxy = $false }
    $c = [System.Net.Http.HttpClient]::new($h)
    $c.Timeout = [TimeSpan]::FromSeconds($Timeout)
    [void]$c.DefaultRequestHeaders.TryAddWithoutValidation('User-Agent', $UserAgent)
    return $c
}

function Invoke-Probe {
    param($Client, [string]$Url, [string]$Method = 'Head')
    try {
        $verb = [System.Net.Http.HttpMethod]::new($Method.ToUpperInvariant())
        $req = [System.Net.Http.HttpRequestMessage]::new($verb, $Url)
        $resp = $Client.SendAsync($req, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        $code = [int]$resp.StatusCode
        $final = if ($resp.RequestMessage.RequestUri) { $resp.RequestMessage.RequestUri.AbsoluteUri } else { $Url }
        $resp.Dispose()
        return @{ Code = $code; Final = $final; Error = $null }
    }
    catch { return @{ Code = 0; Final = $null; Error = $_.Exception.Message } }
}

function Test-Url {
    param($Client, [string]$Url, [int]$Attempts = 2)
    $last = @{ Code = 0; Final = $null; Error = $null }
    for ($i = 1; $i -le [Math]::Max(1, $Attempts); $i++) {
        $head = Invoke-Probe -Client $Client -Url $Url -Method 'Head'
        if ($head.Code -gt 0 -and @(400, 405, 501) -notcontains $head.Code) { return $head }
        $get = Invoke-Probe -Client $Client -Url $Url -Method 'Get'
        if ($get.Code -gt 0) { return $get }
        $last = $get
        if ($i -lt $Attempts) { Start-Sleep -Seconds 3 }
    }
    return $last
}

function Get-RemoteFetchVerdict {
    param([string]$Url, [int]$TimeoutSec = 25)
    $client = $null
    try {
        $client = [System.Net.Http.HttpClient]::new()
        $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSec)
        [void]$client.DefaultRequestHeaders.TryAddWithoutValidation('User-Agent', $UserAgent)
        $resp = $client.GetAsync('https://r.jina.ai/' + $Url).GetAwaiter().GetResult()
        $code = [int]$resp.StatusCode
        $resp.Dispose()
        if ($code -ge 200 -and $code -lt 400) { return $true }
        if ($code -ge 400 -and $code -lt 500) { return $false }
        return $null
    }
    catch { return $null }
    finally { if ($client) { $client.Dispose() } }
}

function Get-NodeCheckVerdict {
    param([string]$Url, [int]$Nodes = 3, [int]$PollTimes = 6, [int]$PollSeconds = 4)
    $apiBase = 'https://check-host.net'
    $client = $null
    try {
        $client = [System.Net.Http.HttpClient]::new()
        $client.Timeout = [TimeSpan]::FromSeconds(15)
        [void]$client.DefaultRequestHeaders.TryAddWithoutValidation('Accept', 'application/json')
        $submit = ($client.GetStringAsync(('{0}/check-http?host={1}&max_nodes={2}' -f $apiBase, [uri]::EscapeDataString($Url), $Nodes)).GetAwaiter().GetResult()) | ConvertFrom-Json
        if (-not $submit.request_id) { return $null }
        for ($i = 1; $i -le $PollTimes; $i++) {
            Start-Sleep -Seconds $PollSeconds
            $poll = ($client.GetStringAsync(('{0}/check-result/{1}' -f $apiBase, $submit.request_id)).GetAwaiter().GetResult()) | ConvertFrom-Json
            $pending = 0; $answered = 0
            foreach ($p in $poll.PSObject.Properties) {
                if ($null -eq $p.Value) { $pending++; continue }
                foreach ($item in @($p.Value)) {
                    if ($null -eq $item) { continue }
                    $answered++
                    if ([int]$item[0] -eq 1) { return $true }
                }
            }
            if ($answered -gt 0 -and $pending -eq 0) { return $false }
        }
        return $null
    }
    catch { return $null }
    finally { if ($client) { $client.Dispose() } }
}

function Get-SecondOpinion {
    param([string]$Url, [int]$Nodes = 3)
    if ((Get-RemoteFetchVerdict -Url $Url) -eq $true) { return $true }
    if ((Get-NodeCheckVerdict -Url $Url -Nodes $Nodes) -eq $true) { return $true }
    return $false
}

# ---------------- 主流程 ----------------
$rawData  = Get-Content -LiteralPath $DataPath -Raw -Encoding UTF8 | ConvertFrom-Json
$tools    = @($rawData)
if ($MaxItems -gt 0 -and $tools.Count -gt $MaxItems) { $tools = @($tools[0..($MaxItems - 1)]) }
$client   = New-ProbeClient -Timeout $TimeoutSec
$proxyClient = $null
if ($ProxyUrl) { $proxyClient = New-ProbeClient -Timeout $TimeoutSec -Proxy $ProxyUrl; Write-Host ("已启用代理复核口径：" + $ProxyUrl) }

$rows = New-Object System.Collections.Generic.List[string]
$ok = 0; $unknown = 0; $dead = 0

try {
    foreach ($t in $tools) {
        foreach ($p in @('status', 'http_code', 'final_url', 'last_checked', 'checked_from')) {
            if (-not ($t.PSObject.Properties.Name -contains $p)) { $t | Add-Member -NotePropertyName $p -NotePropertyValue $null }
        }
        $prevStatus = [string]$t.status
        $u = [string]$t.url
        if ([string]::IsNullOrWhiteSpace($u) -or $u -notmatch '^https?://') { continue }
        $res = Test-Url -Client $client -Url $u -Attempts $Retry
        $best = $null
        if ($res.Code -gt 0) {
            $best = @{ Via = 'direct'; Code = $res.Code; Final = $res.Final }
        }
        elseif ($proxyClient) {
            $res2 = Test-Url -Client $proxyClient -Url $u -Attempts 1
            if ($res2.Code -gt 0) { $best = @{ Via = 'proxy'; Code = $res2.Code; Final = $res2.Final } }
        }

        if ($best) {
            $t.status = 'ok'
            $t.http_code = $best.Code
            $t.final_url = $best.Final
            $prevVia = [string]$t.reachable_via
            $newVia = $best.Via
            if ($newVia -eq 'direct' -and $prevVia -eq 'proxy') { $newVia = 'proxy' }
            if ($t.PSObject.Properties.Name -contains 'reachable_via') { $t.reachable_via = $newVia } else { $t | Add-Member -NotePropertyName 'reachable_via' -NotePropertyValue $newVia -Force }
        }
        else {
            $knownProxyOnly = ([string]$t.reachable_via -eq 'proxy' -and -not $ProxyUrl)
            if ($knownProxyOnly) {
                Write-Host ("{0}: 已知仅墙外可达，本环境无代理，保留原状态 {1}" -f $t.name, $t.status)
                $t.last_checked = $today; $t.checked_from = $Runner
                switch ($t.status) { 'ok' { $ok++ } 'dead' { $dead++ } default { $unknown++ } }
                continue
            }
            $t.http_code = 0; $t.final_url = $null
            if ($Runner -eq 'github-actions') {
                if ($prevStatus -eq 'ok') { $t.status = 'unknown' }
                elseif ($prevStatus -in @('unknown', 'dead')) {
                    $verdict = 'dead'
                    if ($SecondOpinion) {
                        Write-Host ("{0}: 本机两轮无响应，换境外位置复核……" -f $t.name)
                        if (Get-SecondOpinion -Url $u -Nodes $OpinionNodes) { $verdict = 'unknown'; Write-Host ("{0}: 别处能看到，本轮记 unknown" -f $t.name) }
                    }
                    $t.status = $verdict
                }
                else { $t.status = 'unknown' }
            }
            elseif ($t.status -ne 'dead') { $t.status = 'unknown' }
        }
        $t.last_checked = $today
        $t.checked_from = $Runner
        switch ($t.status) { 'ok' { $ok++ } 'dead' { $dead++ } default { $unknown++ } }
        Write-Host ("{0,-26} -> {1,-8} {2}" -f $t.name, $t.status, $t.http_code)
        $rows.Add(("| {0} | {1} | {2} | {3} | {4} |" -f $t.name, $t.category, $t.status, $t.http_code, $t.url))
    }
}
finally {
    $client.Dispose()
    if ($proxyClient) { $proxyClient.Dispose() }
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$jsonPretty = ConvertTo-Json -InputObject $tools -Depth 8
[System.IO.File]::WriteAllText($DataPath, $jsonPretty, $utf8)

$line = "体检完成（{0} / {1}）：存活 {2}，未验证 {3}，失效 {4}" -f $today, $Runner, $ok, $unknown, $dead
Write-Host $line

if ($env:GITHUB_STEP_SUMMARY) {
    $md = @()
    $md += "### AI Agent 工坊 链接体检（$today / $Runner）"
    $md += ''
    $md += "存活 **$ok** / 未验证 **$unknown** / 失效 **$dead**"
    $md += ''
    $md += '| 项目 | 分类 | 状态 | HTTP | 地址 |'
    $md += '|---|---|---|---|---|'
    $md += $rows
    Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value ($md -join $NL) -Encoding utf8
}
