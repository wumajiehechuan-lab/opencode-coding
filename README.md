# opencode-coding

使用 oh-my-opencode 插件进行 AI 编程的 OpenClaw Skill。

## 特性

- ✅ **双模式支持**：常规对话模式 + ultrawork 全自动模式
- ✅ **多 Agent 协作**：Sisyphus / Librarian / Explore / Oracle
- ✅ **MCP 工具集成**：Git、浏览器自动化等
- ✅ **Hooks 自动化**：background-notification、session-recovery 等
- ✅ **修复 API**：使用正确的端点和请求格式
- ✅ **完整示例**：涵盖各种使用场景

## 安装

1. 安装 OpenCode：
   ```powershell
   irm https://opencode.ai/install.ps1 | iex
   ```

2. 安装 oh-my-opencode 插件：
   ```bash
   cd ~/.config/opencode
   bun add oh-my-opencode
   ```

3. 配置 OpenCode 插件：
   ```bash
   # 编辑 ~/.config/opencode/opencode.json
   {
     "plugin": ["oh-my-opencode"]
   }
   ```

4. 复制本仓库的配置：
   ```bash
   cp config/oh-my-opencode.json ~/.config/opencode/
   ```

5. 使用本 Skill：
   ```powershell
   # 将 skill 复制到 OpenClaw skills 目录
   cp -r opencode-coding ~/.openclaw/workspace/skills/
   ```

## 快速开始

```powershell
Import-Module .\opencode_coding.ps1

# Ultrawork 模式（全自动）
$session = New-CodeSession -Title "Create App" -Mode ultrawork
Send-CodeTask -SessionId $session.id -Task "创建一个 Python GUI 应用"

# 常规模式（多轮对话）
$session = New-CodeSession -Title "Fix Bug" -Mode normal
Send-CodeMessage -SessionId $session.id -Message "修复登录bug"
```

### ⚠️ 重要提示：ulw 魔法词

- **正确**：`Send-CodeTask -Task "ulw 创建应用"` 或 `Send-CodeTask -Task "创建应用"`（自动添加）
- **错误**：`Send-CodeTask -Task "/ulw 创建应用"`（`/ulw` 是 TUI 指令，API 模式下无效）

## 文档

- `SKILL.md` - 完整使用文档
- `examples/` - 示例脚本
- `config/` - 配置模板（含最优 hooks 设置）

## Hooks 配置

本 Skill 推荐启用以下 hooks（已包含在配置模板中）：

| Hook | 功能 |
|------|------|
| **background-notification** | 任务完成/失败时自动通知 |
| **session-recovery** | 会话中断后自动恢复 |
| **context-window-monitor** | 监控上下文窗口使用率 |
| **todo-continuation-enforcer** | 确保待办事项被执行 |

## 示例

### Ultrawork 全自动模式

```powershell
$session = New-CodeSession -Title "Todo App" -Mode ultrawork

Send-CodeTask -SessionId $session.id -Task @"
ulw

创建一个 React + Node.js 待办事项应用：
1. 前端：React hooks，本地存储
2. 后端：Express API，SQLite 数据库
3. 功能：增删改查、标记完成、筛选

保存到 D:\projects\todo-app\
"@

# 等待完成
Wait-CodeCompletion -SessionId $session.id -Timeout 600
```

### 常规多轮对话模式

```powershell
$session = New-CodeSession -Title "Refactor" -Mode normal

# 第一轮：分析
Send-CodeMessage -SessionId $session.id `
    -Message "分析代码结构" -Agent explore

# 第二轮：重构
Send-CodeMessage -SessionId $session.id `
    -Message "执行重构" -Agent sisyphus

# 第三轮：验证
Send-CodeMessage -SessionId $session.id `
    -Message "运行测试验证" -Agent oracle
```

## 与原 Skill 的区别

| 原 opencode-controller | opencode-coding (本仓库) |
|------------------------|--------------------------|
| 简单的 API 包装器 | 专注 oh-my-opencode 集成 |
| 单一模式 | 支持 normal + ultrawork |
| API 端点错误 | 修复为正确端点 |
| 无 Agent 选择 | 支持多 Agent |
| 无 MCP 支持 | 支持 MCP 工具 |
| 无 Hooks | 启用关键 Hooks |

## 许可证

MIT

## 相关链接

- [OpenCode](https://opencode.ai)
- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)
- [OpenClaw](https://openclaw.ai)
