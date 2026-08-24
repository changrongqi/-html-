<#
=====================================================================
 add-project.ps1 —— 一键把新的前端项目上传到本仓库（-html-）
=====================================================================
 用法（任选其一）：

  ① 交互式（最省心，按提示输入）：
       powershell -ExecutionPolicy Bypass -File .\add-project.ps1

  ② 直接传参：
       powershell -ExecutionPolicy Bypass -File .\add-project.ps1 `
         -Source "D:\我的项目" -Name "my-project"

 参数说明：
   -Source  要上传的内容：可以是【单个 HTML 文件】或【整个项目文件夹】
            （文件夹里建议包含 index.html）
   -Name    项目名（会作为仓库里的文件夹名）。不填时自动取文件夹名/文件名

 脚本会做的事：
   1. 把内容复制到本仓库下的 “项目名/” 目录（重复执行会覆盖更新）
   2. 自动 git add + git commit
   3. 自动 git push origin main，上传完成
=====================================================================
#>

param(
    [string]$Source,
    [string]$Name,
    [switch]$SkipPush   # 测试用：只复制+提交，不推送
)

$ErrorActionPreference = "Stop"

# 仓库根目录 = 本脚本所在目录
$RepoRoot = $PSScriptRoot

# ---------- 1. 确定源路径 ----------
if (-not $Source) {
    $Source = Read-Host "请输入要上传的项目路径（HTML 文件或整个文件夹）"
}
$Source = $Source.Trim().Trim('"').Trim("'")
if (-not $Source -or -not (Test-Path $Source)) {
    Write-Host "错误：路径不存在 → $Source" -ForegroundColor Red
    exit 1
}

# ---------- 2. 确定项目名 ----------
if (-not $Name) {
    $item = Get-Item $Source
    if ($item.PSIsContainer) {
        $Name = Split-Path $Source -Leaf
    } else {
        $Name = [System.IO.Path]::GetFileNameWithoutExtension($Source)
    }
}
# 清理非法字符（空格、冒号、斜杠等 -> 连字符）
$Name = ($Name -replace '[\\/:*?"<>|\s]', '-').Trim('-')
if (-not $Name) {
    Write-Host "错误：无法生成有效的项目名" -ForegroundColor Red
    exit 1
}

$DestDir = Join-Path $RepoRoot $Name
Write-Host "项目名：$Name" -ForegroundColor Cyan

# ---------- 3. 复制文件 ----------
New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
if ((Get-Item $Source).PSIsContainer) {
    Copy-Item -Path (Join-Path $Source '*') -Destination $DestDir -Recurse -Force
} else {
    Copy-Item -Path $Source -Destination (Join-Path $DestDir 'index.html') -Force
}
Write-Host "已复制到：$DestDir" -ForegroundColor Green

# ---------- 4. git 提交 + 推送 ----------
Push-Location $RepoRoot
try {
    git add -- $Name
    if ($LASTEXITCODE -ne 0) { Write-Host "git add 失败" -ForegroundColor Red; exit 1 }

    git commit -m "新增：$Name"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "git commit 失败（可能该目录没有任何改动）" -ForegroundColor Yellow
    }

    if ($SkipPush) {
        Write-Host "（已跳过推送，-SkipPush 测试模式）" -ForegroundColor Yellow
    } else {
        git push origin main
        if ($LASTEXITCODE -ne 0) {
            Write-Host "git push 失败：请检查网络，或登录 GitHub 后重试" -ForegroundColor Red
            exit 1
        }
    }
    Write-Host "完成！$Name 已上传到 https://github.com/changrongqi/-html-" -ForegroundColor Green
} finally {
    Pop-Location
}
