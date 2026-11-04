<#
ai-agent-hub-zh 数据校验 —— 对标 public-apis 的「PR 触发 build 检查链接/格式」

校验项：
  1. JSON 可解析，且是数组
  2. 必填字段齐全
  3. url 以 http(s):// 开头
  4. category 在允许集合内
  5. cn_friendly / status 在允许枚举内
  6. name 与 url 均不重复
  7. 说明文字长度上限

任一失败 exit 1，供 GitHub Actions 挡住不合格 PR。
#>
[CmdletBinding()]
param([string]$DataPath)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
if (-not $DataPath) { $DataPath = Join-Path $root 'data/tools.json' }

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

$raw = Get-Content -LiteralPath $DataPath -Raw -Encoding UTF8
try { $tools = @($raw | ConvertFrom-Json) }
catch { $errors.Add("JSON 解析失败：$($_.Exception.Message)"); $tools = @() }

if ($tools.Count -eq 0) { $errors.Add('数据文件为空或不是数组') }

$required = @('category', 'name', 'platform', 'notes', 'url', 'cn_friendly', 'deploy', 'status')
$allowedCategories = @('编码代理', '破甲 Harness', 'Skills 库', '免费额度网关', '代理 / 中转')
$allowedCn = @('direct', 'proxy', '')
$allowedStatus = @('ok', 'unknown', 'dead')

$seenNames = @{}
$seenUrls = @{}
for ($i = 0; $i -lt $tools.Count; $i++) {
    $t = $tools[$i]
    $tag = "#$($i + 1) $([string]$t.name)"

    foreach ($f in $required) {
        if (-not ($t.PSObject.Properties.Name -contains $f) -or [string]::IsNullOrWhiteSpace([string]$t.$f)) {
            # cn_friendly 允许留空表示「未验证」
            if ($f -eq 'cn_friendly') { continue }
            $errors.Add("$tag 缺必填字段：$f")
        }
    }

    $u = [string]$t.url
    if ($u -and $u -notmatch '^https?://') { $errors.Add("$tag url 格式不合法：$u") }
    if ($u -and -not $u.StartsWith('https://')) { $warnings.Add("$tag 用的是 http 明文：$u") }

    $cat = [string]$t.category
    if ($cat -and $allowedCategories -notcontains $cat) { $errors.Add("$tag category 不在允许集合：$cat") }

    $cn = [string]$t.cn_friendly
    if ($allowedCn -notcontains $cn) { $errors.Add("$tag cn_friendly 非法（应为 direct/proxy/空）：$cn") }

    $st = [string]$t.status
    if ($st -and $allowedStatus -notcontains $st) { $errors.Add("$tag status 非法（应为 ok/unknown/dead）：$st") }

    $n = [string]$t.name
    if ($n) {
        if ($seenNames.ContainsKey($n)) { $errors.Add("$tag 项目名重复，与 #$($seenNames[$n]) 相同") }
        else { $seenNames[$n] = $i + 1 }
    }
    if ($u) {
        if ($seenUrls.ContainsKey($u)) { $errors.Add("$tag url 重复，与 #$($seenUrls[$u]) 相同") }
        else { $seenUrls[$u] = $i + 1 }
    }

    if (([string]$t.notes).Length -gt 160) { $warnings.Add("$tag notes 超过 160 字，建议精简") }
}

Write-Host ("校验完成：{0} 条，错误 {1}，警告 {2}" -f $tools.Count, $errors.Count, $warnings.Count)
foreach ($w in $warnings) { Write-Host "  [warn] $w" }
foreach ($e in $errors)   { Write-Host "  [ERROR] $e" }

if ($env:GITHUB_STEP_SUMMARY) {
    $md = @("### 数据校验", "", "条目 **$($tools.Count)** / 错误 **$($errors.Count)** / 警告 **$($warnings.Count)**")
    if ($errors.Count -gt 0) { $md += ''; $md += '```'; $md += $errors; $md += '```' }
    Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Value ($md -join "`n") -Encoding utf8
}

if ($errors.Count -gt 0) { exit 1 }
Write-Host '校验通过 ✅'
