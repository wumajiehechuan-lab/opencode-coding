---
name: opencode-coding
description: "使用 oh-my-opencode 插件进行 AI 编程。支持常规多轮对话模式和 ultrawork 全自动模式，集成 MCP 工具，提供 Sisyphus/Librarian/Explore/Oracle 多 Agent 协作。"
homepage: https://github.com/wumajiehechuan-lab/opencode-coding
metadata:
  emoji: "🧑‍💻"
  requires:
    bins: ["opencode"]
---

# OpenCode Coding - AI 编程助手

使用 [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) 插件进行智能化编程，支持多 Agent 协作和两种工作模式。

## 什么是 oh-my-opencode？

oh-my-opencode 是 OpenCode 的 Agent 编排框架，核心特性：

- **Sisyphus 主代理**：智能任务分解与执行
- **专业子代理**：Librarian（代码搜索）、Explore（代码探索）、Oracle（问题诊断）
- **ultrawork 模式**：全自动执行直到任务完成
- **MCP 工具集成**：Git、浏览器、文档等扩展能力

## 架构概览

```
┌─────────────────────────────────────────┐
│           OpenCode (核心)                │
│         HTTP API + CLI 接口              │
└─────────────────┬───────────────────────┘
                  │ 插件扩展
                  ▼
┌─────────────────────────────────────────┐
│         oh-my-opencode                   │
│                                          │
│  ┌─────────────────────────────────┐    │
│  │      Sisyphus (主代理)           │    │
│  │  - 任务规划 (Prometheus)         │    │
│  │  - 自主执行                       │    │
│  │  - 错误恢复                       │    │
│  └──────────────┬──────────────────┘    │
│                 │ 委派                   │
│  ┌──────────────┼──────────────┐        │
│  │ Librarian    │ Explore      │ Oracle │
│  │ 代码搜索      │ 代码导航      │ 诊断   │
│  └──────────────┴──────────────┘        │
└─────────────────────────────────────────┘
```

## oh-my-opencode 命令

### 核心指令

| 指令 | 功能 | 使用场景 | API 支持 |
|------|------|----------|----------|
| `ulw` / `ultrawork` | **魔法词**，激活全自动模式 | 明确需求，放手让 AI 完成 | ✅ 支持 |
| `/start-work` | 执行 Prometheus 制定的计划 | 计划模式 → 执行 | ❌ TUI 专用 |
| `/refactor` | 智能重构（LSP + AST + TDD） | 代码重构 | ❌ TUI 专用 |
| `/ulw-loop` | 启动 ultrawork 循环 | 持续迭代 | ❌ TUI 专用 |
| `/cancel-ralph` | 取消 Ralph 循环 | 中断自动执行 | ❌ TUI 专用 |

**⚠️ 重要区分**：
- **魔法词**（`ulw`, `ultrawork`）：在提示中包含即可，**API 和 TUI 都支持**
- **斜杠指令**（`/start-work`, `/refactor`）：仅 TUI 交互模式支持，**API 模式下无效**

### 使用决策树

```
任务是否明确？
├─ YES → 使用 "ulw" 魔法词让 Agent 自动完成
└─ NO → 是否需要精确、可验证的执行？
    ├─ YES → 使用 @plan 制定计划，然后 /start-work（TUI）
    └─ NO → 直接使用 "ulw" 魔法词
```

### ultrawork 魔法词用法

只需在提示中包含 `ultrawork` 或 `ulw` 单词即可激活：

**✅ 正确用法**：
```
ulw 创建一个 Python GUI 截图工具
```

```
ultrawork 实现一个完整的用户认证系统
```

```
使用 ulw 模式重构这段代码
```

**❌ 错误用法**（API 模式下无效）：
```
/ulw 创建一个 Python GUI 截图工具  ← 不要加 /
```

## 两种工作模式

### 1. 常规模式（多轮对话）

**特点**：
- 逐步交互，每步可控
- 适合探索性任务
- 可随时调整方向

**使用场景**：
- 需求不明确的开发
- 需要逐步确认的重构
- 学习和探索代码库

### 2. ultrawork 模式（全自动）

**特点**：
- 一句指令，自动完成
- Sisyphus 自主规划执行
- 仅在失败时通知

**使用场景**：
- 明确的编程任务
- 标准化代码生成
- 批量处理

**核心理念**：
```
Human Intent → Agent Execution → Verified Result
     ↑_________________________________↓
     └────── 最小人工干预 ──────────────┘
```

## OpenCode 基础使用

### 核心概念

**计划模式 vs 构建模式**：
- 按 `Tab` 键在两种模式间切换
- **计划模式**（右下角指示器）：只规划不执行，适合复杂任务先制定方案
- **构建模式**：直接执行代码更改

**常用命令**：
| 命令 | 功能 |
|------|------|
| `/init` | 初始化项目，创建 AGENTS.md |
| `/connect` | 连接 LLM 提供商 |
| `/undo` | 撤销上次更改 |
| `@文件路径` | 引用特定文件 |

### 项目理解（AGENTS.md）

OpenCode 通过 `AGENTS.md` 文件理解项目：
- 运行 `/init` 自动生成
- 包含项目结构、编码规范、架构决策
- 支持子目录中的 `AGENTS.md`（OpenCode 1.1.37+）

**AGENTS.md 示例结构**：
```markdown
# 项目概述
- 技术栈: React + TypeScript + Node.js
- 架构: 微前端 + monorepo

# 编码规范
- 使用函数组件 + hooks
- 类型定义放在 types/ 目录
- API 调用使用 services/api.ts

# 重要文件
- packages/web/: 前端主应用
- packages/api/: 后端 API
```

### 工作流程

1. **初始化项目**
   ```bash
   cd /path/to/project
   opencode
   /init  # 分析项目结构，创建 AGENTS.md
   ```

2. **提问**（探索代码库）
   ```
   How is authentication handled in @packages/functions/src/api/index.ts
   ```

3. **添加功能**（建议先规划）
   - 按 `Tab` 切换到**计划模式**
   - 描述功能需求
   - 审查并迭代计划
   - 按 `Tab` 切回**构建模式**
   - 执行：`Sounds good! Go ahead and make the changes.`

4. **撤销更改**
   ```
   /undo
   ```

## 安装配置

### 1. 安装 OpenCode

```bash
# Windows
irm https://opencode.ai/install.ps1 | iex

# macOS/Linux
curl -fsSL https://opencode.ai/install | bash
```

### 2. 安装 oh-my-opencode 插件

```bash
# 进入 OpenCode 配置目录
cd ~/.config/opencode

# 安装插件
bun add oh-my-opencode
# 或
npm install oh-my-opencode
```

### 3. 配置插件

编辑 `~/.config/opencode/opencode.json`：

```json
{
  "plugin": ["oh-my-opencode"]
}
```

### 4. 配置 Agent（可选）

创建 `~/.config/opencode/oh-my-opencode.json`：

```json
{
  "agents": {
    "planner-sisyphus": {
      "enabled": true,
      "replace_plan": true
    },
    "librarian": {
      "enabled": true
    },
    "explore": {
      "enabled": true
    },
    "oracle": {
      "enabled": true
    }
  },
  "mcps": [
    { "name": "git-master", "enabled": true }
  ]
}
```

## 快速开始

### PowerShell 使用

```powershell
# 导入模块
Import-Module .\opencode_coding.ps1

# ===== 常规模式 =====
# 创建会话（多轮对话）
$session = New-CodeSession -Title "Fix Bug" -Mode normal

# 第一轮对话
$response = Send-CodeMessage -SessionId $session.id `
    -Message "修复 login.py 中的 SQL 注入漏洞" `
    -Agent sisyphus

# 基于结果追问
Send-CodeMessage -SessionId $session.id `
    -Message "请添加输入验证和单元测试"

# ===== ultrawork 模式 =====
# 全自动执行
$session = New-CodeSession -Title "Create App" -Mode ultrawork

Send-CodeTask -SessionId $session.id `
    -Task "创建 Python GUI 截图工具，支持全屏/区域截图和系统托盘" `
    -Agent sisyphus

# 等待完成（可选）
Wait-CodeCompletion -SessionId $session.id -Timeout 300
```

### Python 使用

```python
from opencode_coding import OpenCodeCoding

# 初始化
coder = OpenCodeCoding(working_dir="D:\\projects")

# 常规模式 - 多轮对话
session = coder.create_session(title="Refactor Code", mode="normal")

response = session.send_message(
    message="将 utils.py 重构为类结构",
    agent="sisyphus"
)

# ultrawork 模式 - 全自动
session = coder.create_session(title="Create API", mode="ultrawork")

session.send_task(
    task="创建 Flask REST API，包含用户认证和 CRUD 操作",
    agent="sisyphus",
    auto_execute=True
)
```

## Agent 选择指南

| Agent | 职责 | 使用场景 | 推荐模式 |
|-------|------|----------|----------|
| **sisyphus** | 主代理 | 编写新代码、重构、复杂任务 | ultrawork |
| **librarian** | 代码搜索 | 理解项目结构、找代码 | normal |
| **explore** | 代码导航 | 探索大型代码库 | normal |
| **oracle** | 问题诊断 | 调试、错误分析 | normal |

## 工作流示例

### 示例 1：创建新应用（ultrawork）

```powershell
$session = New-CodeSession -Title "Todo App" -Mode ultrawork

# 使用 ulw 魔法词激活 ultrawork 模式
# ⚠️ 注意：是 "ulw" 不是 "/ulw"（后者是 TUI 指令，API 模式下无效）
Send-CodeTask -SessionId $session.id -Task @"
ulw

创建一个 React + Node.js 待办事项应用：
1. 前端：React hooks，本地存储
2. 后端：Express API，SQLite 数据库
3. 功能：增删改查、标记完成、筛选
4. 样式：简洁美观，响应式设计

保存到 D:\projects\todo-app\
"@

# 等待自动完成
Watch-CodeSession -SessionId $session.id
```

### 示例 2：代码重构（常规模式）

```powershell
$session = New-CodeSession -Title "Refactor" -Mode normal

# 第一轮：分析
Send-CodeMessage -SessionId $session.id `
    -Message "分析 D:\\project\\legacy.py 的代码结构" `
    -Agent explore

# 第二轮：制定计划
Send-CodeMessage -SessionId $session.id `
    -Message "制定重构计划，将函数改为类" `
    -Agent sisyphus

# 第三轮：执行重构
Send-CodeMessage -SessionId $session.id `
    -Message "执行重构，并添加类型提示" `
    -Agent sisyphus

# 第四轮：验证
Send-CodeMessage -SessionId $session.id `
    -Message "运行测试验证重构没有破坏功能" `
    -Agent oracle
```

### 示例 3：Bug 诊断（常规模式）

```powershell
$session = New-CodeSession -Title "Debug" -Mode normal

Send-CodeMessage -SessionId $session.id -Message @"
分析以下错误并修复：
错误信息：TypeError: 'NoneType' object is not callable
文件：app.py:42
相关代码：result = process_data(data)
"@ -Agent oracle
```

## MCP 工具使用

### 启用 MCP 工具

```powershell
# 启用 Git 工具
Enable-CodeMcp -Tools @("git-master")

# 启用多个工具
Enable-CodeMcp -Tools @("git-master", "playwright", "context7")
```

### 常用 MCP 工具

| 工具 | 功能 | 使用场景 |
|------|------|----------|
| **git-master** | Git 操作 | 自动提交、分支管理 |
| **playwright** | 浏览器自动化 | E2E 测试、截图 |
| **context7** | 文档检索 | 查 API 文档、最佳实践 |

## Hooks（自动化钩子）

oh-my-opencode 提供 Hooks 机制，在特定事件发生时自动执行操作。

### 推荐的 Hooks 配置

已在 `config/oh-my-opencode.json` 中启用：

```json
{
  "hooks": {
    "background-notification": {
      "enabled": true,
      "notify_on_completion": true,
      "notify_on_failure": true
    },
    "session-recovery": {
      "enabled": true,
      "auto_resume": true
    },
    "context-window-monitor": {
      "enabled": true,
      "warning_threshold": 0.8
    },
    "todo-continuation-enforcer": {
      "enabled": true
    }
  }
}
```

### Hooks 说明

| Hook | 功能 | 解决的问题 |
|------|------|-----------|
| **background-notification** | 后台任务完成/失败时发送通知 | ✅ 任务完成及时通知，避免长时间等待 |
| **session-recovery** | 会话中断后自动恢复 | ✅ 网络中断或进程崩溃后可恢复 |
| **context-window-monitor** | 监控上下文窗口使用率 | ⚠️ 防止 token 溢出 |
| **todo-continuation-enforcer** | 确保待办事项被执行 | ⚠️ 防止任务遗漏 |

**重要**：这些 hooks 在 OpenCode 内部运行，无需外部程序干预。

## API 参考

### 会话管理

```powershell
# 创建会话
New-CodeSession [-Title] <string> [-Mode] <normal|ultrawork> [-Agent] <string>

# 获取会话信息
Get-CodeSession [-SessionId] <string>

# 列出所有会话
Get-CodeSessionList

# 删除会话
Remove-CodeSession [-SessionId] <string>
```

### 消息发送

```powershell
# 常规模式（同步，等待响应）
Send-CodeMessage [-SessionId] <string> [-Message] <string> [-Agent] <string>

# ultrawork 模式（异步，后台执行）
Send-CodeTask [-SessionId] <string> [-Task] <string> [-Agent] <string>
```

### 会话监控

```powershell
# 获取会话消息历史
Get-CodeMessages [-SessionId] <string>

# 监控会话状态（轮询）
Watch-CodeSession [-SessionId] <string> [-Interval] <int>

# 等待任务完成
Wait-CodeCompletion [-SessionId] <string> [-Timeout] <int>
```

### MCP 工具

```powershell
# 启用 MCP 工具
Enable-CodeMcp [-Tools] <string[]>

# 获取可用 MCP 列表
Get-CodeMcpList
```

### CLI 模式（推荐）

**⚠️ 重要更新（2026-02-16）**：

经过实际测试，发现以下问题：
- **CLI 模式** (`opencode run`)：存在内部 bug（`titlecase` 函数错误），**暂时不可用**
- **HTTP API 模式**：返回 500 错误，但**后台任务能正常完成并生成代码**

**当前推荐方式**：HTTP API + 异步等待（忽略响应状态码）

```powershell
# 步骤 1: 发送任务（HTTP API 会返回 500，但任务已在后台启动）
try {
    Invoke-RestMethod -Uri "http://127.0.0.1:4096/api/v1/sessions" -Method POST ...
} catch {
    # 忽略 500 错误，这是正常的
    Write-Host "Task started in background (ignore 500 error)"
}

# 步骤 2: 直接等待 3-5 分钟（让 Sisyphus 在后台工作）
Write-Host "Waiting for opencode to complete..."
Start-Sleep -Seconds 180

# 步骤 3: 检查生成的文件
Get-ChildItem -Path "项目目录" -Recurse
# 成功！代码已生成
```

**为什么不能依赖 HTTP 响应？**
- OpenCode HTTP API 有 bug，返回 500 但任务实际在后台运行
- Sisyphus 继续使用 MCP 工具（filesystem_write_file 等）生成代码
- 需要等待足够时间（简单任务 2-3 分钟，复杂任务 5-10 分钟）

### CLI 模式（当前不可用）

```powershell
# 注：以下函数因 opencode 内部 bug 暂时无法使用
# Send-OpenCodeTask -Message "ultrawork ..."  # ❌ 会报错
```

**Bug 详情**（2026-02-16）：
```
TypeError: undefined is not an object (evaluating 'str3.replace')
at titlecase (src/util/locale.ts:3:12)
```

等待 opencode 官方修复后，CLI 模式将是更优选择。

## 最佳实践

### 1. 选择合适的模式

- **需求明确** → ultrawork（全自动）
- **需求模糊** → normal（逐步探索）
- **学习项目** → normal + librarian/explore

### 2. API 模式 vs TUI 模式

本 Skill 使用 **HTTP API 模式** 控制 OpenCode，与 **TUI 交互模式** 有重要区别：

| 特性 | TUI 模式 | API 模式（本 Skill） |
|------|----------|---------------------|
| `ulw` 魔法词 | ✅ `ulw 创建...` | ✅ `ulw 创建...` |
| `/ulw` 指令 | ✅ 支持 | ❌ **不支持** |
| `/start-work` | ✅ 支持 | ❌ **不支持** |
| `/refactor` | ✅ 支持 | ❌ **不支持** |
| 交互式规划 | ✅ Tab 键切换 | ❌ 不可用 |
| 图片拖放 | ✅ 支持 | ❌ 不可用 |

**关键区别**：
- **魔法词**（`ulw`, `ultrawork`）：只需在文本中包含，**API 和 TUI 都支持**
- **斜杠指令**（`/ulw`, `/start-work`）：仅 TUI 支持，**API 模式下会被当作文本**

**✅ 正确的 API 用法**：
```powershell
Send-CodeTask -Task "ulw 创建一个 Python 应用"
# 或
Send-CodeTask -Task "ultrawork 实现用户认证系统"
```

**❌ 错误的 API 用法**：
```powershell
Send-CodeTask -Task "/ulw 创建一个 Python应用"  # / 前缀无效！
```

### 2. 编写清晰的任务描述

```powershell
# ❌ 不好的描述
"修复 bug"

# ✅ 好的描述
"修复 login.py 第 42 行的 TypeError：
- 错误：'NoneType' object is not callable
- 上下文：用户登录时传入 null 值
- 期望：添加 null 检查并返回 400 错误"
```

### 3. ultrawork 任务结构

```
任务目标：[清晰描述]
功能要求：
1. [具体功能 1]
2. [具体功能 2]
技术栈：[指定技术]
输出位置：[明确路径]
```

### 4. 错误处理

```powershell
try {
    $result = Send-CodeMessage -SessionId $session.id -Message "修复代码"
} catch {
    Write-Host "错误：$_" -ForegroundColor Red
    
    # 查看详细日志
    Get-CodeMessages -SessionId $session.id -Last 5
}
```

### 5. 利用 Hooks 减少等待时间

配置文件中已启用 `background-notification` 和 `session-recovery` hooks：

**效果**：
- ✅ 任务完成时自动通知（无需一直轮询）
- ✅ 会话中断后自动恢复
- ✅ 上下文溢出前预警

**建议**：即使启用了 hooks，仍建议设置合理的超时时间：
```powershell
# 等待任务完成，但最多等 10 分钟
Wait-CodeCompletion -SessionId $session.id -Timeout 600
```

## 故障排除

### 问题 1：OpenCode 服务器无法启动

```powershell
# 检查端口占用
Get-NetTCPConnection -LocalPort 4096

# 检查 OpenCode 安装
opencode --version

# 手动启动服务器
opencode serve --port 4096 --hostname 127.0.0.1
```

### 问题 2：API 返回 500 错误

- 检查 oh-my-opencode 插件是否正确安装
- 查看 OpenCode 日志：`opencode debug`
- 尝试重启服务器

### 问题 3：ultrawork 任务卡住

```powershell
# 检查会话状态
Get-CodeSession -SessionId $session.id

# 查看最新消息
Get-CodeMessages -SessionId $session.id -Last 10

# 必要时取消任务
Stop-CodeTask -SessionId $session.id
```

## 配置模板

### 完整配置示例

```json
{
  "agents": {
    "planner-sisyphus": {
      "enabled": true,
      "replace_plan": true,
      "model": "claude-sonnet-4"
    },
    "librarian": {
      "enabled": true,
      "model": "claude-haiku-3"
    },
    "explore": {
      "enabled": true
    },
    "oracle": {
      "enabled": true
    }
  },
  "mcps": [
    {
      "name": "git-master",
      "enabled": true,
      "config": {
        "auto_commit": true
      }
    },
    {
      "name": "playwright",
      "enabled": false
    }
  ],
  "settings": {
    "ultrawork_auto_confirm": true,
    "notification_on_complete": true
  }
}
```

## 参考链接

- [OpenCode 官网](https://opencode.ai)
- [oh-my-opencode GitHub](https://github.com/code-yeongyu/oh-my-opencode)
- [oh-my-opencode 文档](https://ohmyopencode.com)
- [MCP 工具列表](https://github.com/code-yeongyu/oh-my-opencode#mcps)

## 更新日志

### v2.1.0 (2026-02-16)
- ✨ **新增 CLI 模式函数**（因 opencode bug 暂时不可用）：
  - `Send-OpenCodeTask` - 同步 CLI 执行
  - `Send-OpenCodeTaskAsync` - 异步后台执行
  - `Get-OpenCodeTaskResult` - 获取异步结果
- 📚 **重要更新**：发现 HTTP API 实际可用（返回 500 但后台成功）
- 📚 **重要更新**：CLI 模式存在内部 bug（`titlecase` 错误），暂时禁用
- 📚 更新文档，说明当前正确的使用方式
- 🔧 更新使用建议：HTTP API + 异步等待

### v2.0.1 (2026-02-14)
- ✨ 启用关键 Hooks：background-notification、session-recovery
- ✨ 解决任务完成通知延迟问题
- 📚 添加 Hooks 使用说明
- 📚 修正 ulw 魔法词使用方式（不是 /ulw 指令）

### v2.0.0 (2026-02-14)
- ✨ 完全重写，专注 oh-my-opencode 集成
- ✨ 支持常规模式和 ultrawork 模式
- ✨ 支持多 Agent 选择（sisyphus/librarian/explore/oracle）
- ✨ 支持 MCP 工具
- 🔧 修复 API 端点错误
- 📚 完善文档和示例

---

**提示**：本 Skill 需要正确安装 OpenCode 和 oh-my-opencode 插件才能使用。推荐使用提供的配置模板（已启用最佳 hooks 设置）。
