# Create GitHub Repository using API
$token = $env:GITHUB_TOKEN
if (-not $token) {
    Write-Host "GitHub Token not found in environment" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Accept" = "application/vnd.github.v3+json"
}

$body = @{
    name = "opencode-coding"
    description = "OpenClaw Skill for AI programming with oh-my-opencode plugin"
    private = $false
    auto_init = $false
} | ConvertTo-Json -Compress

try {
    Write-Host "Creating GitHub repository..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method POST -Headers $headers -Body $body -ContentType "application/json"
    Write-Host "✓ Repository created successfully!" -ForegroundColor Green
    Write-Host "URL: $($response.html_url)"
} catch {
    Write-Host "✗ Failed to create repository" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorBody = $reader.ReadToEnd()
        Write-Host "Response: $errorBody"
    }
}
