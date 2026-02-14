# OpenCode Coding - MCP 工具集成示例
# 展示如何启用和使用 MCP 工具

Import-Module .\opencode_coding.ps1

Write-Host "=== MCP 工具集成示例 ===" -ForegroundColor Cyan

# ===== 查看可用 MCP 工具 =====
Write-Host "`n1. 查看可用 MCP 工具" -ForegroundColor Yellow

$mcps = Get-CodeMcpList
foreach ($mcp in $mcps) {
    $status = if ($mcp.enabled) { "✓ 已启用" } else { "○ 未启用" }
    Write-Host "  $($mcp.name): $($mcp.description) [$status]"
}

# ===== 启用 MCP 工具 =====
Write-Host "`n2. 启用 Git 和 Playwright MCP" -ForegroundColor Yellow

Enable-CodeMcp -Tools @("git-master", "playwright")

# ===== 使用 git-master 的示例 =====
Write-Host "`n3. 使用 git-master 进行自动化提交" -ForegroundColor Yellow

$session = New-CodeSession `
    -Title "Git 自动化" `
    -Mode ultrawork `
    -Agent sisyphus `
    -WorkingDir "D:\\projects\\my-app"

Send-CodeTask `
    -SessionId $session.id `
    -Task @"
完成以下 Git 工作流：

1. 检查当前 Git 状态
2. 如果有未提交更改：
   - 创建新分支 'feature/new-feature'
   - 添加所有更改
   - 提交信息："feat: add new feature"
3. 推送到远程
4. 返回主分支

使用 git-master MCP 工具完成。
"@

Wait-CodeCompletion -SessionId $session.id -Timeout 180
Remove-CodeSession -SessionId $session.id

# ===== 使用 playwright 的示例 =====
Write-Host "`n4. 使用 Playwright 进行 E2E 测试" -ForegroundColor Yellow

$testSession = New-CodeSession `
    -Title "E2E 测试" `
    -Mode ultrawork `
    -Agent sisyphus `
    -WorkingDir "D:\\projects\\my-app"

Send-CodeTask `
    -SessionId $testSession.id `
    -Task @"
使用 Playwright 创建 E2E 测试：

1. 访问 http://localhost:3000
2. 测试登录流程：
   - 输入用户名/密码
   - 点击登录按钮
   - 验证登录成功
3. 测试核心功能：
   - 创建待办事项
   - 标记完成
   - 删除事项
4. 截图保存测试结果
5. 生成测试报告

保存测试文件到 tests/e2e/
"@

Wait-CodeCompletion -SessionId $testSession.id -Timeout 300
Remove-CodeSession -SessionId $testSession.id

Write-Host "`n=== MCP 集成示例完成 ===" -ForegroundColor Cyan
