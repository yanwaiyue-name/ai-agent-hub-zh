<#
ai-agent-hub-zh 渲染：从 data/tools.json 生成单文件 docs/index.html（不联网可用）

单文件网页自带搜索 / 分类筛选 / 状态筛选，标 star 与上游最近更新
（数据由 scripts/sync-upstream.ps1 每周从 GitHub API 拉取）。
#>
[CmdletBinding()]
param([string]$DataPath, [string]$OutPath)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
if (-not $DataPath) { $DataPath = Join-Path $root 'data/tools.json' }
if (-not $OutPath)  { $OutPath  = Join-Path $root 'docs/index.html' }

$tools = @(Get-Content -LiteralPath $DataPath -Raw -Encoding UTF8 | ConvertFrom-Json)

function Html-Escape($s) {
    if ($null -eq $s) { return '' }
    ([string]$s -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;')
}

$rows = New-Object System.Collections.Generic.List[string]
foreach ($t in $tools) {
    $status = [string]$t.status
    $badge = switch ($status) {
        'ok'     { '<span class="badge ok">✅ 存活</span>' }
        'dead'   { '<span class="badge dead">❌ 失效</span>' }
        default  { '<span class="badge unk">⚠️ 未验证</span>' }
    }
    $cn = [string]$t.cn_friendly
    $cnBadge = switch ($cn) {
        'direct' { '<span class="badge cn direct">墙内直连</span>' }
        'proxy'  { '<span class="badge cn proxy">需代理</span>' }
        default  { '<span class="badge cn">未验证</span>' }
    }
    $deploy = if ([string]$t.deploy) { '<code>' + (Html-Escape $t.deploy) + '</code>' } else { '—' }
    $stars = if ($t.stars) { '★' + [string]$t.stars } else { '—' }
    $pushed = if ($t.pushed_at) { ([string]$t.pushed_at).Substring(0, 10) } else { '—' }
    $archived = if ($t.archived -eq $true) { ' <span class="badge archived">已归档</span>' } else { '' }
    $cat = Html-Escape $t.category
    # 搜索索引：项目名 + 说明 + 平台 + 分类，压成小写供 JS 匹配
    $hay = (Html-Escape ((@($t.name, $t.notes, $t.platform, $t.category) -join ' ').ToLowerInvariant()))

    $rows.Add(@"
    <tr data-cat="$cat" data-status="$status" data-hay="$hay" data-stars="$(if ($t.stars) { [int]$t.stars } else { 0 })">
      <td><a href="$(Html-Escape $t.url)" target="_blank" rel="noopener">$(Html-Escape $t.name)</a>$archived<br><span class="meta">$(Html-Escape $t.platform)</span></td>
      <td><span class="cat">$cat</span></td>
      <td>$(Html-Escape $t.notes)</td>
      <td>$deploy</td>
      <td class="num">$stars<br><span class="meta">$pushed</span></td>
      <td>$cnBadge</td>
      <td>$badge</td>
    </tr>
"@)
}

$okCount   = @($tools | Where-Object { [string]$_.status -eq 'ok' }).Count
$deadCount = @($tools | Where-Object { [string]$_.status -eq 'dead' }).Count
$catList   = @($tools | ForEach-Object { [string]$_.category } | Sort-Object -Unique)
$catButtons = @('<button class="filter active" data-cat="all">全部</button>') +
              @($catList | ForEach-Object { '<button class="filter" data-cat="' + (Html-Escape $_) + '">' + (Html-Escape $_) + '</button>' })
$today = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')

$html = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>AI Agent 工坊 · 中文资源导航</title>
<style>
  :root { color-scheme: light dark; }
  body { font-family: -apple-system, "Segoe UI", "PingFang SC", "Microsoft YaHei", sans-serif; max-width: 1180px; margin: 2rem auto; padding: 0 1rem; color: #1a1a1a; line-height: 1.6; }
  h1 { text-align: center; margin-bottom: .3rem; }
  .sub { text-align: center; color: #666; margin: 0 0 1.5rem; }
  .summary { display: flex; gap: .8rem; justify-content: center; margin-bottom: 1.5rem; flex-wrap: wrap; }
  .summary div { background: #f5f5f7; border-radius: 8px; padding: .5rem 1.1rem; font-size: .9rem; }
  .toolbar { position: sticky; top: 0; background: var(--bg, #fff); padding: .8rem 0; border-bottom: 1px solid #e5e5e5; z-index: 5; }
  #q { width: 100%; box-sizing: border-box; padding: .6rem .9rem; font-size: 1rem; border: 1px solid #d0d0d0; border-radius: 8px; }
  .filters { margin-top: .6rem; display: flex; gap: .4rem; flex-wrap: wrap; align-items: center; }
  button.filter, button.sort { cursor: pointer; border: 1px solid #d0d0d0; background: #fafafa; color: #333; border-radius: 20px; padding: .25rem .8rem; font-size: .85rem; }
  button.filter.active { background: #0078d4; border-color: #0078d4; color: #fff; }
  table { width: 100%; border-collapse: collapse; font-size: .88rem; }
  th, td { text-align: left; padding: .55rem .6rem; border-bottom: 1px solid #eee; vertical-align: top; }
  th { background: #fafafa; position: sticky; top: 118px; }
  code { background: #f0f0f0; padding: .1rem .4rem; border-radius: 4px; font-size: .82em; word-break: break-all; }
  a { color: #0078d4; text-decoration: none; }
  a:hover { text-decoration: underline; }
  .badge { font-size: .78em; padding: .1rem .45rem; border-radius: 4px; white-space: nowrap; }
  .ok { color: #1a7f37; background: #dafbe1; } .dead { color: #cf222e; background: #ffebe9; } .unk { color: #9a6700; background: #fff8c5; }
  .cn.direct { background: #dafbe1; color: #116329; } .cn.proxy { background: #fff8c5; color: #7d4e00; } .cn { background: #f0f0f0; color: #666; }
  .archived { background: #f0f0f0; color: #666; }
  .cat { color: #0078d4; font-size: .85em; white-space: nowrap; }
  .meta { color: #888; font-size: .8em; }
  .num { white-space: nowrap; }
  #none { display: none; text-align: center; color: #888; padding: 2rem; }
  footer { margin-top: 3rem; text-align: center; color: #999; font-size: .85rem; }
  @media (prefers-color-scheme: dark) {
    body { background: #0d1117; color: #e6edf3; }
    .toolbar { --bg: #0d1117; border-color: #30363d; }
    .summary div, th, button.filter, button.sort, code { background: #161b22; color: #e6edf3; border-color: #30363d; }
    #q { background: #161b22; color: #e6edf3; border-color: #30363d; }
    td, th { border-color: #30363d; }
  }
</style>
</head>
<body>
<script src="https://yanwaiyue-name.github.io/yuese-nav/nav.js" data-site="ai-agent-hub-zh" data-theme="auto" data-max="1180" defer></script>
  <h1>🤖 AI Agent 工坊 · 中文资源导航</h1>
  <p class="sub">编码代理 / 破甲 Harness / Skills 库 / 免费额度网关 / 代理中转 — 每周自动体检</p>
  <div class="summary">
    <div>条目 <b id="total">$($tools.Count)</b></div>
    <div>存活 <b>$okCount</b></div>
    <div>失效 <b>$deadCount</b></div>
    <div>更新 <b>$today</b></div>
    <div>当前显示 <b id="shown">$($tools.Count)</b></div>
  </div>
  <div class="toolbar">
    <input id="q" type="search" placeholder="搜索项目名 / 说明 / 平台，例如：Rust、破甲、代理…" autocomplete="off">
    <div class="filters">
      $(($catButtons -join ' '))
      <button class="sort" id="sortStar">按 ★ 排序</button>
      <label style="font-size:.85rem;"><input type="checkbox" id="onlyOk"> 只看存活</label>
    </div>
  </div>
  <table id="t">
    <thead><tr><th>项目</th><th>分类</th><th>说明</th><th>一键部署</th><th>★ / 上游更新</th><th>国内网络</th><th>状态</th></tr></thead>
    <tbody>
$(($rows -join "`n"))
    </tbody>
  </table>
  <p id="none">没有匹配的项目，换个关键词试试。</p>
  <footer>本页由 scripts/render.ps1 从 data/tools.json 生成 · star 与更新时间由 sync-upstream.ps1 同步 · 仅供学习研究</footer>
<script>
(function () {
  var q = document.getElementById('q'),
      rows = Array.prototype.slice.call(document.querySelectorAll('#t tbody tr')),
      shown = document.getElementById('shown'),
      none = document.getElementById('none'),
      onlyOk = document.getElementById('onlyOk'),
      cat = 'all', starDesc = false;

  function apply() {
    var term = q.value.trim().toLowerCase(), n = 0;
    rows.forEach(function (r) {
      var ok = (cat === 'all' || r.dataset.cat === cat) &&
               (!term || r.dataset.hay.indexOf(term) !== -1) &&
               (!onlyOk.checked || r.dataset.status === 'ok');
      r.style.display = ok ? '' : 'none';
      if (ok) n++;
    });
    shown.textContent = n;
    none.style.display = n ? 'none' : 'block';
  }

  q.addEventListener('input', apply);
  onlyOk.addEventListener('change', apply);
  document.querySelectorAll('button.filter').forEach(function (b) {
    b.addEventListener('click', function () {
      document.querySelectorAll('button.filter').forEach(function (x) { x.classList.remove('active'); });
      b.classList.add('active'); cat = b.dataset.cat; apply();
    });
  });
  document.getElementById('sortStar').addEventListener('click', function () {
    starDesc = !starDesc;
    var body = document.querySelector('#t tbody');
    rows.sort(function (a, b) {
      return starDesc ? Number(b.dataset.stars) - Number(a.dataset.stars)
                      : Number(a.dataset.stars) - Number(b.dataset.stars);
    }).forEach(function (r) { body.appendChild(r); });
    this.textContent = starDesc ? '★ 从高到低' : '按 ★ 排序';
  });
})();
</script>
</body>
</html>
"@

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutPath) | Out-Null
[System.IO.File]::WriteAllText($OutPath, $html, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("已生成：$OutPath （$($tools.Count) 条）")
