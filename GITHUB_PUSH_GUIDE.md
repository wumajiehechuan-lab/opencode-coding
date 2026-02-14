# GitHub 推送指南

由于当前环境限制，请手动执行以下步骤将代码推送到 GitHub：

## 步骤 1：在 GitHub 上创建仓库

1. 访问 https://github.com/new
2. 填写仓库信息：
   - **Repository name**: `opencode-coding`
   - **Description**: `OpenClaw Skill for AI programming with oh-my-opencode plugin`
   - **Visibility**: Public
   - **Initialize**: 不要勾选（我们已有本地仓库）
3. 点击 "Create repository"

## 步骤 2：推送本地代码

在本地打开 PowerShell，执行：

```powershell
cd C:\Users\admin\.openclaw\workspace\skills\opencode-coding

# 添加远程仓库（将 YOUR_USERNAME 替换为你的 GitHub 用户名）
git remote add origin https://github.com/YOUR_USERNAME/opencode-coding.git

# 推送代码
git push -u origin master
```

## 步骤 3：验证

访问 `https://github.com/YOUR_USERNAME/opencode-coding` 确认代码已上传。

## 仓库内容

推送后，GitHub 仓库将包含：

```
opencode-coding/
├── LICENSE                           # MIT 许可证
├── README.md                         # 项目说明
├── SKILL.md                          # 完整文档
├── config/
│   ├── oh-my-opencode.json          # 推荐配置（含 hooks）
│   └── opencode.json                # OpenCode 配置
├── examples/
│   ├── basic-usage.ps1              # 基础用法示例
│   ├── ultrawork-demo.ps1           # Ultrawork 模式演示
│   ├── multi-agent-demo.ps1         # 多 Agent 协作示例
│   └── mcp-integration.ps1          # MCP 工具集成示例
├── opencode_coding.ps1              # PowerShell 控制器
└── opencode_coding.py               # Python 控制器
```

## 建议的仓库设置

推送后，建议在 GitHub 上：

1. **添加 topics**: `openclaw`, `opencode`, `oh-my-opencode`, `ai-programming`, `skill`
2. **启用 Issues**: 用于用户反馈
3. **添加 README 徽章**: 可以添加 OpenClaw 和 OpenCode 的链接徽章

## 分享 Skill

推送后，可以在以下地方分享：
- OpenClaw 社区
- ClawdHub (https://clawdhub.com)
- GitHub Discussions
