# Feishu Smart Session Reset

当 Feishu `smart` agent 出现以下症状时，可优先执行重置：

- `file lock stale for ...jsonl`
- `Something went wrong while processing your request`
- 会话长时间 `running` 但没有最终回复
- 刚超时/过载后，新消息继续复用坏会话

## 处理动作

运行：

```sh
/Users/you/.openclaw/workspace-smart/reset_feishu_smart_session.sh
```

脚本会做三件事：

1. 备份 `/Users/you/.openclaw/agents/smart/sessions/sessions.json`
2. 把 `smart` 当前会话映射重置为 `{}`，强制下一条 Feishu 消息开新会话
3. 重启 `openclaw gateway`

## 说明

- 不删除历史 `.jsonl` 会话日志
- 只重置 `smart` 的活动会话映射
- 如果上游是 `request timed out` 或 `server overloaded`，这只能清理后遗症，不能解决上游服务波动
