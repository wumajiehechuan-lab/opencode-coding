# OpenCode Coding - 基础用法示例
# 本示例展示如何使用常规模式进行多轮对话编程

# 导入模块
Import-Module .\opencode_coding.ps1

Write-Host "=== OpenCode Coding - 基础用法示例 ===" -ForegroundColor Cyan

# ===== 示例 1：创建会话 =====
Write-Host "`n1. 创建常规模式会话" -ForegroundColor Yellow

$session = New-CodeSession `
    -Title "Python计算器" `
    -Mode normal `
    -Agent sisyphus `
    -WorkingDir "D:\\projects\\calculator"

Write-Host "会话 ID: $($session.id)" -ForegroundColor Green
Write-Host "工作目录: $($session.directory)" -ForegroundColor Gray

# ===== 示例 2：第一轮对话 - 描述需求 =====
Write-Host "`n2. 第一轮：描述需求" -ForegroundColor Yellow

$response = Send-CodeMessage `
    -SessionId $session.id `
    -Message @"
创建一个 Python 计算器应用，要求：
1. 支持加减乘除四则运算
2. 命令行交互界面
3. 输入 exit 退出
4. 处理除零错误

保存到当前目录。
"@

Write-Host "Agent 响应已接收" -ForegroundColor Green

# ===== 示例 3：第二轮对话 - 要求改进 =====
Write-Host "`n3. 第二轮：添加功能" -ForegroundColor Yellow

$response = Send-CodeMessage `
    -SessionId $session.id `
    -Message "请添加计算历史记录功能，保存到 history.txt"

# ===== 示例 4：第三轮对话 - 验证 =====
Write-Host "`n4. 第三轮：运行测试" -ForegroundColor Yellow

$response = Send-CodeMessage `
    -SessionId $session.id `
    -Message "运行程序验证功能是否正常，并显示测试结果"

# ===== 示例 5：查看消息历史 =====
Write-Host "`n5. 查看消息历史" -ForegroundColor Yellow

$messages = Get-CodeMessages -SessionId $session.id -Last 5
Write-Host "共有 $($messages.Count) 条消息"

# ===== 示例 6：删除会话 =====
Write-Host "`n6. 清理：删除会话" -ForegroundColor Yellow

Remove-CodeSession -SessionId $session.id

Write-Host "`n=== 示例完成 ===" -ForegroundColor Cyan
