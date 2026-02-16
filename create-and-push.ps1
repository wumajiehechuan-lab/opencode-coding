# Create GitHub repo using stored credentials
$repoName = "opencode-coding"
$description = "OpenClaw Skill for AI programming with oh-my-opencode plugin"

# Use git credential-manager to get stored credentials
$credOutput = & git credential-manager get 2>&1 <<'EOF'
protocol=https
host=github.com
EOF

Write-Host "Attempting to create repository..."

# Alternative: use gh CLI if available
try {
    $ghCheck = & gh --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Using gh CLI to create repository..."
        & gh repo create "wumajiehechuan-lab/$repoName" --public --description "$description" --source=. --remote=origin --push
    } else {
        Write-Host "gh CLI not available. Please create repository manually:"
        Write-Host "1. Visit: https://github.com/new"
        Write-Host "2. Repository name: $repoName"
        Write-Host "3. Description: $description"
        Write-Host "4. Click 'Create repository'"
        Write-Host "5. Then run: git push -u origin master"
    }
} catch {
    Write-Host "Error: $_"
}
