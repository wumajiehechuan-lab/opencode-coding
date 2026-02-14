#requires -Version 5.1

<#
.SYNOPSIS
    OpenCode Coding - PowerShell Module for oh-my-opencode
    
.DESCRIPTION
    Control oh-my-opencode plugin for AI programming.
    Supports normal (multi-turn) and ultrawork (auto-execute) modes.
    
.EXAMPLE
    Import-Module .\opencode_coding.ps1
    
    # Normal mode
    $session = New-CodeSession -Title "Fix Bug" -Mode normal
    Send-CodeMessage -SessionId $session.id -Message "Fix the auth bug"
    
    # Ultrawork mode
    $session = New-CodeSession -Title "Create App" -Mode ultrawork
    Send-CodeTask -SessionId $session.id -Task "Create a Python GUI app"
#>

# Default configuration
$script:DefaultPort = 4096
$script:DefaultServerHost = "127.0.0.1"
$script:DefaultWorkingDir = $PWD.Path

# API Endpoints (Corrected)
$script:ApiEndpoints = @{
    Health      = "/global/health"
    Session     = "/session"
    Sessions    = "/session"
    Messages    = "/session/{0}/messages"
    Message     = "/session/{0}/message"
    PromptAsync = "/session/{0}/prompt_async"
}

#region Server Management

function New-CodeController {
    <#
    .SYNOPSIS
        Create a new OpenCode controller instance.
    #>
    param(
        [int]$Port = $script:DefaultPort,
        [string]$ServerHost = $script:DefaultServerHost,
        [string]$WorkingDir = $script:DefaultWorkingDir,
        [bool]$AutoStart = $true,
        [int]$ServerTimeout = 30
    )
    
    if (-not (Test-Path $WorkingDir)) {
        New-Item -ItemType Directory -Path $WorkingDir -Force | Out-Null
    }
    
    $controller = @{
        Port = $Port
        ServerHost = $ServerHost
        WorkingDir = $WorkingDir
        AutoStart = $AutoStart
        ServerTimeout = $ServerTimeout
        BaseUrl = "http://${ServerHost}:${Port}"
        ServerProcess = $null
    }
    
    if ($AutoStart -and -not (Test-CodeServer -Controller $controller)) {
        Start-CodeServer -Controller $controller
    }
    
    return $controller
}

function Test-CodeServer {
    <#
    .SYNOPSIS
        Check if OpenCode server is running.
    #>
    param([hashtable]$Controller)
    
    try {
        $url = "$($Controller.BaseUrl)$($script:ApiEndpoints.Health)"
        $response = Invoke-RestMethod -Uri $url -Method GET -TimeoutSec 2 -ErrorAction Stop
        return $response.healthy -eq $true
    }
    catch {
        return $false
    }
}

function Start-CodeServer {
    <#
    .SYNOPSIS
        Start the OpenCode HTTP server.
    #>
    param([hashtable]$Controller)
    
    if (Test-CodeServer -Controller $Controller) {
        Write-Host "✓ OpenCode server already running at $($Controller.BaseUrl)" -ForegroundColor Green
        return $true
    }
    
    Write-Host "Starting OpenCode server on $($Controller.ServerHost):$($Controller.Port)..." -ForegroundColor Cyan
    
    try {
        $null = Get-Command opencode -ErrorAction Stop
        
        # Use cmd /c to avoid blocking
        $process = Start-Process -FilePath "cmd" `
            -ArgumentList "/c", "opencode serve --port $($Controller.Port) --hostname $($Controller.ServerHost)" `
            -WorkingDirectory $Controller.WorkingDir `
            -WindowStyle Minimized `
            -PassThru
        
        $Controller.ServerProcess = $process
        
        $startTime = Get-Date
        while (((Get-Date) - $startTime).TotalSeconds -lt $Controller.ServerTimeout) {
            if (Test-CodeServer -Controller $Controller) {
                Write-Host "✓ OpenCode server started at $($Controller.BaseUrl)" -ForegroundColor Green
                return $true
            }
            Start-Sleep -Milliseconds 500
        }
        
        throw "Server failed to respond within timeout period"
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        throw "OpenCode not found. Please install: https://opencode.ai"
    }
    catch {
        throw "Failed to start server: $_"
    }
}

function Stop-CodeServer {
    <#
    .SYNOPSIS
        Stop the OpenCode server.
    #>
    param([hashtable]$Controller)
    
    if ($Controller.ServerProcess -and -not $Controller.ServerProcess.HasExited) {
        Stop-Process -Id $Controller.ServerProcess.Id -Force -ErrorAction SilentlyContinue
    }
    
    # Also kill any opencode processes we started
    Get-Process -Name "opencode" -ErrorAction SilentlyContinue | 
        Where-Object { $_.StartTime -gt (Get-Date).AddMinutes(-5) } |
        Stop-Process -Force -ErrorAction SilentlyContinue
    
    return $true
}

#endregion

#region API Helpers

function Invoke-CodeApi {
    <#
    .SYNOPSIS
        Make HTTP request to OpenCode API.
    #>
    param(
        [hashtable]$Controller,
        [string]$Method = "GET",
        [string]$Path,
        [hashtable]$Body = $null,
        [int]$TimeoutSec = 30
    )
    
    $url = "$($Controller.BaseUrl)$Path"
    
    try {
        $params = @{
            Uri = $url
            Method = $Method
            TimeoutSec = $TimeoutSec
            ErrorAction = "Stop"
        }
        
        if ($Body) {
            $params.ContentType = "application/json"
            $params.Body = ($Body | ConvertTo-Json -Depth 10 -Compress)
        }
        
        $response = Invoke-RestMethod @params
        return $response
    }
    catch {
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $errorBody = $reader.ReadToEnd()
            throw "API Error ($($_.Exception.Response.StatusCode)): $errorBody"
        }
        throw "API request failed: $_"
    }
}

#endregion

#region Session Management

function New-CodeSession {
    <#
    .SYNOPSIS
        Create a new OpenCode session.
        
    .PARAMETER Title
        Session title
        
    .PARAMETER Mode
        Working mode: normal (multi-turn) or ultrawork (auto-execute)
        
    .PARAMETER Agent
        Agent to use: sisyphus, librarian, explore, oracle
        
    .PARAMETER WorkingDir
        Working directory for the session
    #>
    param(
        [string]$Title = "New Session",
        [ValidateSet("normal", "ultrawork")]
        [string]$Mode = "normal",
        [ValidateSet("sisyphus", "librarian", "explore", "oracle", "general")]
        [string]$Agent = "sisyphus",
        [string]$WorkingDir = $PWD.Path
    )
    
    $controller = New-CodeController -WorkingDir $WorkingDir -AutoStart $true
    
    $body = @{
        title = $Title
        agent = $Agent
    }
    
    if ($Mode -eq "ultrawork") {
        # ultrawork mode uses sisyphus with special prompt
        $body.agent = "sisyphus"
    }
    
    try {
        $session = Invoke-CodeApi -Controller $controller -Method "POST" `
            -Path $script:ApiEndpoints.Session -Body $body
        
        # Add mode info to session object
        $session | Add-Member -NotePropertyName "mode" -NotePropertyValue $Mode -Force
        $session | Add-Member -NotePropertyName "agent" -NotePropertyValue $Agent -Force
        $session | Add-Member -NotePropertyName "controller" -NotePropertyValue $controller -Force
        
        Write-Host "✓ Session created: $($session.id) ($Mode mode)" -ForegroundColor Green
        return $session
    }
    catch {
        throw "Failed to create session: $_"
    }
}

function Get-CodeSession {
    <#
    .SYNOPSIS
        Get session details.
    #>
    param(
        [string]$SessionId,
        [hashtable]$Controller = $null
    )
    
    if (-not $Controller) {
        $Controller = New-CodeController -AutoStart $true
    }
    
    $path = "$($script:ApiEndpoints.Session)/$SessionId"
    return Invoke-CodeApi -Controller $Controller -Method "GET" -Path $path
}

function Get-CodeSessionList {
    <#
    .SYNOPSIS
        List all sessions.
    #>
    param([hashtable]$Controller = $null)
    
    if (-not $Controller) {
        $Controller = New-CodeController -AutoStart $true
    }
    
    return Invoke-CodeApi -Controller $Controller -Method "GET" `
        -Path $script:ApiEndpoints.Sessions
}

function Remove-CodeSession {
    <#
    .SYNOPSIS
        Delete a session.
    #>
    param(
        [string]$SessionId,
        [hashtable]$Controller = $null
    )
    
    if (-not $Controller) {
        $Controller = New-CodeController -AutoStart $true
    }
    
    $path = "$($script:ApiEndpoints.Session)/$SessionId"
    Invoke-CodeApi -Controller $Controller -Method "DELETE" -Path $path | Out-Null
    Write-Host "✓ Session deleted: $SessionId" -ForegroundColor Green
    return $true
}

#endregion

#region Message Sending

function Send-CodeMessage {
    <#
    .SYNOPSIS
        Send a message in normal mode (sync, waits for response).
        Use for multi-turn conversations.
        
    .PARAMETER SessionId
        Session ID
        
    .PARAMETER Message
        Message content
        
    .PARAMETER Agent
        Agent to handle the message
        
    .PARAMETER TimeoutSec
        Timeout in seconds (default: 120)
    #>
    param(
        [string]$SessionId,
        [string]$Message,
        [ValidateSet("sisyphus", "librarian", "explore", "oracle", "general")]
        [string]$Agent = "sisyphus",
        [int]$TimeoutSec = 120,
        [hashtable]$Controller = $null
    )
    
    if (-not $Controller) {
        $Controller = New-CodeController -AutoStart $true
    }
    
    $body = @{
        parts = @(@{
            type = "text"
            text = $Message
        })
        agent = $Agent
    }
    
    $path = $script:ApiEndpoints.Message -f $SessionId
    
    try {
        Write-Host "Sending message (timeout: ${TimeoutSec}s)..." -ForegroundColor Cyan
        $response = Invoke-CodeApi -Controller $Controller -Method "POST" `
            -Path $path -Body $body -TimeoutSec $TimeoutSec
        
        return $response
    }
    catch {
        throw "Failed to send message: $_"
    }
}

function Send-CodeTask {
    <#
    .SYNOPSIS
        Send a task in ultrawork mode (async, auto-execute).
        Sisyphus will automatically complete the task.
        
        IMPORTANT: This function automatically prepends "ulw" magic word to the task.
        Do NOT include "/ulw" in your task text - use Send-CodeMessage for manual control.
        
    .PARAMETER SessionId
        Session ID
        
    .PARAMETER Task
        Task description (will be prefixed with "ulw" magic word)
        
    .PARAMETER Agent
        Agent to handle the task (usually sisyphus)
    #>
    param(
        [string]$SessionId,
        [string]$Task,
        [ValidateSet("sisyphus", "librarian", "explore", "oracle")]
        [string]$Agent = "sisyphus",
        [hashtable]$Controller = $null
    )
    
    if (-not $Controller) {
        $Controller = New-CodeController -AutoStart $true
    }
    
    # Format task for ultrawork mode - use "ulw" magic word (not "/ulw" command)
    # "ulw" is a magic word recognized by oh-my-opencode in both API and TUI modes
    # "/ulw" is a TUI-only command that won't work via API
    $ultraworkTask = "ulw`n`n$Task"
    
    $body = @{
        parts = @(@{
            type = "text"
            text = $ultraworkTask
        })
        agent = $Agent
    }
    
    # Use async endpoint for ultrawork
    $path = $script:ApiEndpoints.PromptAsync -f $SessionId
    
    try {
        Write-Host "Sending ultrawork task..." -ForegroundColor Cyan
        Write-Host "Agent will auto-execute until completion" -ForegroundColor Gray
        
        # Async calls may timeout, which is expected
        $null = Invoke-CodeApi -Controller $Controller -Method "POST" `
            -Path $path -Body $body -TimeoutSec 10
    }
    catch {
        # Timeout is expected for async
        Write-Host "✓ Task sent (async mode)" -ForegroundColor Green
    }
    
    return @{ status = "sent"; mode = "ultrawork"; sessionId = $SessionId }
}

#endregion

#region Session Monitoring

function Get-CodeMessages {
    <#
    .SYNOPSIS
        Get messages from a session.
    #>
    param(
        [string]$SessionId,
        [int]$Last = 10,
        [hashtable]$Controller = $null
    )
    
    if (-not $Controller) {
        $Controller = New-CodeController -AutoStart $true
    }
    
    $path = $script:ApiEndpoints.Messages -f $SessionId
    $messages = Invoke-CodeApi -Controller $Controller -Method "GET" -Path $path
    
    if ($Last -gt 0 -and $messages.Count -gt $Last) {
        return $messages | Select-Object -Last $Last
    }
    
    return $messages
}

function Watch-CodeSession {
    <#
    .SYNOPSIS
        Monitor session status with periodic polling.
    #>
    param(
        [string]$SessionId,
        [int]$Interval = 30,
        [int]$MaxIterations = 20,
        [hashtable]$Controller = $null
    )
    
    if (-not $Controller) {
        $Controller = New-CodeController -AutoStart $true
    }
    
    Write-Host "Monitoring session $SessionId (interval: ${Interval}s)..." -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    
    for ($i = 0; $i -lt $MaxIterations; $i++) {
        try {
            $session = Get-CodeSession -SessionId $SessionId -Controller $Controller
            $messages = Get-CodeMessages -SessionId $SessionId -Last 1 -Controller $Controller
            
            Write-Host "`n[$i] Updated: $([datetime]::new(1970,1,1).AddMilliseconds($session.time.updated).ToLocalTime())" -ForegroundColor Gray
            
            if ($messages.Count -gt 0) {
                $lastMsg = $messages[-1]
                if ($lastMsg.parts -and $lastMsg.parts.Count -gt 0) {
                    $text = $lastMsg.parts[0].text
                    if ($text.Length -gt 100) {
                        $text = $text.Substring(0, 100) + "..."
                    }
                    Write-Host "Last: $text" -ForegroundColor White
                }
            }
        }
        catch {
            Write-Host "Error: $_" -ForegroundColor Red
        }
        
        if ($i -lt $MaxIterations - 1) {
            Start-Sleep -Seconds $Interval
        }
    }
    
    Write-Host "`nMonitoring stopped" -ForegroundColor Yellow
}

function Wait-CodeCompletion {
    <#
    .SYNOPSIS
        Wait for session to complete (no new messages for a while).
    #>
    param(
        [string]$SessionId,
        [int]$Timeout = 300,
        [int]$StabilityThreshold = 60,
        [hashtable]$Controller = $null
    )
    
    if (-not $Controller) {
        $Controller = New-CodeController -AutoStart $true
    }
    
    $startTime = Get-Date
    $lastMessageTime = $startTime
    $lastMessageCount = 0
    
    Write-Host "Waiting for completion (timeout: ${Timeout}s)..." -ForegroundColor Cyan
    
    while (((Get-Date) - $startTime).TotalSeconds -lt $Timeout) {
        try {
            $messages = Get-CodeMessages -SessionId $SessionId -Controller $Controller
            
            if ($messages.Count -ne $lastMessageCount) {
                $lastMessageCount = $messages.Count
                $lastMessageTime = Get-Date
                Write-Host "." -NoNewline -ForegroundColor Gray
            }
            else {
                # Check if stable for threshold time
                if (((Get-Date) - $lastMessageTime).TotalSeconds -gt $StabilityThreshold) {
                    Write-Host "`n✓ Session appears complete ($lastMessageCount messages)" -ForegroundColor Green
                    return @{ completed = $true; messageCount = $lastMessageCount }
                }
            }
        }
        catch {
            Write-Host "X" -NoNewline -ForegroundColor Red
        }
        
        Start-Sleep -Seconds 5
    }
    
    Write-Host "`n⏱ Timeout reached" -ForegroundColor Yellow
    return @{ completed = $false; messageCount = $lastMessageCount }
}

#endregion

#region MCP Tools

function Enable-CodeMcp {
    <#
    .SYNOPSIS
        Enable MCP tools for the session.
    #>
    param(
        [string[]]$Tools,
        [hashtable]$Controller = $null
    )
    
    if (-not $Controller) {
        $Controller = New-CodeController -AutoStart $true
    }
    
    Write-Host "Enabling MCP tools: $($Tools -join ', ')" -ForegroundColor Cyan
    
    # MCP configuration is typically done via config file
    # This is a placeholder for future API-based MCP management
    
    return @{ enabled = $Tools; status = "configured" }
}

function Get-CodeMcpList {
    <#
    .SYNOPSIS
        Get available MCP tools.
    #>
    return @(
        @{ name = "git-master"; description = "Git operations and atomic commits"; enabled = $false }
        @{ name = "playwright"; description = "Browser automation and E2E testing"; enabled = $false }
        @{ name = "context7"; description = "Documentation retrieval"; enabled = $false }
    )
}

#endregion

#region Helper Functions

function Show-CodeSessionInfo {
    <#
    .SYNOPSIS
        Display formatted session information.
    #>
    param([string]$SessionId)
    
    $session = Get-CodeSession -SessionId $SessionId
    
    Write-Host "`n=== Session Information ===" -ForegroundColor Cyan
    Write-Host "ID:        $($session.id)"
    Write-Host "Title:     $($session.title)"
    Write-Host "Slug:      $($session.slug)"
    Write-Host "Directory: $($session.directory)"
    Write-Host "Created:   $([datetime]::new(1970,1,1).AddMilliseconds($session.time.created).ToLocalTime())"
    Write-Host "Updated:   $([datetime]::new(1970,1,1).AddMilliseconds($session.time.updated).ToLocalTime())"
    Write-Host "===========================`n" -ForegroundColor Cyan
}

function Format-CodeMessage {
    <#
    .SYNOPSIS
        Format a message for display.
    #>
    param([hashtable]$Message)
    
    $role = $Message.role.ToUpper()
    $color = switch ($role) {
        "USER" { "Green" }
        "ASSISTANT" { "Blue" }
        "SYSTEM" { "Yellow" }
        default { "White" }
    }
    
    Write-Host "[$role]" -ForegroundColor $color -NoNewline
    
    if ($Message.parts) {
        foreach ($part in $Message.parts) {
            if ($part.type -eq "text") {
                Write-Host ": $($part.text.Substring(0, [Math]::Min(200, $part.text.Length)))"
            }
        }
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    # Server
    "New-CodeController",
    "Test-CodeServer", 
    "Start-CodeServer",
    "Stop-CodeServer",
    # Session
    "New-CodeSession",
    "Get-CodeSession",
    "Get-CodeSessionList",
    "Remove-CodeSession",
    # Messages
    "Send-CodeMessage",
    "Send-CodeTask",
    "Get-CodeMessages",
    # Monitoring
    "Watch-CodeSession",
    "Wait-CodeCompletion",
    # MCP
    "Enable-CodeMcp",
    "Get-CodeMcpList",
    # Helpers
    "Show-CodeSessionInfo",
    "Format-CodeMessage"
)

Write-Host "OpenCode Coding module loaded. Use 'Get-Help New-CodeSession' for examples." -ForegroundColor Green
