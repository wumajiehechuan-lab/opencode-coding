# OpenCode Coding - 多 Agent 协作示例
# 展示如何根据不同的任务选择合适的 Agent

Import-Module .\opencode_coding.ps1

Write-Host "=== 多 Agent 协作示例 ===" -ForegroundColor Cyan

$workingDir = "D:\\projects\\multi-agent-demo"

# ===== 步骤 1：Explore Agent - 探索代码库 =====
Write-Host "`n1. [Explore] 探索项目结构" -ForegroundColor Yellow

$exploreSession = New-CodeSession `
    -Title "探索项目" `
    -Mode normal `
    -Agent explore `
    -WorkingDir $workingDir

Send-CodeMessage `
    -SessionId $exploreSession.id `
    -Message "分析这个项目的代码结构，找出主要模块和它们的关系" `
    -Agent explore

Remove-CodeSession -SessionId $exploreSession.id

# ===== 步骤 2：Librarian Agent - 搜索代码 =====
Write-Host "`n2. [Librarian] 搜索特定代码" -ForegroundColor Yellow

$libSession = New-CodeSession `
    -Title "搜索代码" `
    -Mode normal `
    -Agent librarian `
    -WorkingDir $workingDir

Send-CodeMessage `
    -SessionId $libSession.id `
    -Message "找出项目中所有处理用户认证的代码，包括登录、注册、密码验证" `
    -Agent librarian

Remove-CodeSession -SessionId $libSession.id

# ===== 步骤 3：Oracle Agent - 诊断问题 =====
Write-Host "`n3. [Oracle] 诊断 Bug" -ForegroundColor Yellow

$oracleSession = New-CodeSession `
    -Title "诊断问题" `
    -Mode normal `
    -Agent oracle `
    -WorkingDir $workingDir

Send-CodeMessage `
    -SessionId $oracleSession.id `
    -Message @"
分析以下错误并提供修复方案：

错误信息：
TypeError: Cannot read property 'name' of undefined
    at User.getProfile (user.js:42)
    at router.get (/api/users/:id)

上下文：
- 发生在获取用户资料时
- 某些用户会出现，不是所有用户
- 数据库中这些用户存在

请诊断根本原因并提供修复代码。
"@

Remove-CodeSession -SessionId $oracleSession.id

# ===== 步骤 4：Sisyphus Agent - 执行重构 =====
Write-Host "`n4. [Sisyphus] 执行重构（ultrawork 模式）" -ForegroundColor Yellow

$sisyphusSession = New-CodeSession `
    -Title "重构代码" `
    -Mode ultrawork `
    -Agent sisyphus `
    -WorkingDir $workingDir

Send-CodeTask `
    -SessionId $sisyphusSession.id `
    -Task @"
基于之前的分析，重构用户认证模块：

1. 修复 null 引用错误
2. 添加输入验证
3. 改进错误处理
4. 添加单元测试
5. 更新相关文档

确保所有现有功能正常工作。
"@

# 等待完成
Wait-CodeCompletion -SessionId $sisyphusSession.id -Timeout 300

Remove-CodeSession -SessionId $sisyphusSession.id

Write-Host "`n=== 多 Agent 协作完成 ===" -ForegroundColor Cyan
Write-Host "每个 Agent 各司其职，完成复杂任务" -ForegroundColor Gray
