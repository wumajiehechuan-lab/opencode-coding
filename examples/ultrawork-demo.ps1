# OpenCode Coding - Ultrawork 模式演示
# 本示例展示如何使用 ultrawork 全自动模式
# 
# ⚠️ 重要提示：使用 "ulw" 魔法词（不是 "/ulw" 指令）
# - "ulw" 是魔法词，API 和 TUI 模式都支持
# - "/ulw" 是 TUI 指令，仅在终端交互模式下有效

Import-Module .\opencode_coding.ps1

Write-Host "=== Ultrawork 模式演示 ===" -ForegroundColor Cyan

# ===== 示例 1：全自动开发 Web 应用 =====
Write-Host "`n1. 创建 ultrawork 会话并发送任务" -ForegroundColor Yellow

$session = New-CodeSession `
    -Title "Web Todo App" `
    -Mode ultrawork `
    -Agent sisyphus `
    -WorkingDir "D:\\projects\\todo-app"

# 发送 ultrawork 任务（异步，立即返回）
# ⚠️ 使用 "ulw" 魔法词（不是 "/ulw" 指令）
$task = @"
ulw

创建一个完整的待办事项 Web 应用：

前端：
- React + TypeScript
- 使用 hooks 管理状态
- 本地存储持久化数据
- 美观的 UI 界面

功能：
1. 添加待办事项
2. 标记完成/未完成
3. 删除事项
4. 筛选（全部/进行中/已完成）
5. 显示完成进度

后端（可选简单版）：
- Express.js API
- SQLite 数据库
- RESTful 接口

输出：
- 完整的项目结构
- README.md 使用说明
- package.json 依赖

保存到：D:\projects\todo-app\
"@

Send-CodeTask `
    -SessionId $session.id `
    -Task $task `
    -Agent sisyphus

Write-Host "`n✓ 任务已发送，Sisyphus 正在自动执行..." -ForegroundColor Green
Write-Host "你可以：" -ForegroundColor Gray
Write-Host "  1. 等待（监控进度）" -ForegroundColor Gray
Write-Host "  2. 离开（稍后回来查看结果）" -ForegroundColor Gray

# ===== 示例 2：监控进度 =====
Write-Host "`n2. 监控任务进度（按 Ctrl+C 停止监控）" -ForegroundColor Yellow

# 监控 10 轮，每轮 30 秒
Watch-CodeSession `
    -SessionId $session.id `
    -Interval 30 `
    -MaxIterations 10

# ===== 示例 3：等待完成 =====
Write-Host "`n3. 等待任务完成..." -ForegroundColor Yellow

$result = Wait-CodeCompletion `
    -SessionId $session.id `
    -Timeout 600 `  # 10 分钟超时
    -StabilityThreshold 60

if ($result.completed) {
    Write-Host "`n✓ 任务已完成！共 $($result.messageCount) 条消息" -ForegroundColor Green
} else {
    Write-Host "`n⏱ 任务仍在进行中（已超时）" -ForegroundColor Yellow
}

# ===== 示例 4：查看最终结果 =====
Write-Host "`n4. 查看最终结果" -ForegroundColor Yellow

$messages = Get-CodeMessages -SessionId $session.id -Last 3
foreach ($msg in $messages) {
    if ($msg.parts) {
        Write-Host "`n[$($msg.role)]: $($msg.parts[0].text.Substring(0, [Math]::Min(200, $msg.parts[0].text.Length)))"
    }
}

# ===== 清理 =====
Write-Host "`n5. 是否删除会话？ (y/n)" -ForegroundColor Yellow
$confirm = Read-Host
if ($confirm -eq "y") {
    Remove-CodeSession -SessionId $session.id
}

Write-Host "`n=== 演示完成 ===" -ForegroundColor Cyan
