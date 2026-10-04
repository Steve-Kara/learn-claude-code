# learn-claude-code 启动器
# 用法：双击 run.cmd，或 run.cmd s01_agent_loop

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$py = Join-Path $root '.venv\Scripts\python.exe'

# 关键：统一成 UTF-8。否则模型回复里的 ✓ / emoji / 框线字符在 GBK 控制台会抛
# UnicodeEncodeError，脚本跑到一半直接崩（我们实测踩过）。
# 注意：在这里设，而**不是**在 run.cmd 里用 chcp —— 实测 chcp 会把重定向的 stdin 吃掉。
$env:PYTHONIOENCODING = 'utf-8'
$env:PYTHONUTF8 = '1'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { }
try { [Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { }

if (-not (Test-Path $py)) {
  Write-Host '[x] 找不到 .venv，请先执行：' -ForegroundColor Red
  Write-Host '    python -m venv .venv'
  Write-Host '    .\.venv\Scripts\python.exe -m pip install -r requirements.txt'
  Read-Host '回车退出'
  exit 1
}

# 检查密钥是否还是占位符
$envFile = Join-Path $root '.env'
$placeholder = $true
if (Test-Path $envFile) {
  $keyLine = Select-String -Path $envFile -Pattern '^\s*ANTHROPIC_API_KEY\s*=\s*(.+)$' | Select-Object -First 1
  if ($keyLine -and $keyLine.Matches[0].Groups[1].Value.Trim() -notmatch 'PUT_YOUR|^$') { $placeholder = $false }
}
if ($placeholder) {
  Write-Host ''
  Write-Host '[!] .env 里的 API Key 还是占位符 —— 跑起来会在第一次请求时报 401。' -ForegroundColor Yellow
  Write-Host '    申请（1 分钟）： https://platform.deepseek.com/api_keys'
  Write-Host '    然后编辑 .env，把 ANTHROPIC_API_KEY 换成 sk- 开头的那串。'
  Write-Host ''
  $go = Read-Host '仍然要继续吗？(y/N)'
  if ($go -notmatch '^[yY]') { exit 0 }
}

function Get-Stages {
  Get-ChildItem $root -Directory |
    Where-Object { $_.Name -match '^s\d\d_' -and (Test-Path (Join-Path $_.FullName 'code.py')) } |
    Sort-Object Name | Select-Object -ExpandProperty Name
}

function Start-Stage([string]$name) {
  $file = Join-Path $root "$name\code.py"
  if (-not (Test-Path $file)) { Write-Host "[x] 没有 $name\code.py" -ForegroundColor Red; return }
  Write-Host ''
  Write-Host "=== 启动 $name （输入 q 退出）===" -ForegroundColor Cyan
  & $py $file
  Write-Host ''
}

if ($args.Count -gt 0 -and $args[0]) {
  Start-Stage $args[0]
  exit 0
}

while ($true) {
  try { Clear-Host } catch { }
  Write-Host '=================================================='
  Write-Host '  learn-claude-code  ·  17 级台阶，选一个开跑'
  Write-Host '=================================================='
  $stages = Get-Stages
  $i = 0
  foreach ($s in $stages) {
    $i++
    $desc = ''
    $rm = Join-Path $root "$s\README.zh.md"
    if (Test-Path $rm) {
      $h1 = Select-String -Path $rm -Pattern '^#\s+(.+)$' | Select-Object -First 1
      if ($h1) { $desc = ($h1.Matches[0].Groups[1].Value -replace '[#*`]', '').Trim() }
    }
    Write-Host ("  [{0,2}] {1,-24} {2}" -f $i, $s, $desc)
  }
  Write-Host ''
  Write-Host '  输入序号或目录名开跑；直接回车退出。'
  Write-Host '  进阶： agents\s_full.py 是全部功能的合体版。'
  Write-Host ''
  $choice = Read-Host '选择'
  if ([string]::IsNullOrWhiteSpace($choice)) { exit 0 }

  $target = $null
  $n = 0
  if ([int]::TryParse($choice.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $stages.Count) {
    $target = $stages[$n - 1]
  } elseif ($stages -contains $choice.Trim()) {
    $target = $choice.Trim()
  }
  if ($target) { Start-Stage $target; Read-Host '回车返回菜单' }
  else { Write-Host "[x] 不认识：$choice" -ForegroundColor Red; Start-Sleep -Seconds 1 }
}
