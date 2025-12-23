# Create a GitHub private repository and push the current local repo to it.
# Usage: run this script in the repo root in PowerShell (Windows).
# It will ask for GitHub username, repository name and a Personal Access Token (PAT).
# The PAT needs repo scope ("repo") to create repositories and push.

param()

function Read-PlainToken {
    Write-Host "请输入你的 GitHub Personal Access Token (PAT)。输入时不会回显。" -ForegroundColor Yellow
    $sec = Read-Host -AsSecureString "PAT"
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try { $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) } finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    return $plain
}

# Interactive prompts
$cwd = Get-Location
Write-Host "当前目录: $cwd" -ForegroundColor Cyan

$user = Read-Host "GitHub 用户名（用户名或组织名）"
$repo = Read-Host "将创建的仓库名（例如 MyRepo）。若已存在，将提示后可选择使用现有仓库或改名。"
desc = Read-Host "仓库描述（可留空）"
$privateInput = Read-Host "是否创建为私有仓库？(Y/n)  默认为 Y"
$private = $true
if ($privateInput -and ($privateInput -match '^[nN]')) { $private = $false }

# Read token securely
$token = Read-PlainToken
if (-not $token) { Write-Error "未提供 PAT，终止。"; exit 1 }

$headers = @{ Authorization = "token $token"; "User-Agent" = "PowerShell" }
$body = @{ name = $repo; description = $desc; private = $private } | ConvertTo-Json

# Try to create the repo under the authenticated user
$createUri = "https://api.github.com/user/repos"
try {
    $resp = Invoke-RestMethod -Method Post -Uri $createUri -Headers $headers -Body $body -ContentType 'application/json' -ErrorAction Stop
    Write-Host "已创建仓库: $($resp.full_name)" -ForegroundColor Green
    $cloneUrl = $resp.clone_url
} catch {
    $err = $_.Exception.Response
    if ($err) {
        $status = $err.StatusCode.Value__
        $reader = New-Object System.IO.StreamReader($err.GetResponseStream())
        $text = $reader.ReadToEnd()
        Write-Host "GitHub API 返回 HTTP $status：" -ForegroundColor Yellow
        Write-Host $text

        if ($status -eq 422 -and $text -match 'name already exists') {
            Write-Host "仓库已存在。将使用已存在的仓库（如果你有权限），或者你可以退出并改名。" -ForegroundColor Yellow
            $useExisting = Read-Host "使用已存在的仓库并继续推送？(Y/n) 默认 Y"
            if ($useExisting -and $useExisting -match '^[nN]') { Write-Host "请重新运行并指定一个不同的仓库名。"; exit 1 }
            # attempt to get existing repo info
            $getUri = "https://api.github.com/repos/$user/$repo"
            try { $info = Invoke-RestMethod -Method Get -Uri $getUri -Headers $headers -ErrorAction Stop; $cloneUrl = $info.clone_url } catch { Write-Error "无法获取已存在仓库的信息，可能因为权限或仓库不属于你。错误: $_"; exit 1 }
        } else {
            Write-Error "创建仓库失败：$text"; exit 1
        }
    } else {
        Write-Error "网络或其它错误：$_"; exit 1
    }
}

Write-Host "将远程设置为: $cloneUrl" -ForegroundColor Cyan

# Save existing origin if present
$existingOrigin = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0 -and $existingOrigin) {
    Write-Host "检测到已设置的 origin: $existingOrigin" -ForegroundColor Yellow
    $bakName = "origin-backup-" + (Get-Date -Format "yyyyMMddHHmmss")
    git remote add $bakName $existingOrigin
    Write-Host "已把原 origin 备份为 $bakName" -ForegroundColor Green
    git remote remove origin
}

# Set new origin
git remote add origin $cloneUrl
if ($LASTEXITCODE -ne 0) { Write-Error "设置远程 origin 失败"; exit 1 }

# Ensure main branch exists locally; if not, attempt to use current branch
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
Write-Host "当前本地分支: $branch"

# Push all branches and tags
Write-Host "开始推送所有分支和标签到 $cloneUrl ..." -ForegroundColor Cyan

# Push current branch as main if remote empty; try set-upstream
try {
    git push --set-upstream origin $branch
    if ($LASTEXITCODE -ne 0) { throw "push failed with exit $LASTEXITCODE" }
    git push --all origin
    git push --tags origin
    Write-Host "推送完成。远程仓库地址: $cloneUrl" -ForegroundColor Green
} catch {
    Write-Warning "常规推送失败，尝试强制推送（--force-with-lease）"
    git push --force-with-lease origin $branch
    if ($LASTEXITCODE -ne 0) { Write-Error "强制推送也失败，检查网络/凭据/权限。错误: $_"; exit 1 }
    Write-Host "强制推送完成。远程仓库地址: $cloneUrl" -ForegroundColor Green
}

Write-Host "全部完成。请在 GitHub 上检查仓库并确保历史记录符合预期。若要删除本地为备份添加的 remote，可运行： git remote remove $bakName" -ForegroundColor Cyan

# Clear plaintext token from memory
$token = $null

exit 0

