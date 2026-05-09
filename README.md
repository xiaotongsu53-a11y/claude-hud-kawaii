# claude-hud-kawaii

给 [claude-hud](https://github.com/jarrodwatts/claude-hud) 加 emoji 装饰 + 把 Context / Usage / Weekly 拆成独立行的小补丁包。

## 效果

```
╭─ [ Opus 4.7 ] ◕ [ xhigh ] on [ data-pipeline ] git:main* [ 12m ] ──╮
│ ▸ Context ██░░░░░░░░ 13%  (resets in 3h 31m)                       │
│ ⚡ Usage   █░░░░░░░░░  2%  (resets in 3h 31m)                       │
│ ◷ Weekly  ░░░░░░░░░░  0%  (resets in 6d 23h)                       │
╰────────────────────────────────────────────────────────────────────╯
```

## 改动内容

三个 patch + 一个 config：

1. `src/render/lines/usage.ts` — 把 `Usage | Weekly` 改成 `Usage\nWeekly`，让两个用量窗口分行显示
2. `src/i18n/en.ts` — 给 Context / Usage / Weekly 标签加图标（▸ ⚡ ◷）
3. `src/render/index.ts` — 加外框 + 重排头部为 `[ model ] ◕ [ effort ] on [ project ] git:branch* [ duration ]`

配套的 `config.json`：
- `display.mergeGroups: []` — 不再把 `context` 和 `usage` 合并到同一行
- `display.showEffortLevel: true` — 在头部显示推理等级（low / medium / high / xhigh / max）

## 限制

- 底部 `▶▶ bypass permissions` 那行是 Claude Code 主程序画的，**不归 claude-hud 管**，所以框只包住 HUD 自己的 4 行。
- 终端宽度小于 30 列时自动跳过外框，避免折行错乱。

## 安装

前提：已经通过 `/plugin install claude-hud` 装好了官方插件。

一行命令搞定：

```bash
curl -fsSL https://raw.githubusercontent.com/xiaotongsu53-a11y/claude-hud-kawaii/main/install.sh | bash
```

脚本会自动：
1. 找到 `~/.claude/plugins/cache/*/claude-hud/<version>/` 下最新版本
2. 应用 emoji 标签 + Usage/Weekly 拆行的 patch
3. 把 `config.json` 写到 `~/.claude/plugins/claude-hud/config.json`

statusLine 立即生效，无需重启 Claude Code。

> 想看脚本内容再决定要不要跑：[install.sh](./install.sh)

## 注意事项

- 补丁打在插件 cache 目录（`~/.claude/plugins/cache/.../claude-hud/<version>/src/`），**插件升级到新版本后会被覆盖**，需要重新跑一次 `install.sh`。
- 如果上游修改了 `usage.ts` 或 `en.ts` 的相关行，patch 会失败，需要手动适配。
- 推理等级（effort level）显示需要 Claude Code ≥ 2.1.115 通过 stdin 传 `effort.level`，或父进程带 `--effort` 参数。

## 卸载

```bash
cd claude-hud-kawaii
for p in patches/*.patch; do
  patch -d "$(ls -d ~/.claude/plugins/cache/*/claude-hud/*/ | sort -V | tail -1)" -p1 -R < "$p"
done
rm ~/.claude/plugins/claude-hud/config.json
```

## 致谢

基于 [jarrodwatts/claude-hud](https://github.com/jarrodwatts/claude-hud)。
