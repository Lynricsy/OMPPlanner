# OMPPlanner

为 [oh-my-pi（omp）](https://github.com/can1357/oh-my-pi) 提供的 `oracle` 子 agent：一个跑在顶级模型上的只读顾问兼总规划师，外加主 agent 侧的召唤指南 skill `consult-oracle`。

## 它做什么

| 模式 | 何时用 | 产出 |
|---|---|---|
| 规划 | 跨子系统、多会话、需要切分给并行子 agent 的大块任务 | 决策完备的执行方案，写入 `local://<slug>-plan.md`；最终消息给出路径、核心判断、步骤标题和待用户决定的问题 |
| 顾问 | 同一问题两次修复失败、证据互相矛盾、高风险的架构/安全/性能/数据决策、方案评审 | 结论与置信度、排序后的根因假设、判别性检查、可立即执行的下一步 |

oracle 只读：不改工作区，不执行命令。需要跑命令时，它把确切命令和"每种结果说明什么"交给主 agent 执行。大范围的代码搜集它会并行派发便宜的 `scout`，推理留给自己。

## 文件

| 路径 | 作用 |
|---|---|
| `agents/oracle.md` | agent 定义：frontmatter（工具、`spawns: scout`、`model: "@oracle"`、`blocking`、`read-summarize: false`）+ 系统提示词 |
| `skills/consult-oracle/SKILL.md` | 给主 agent 看：何时召唤、调用约束、简报模板、拿到回复后怎么用 |
| `install.sh` | 把上面两项软链到 `~/.omp/agent/`（遵循 `PI_CODING_AGENT_DIR`），可重复执行 |

## 安装

```bash
./install.sh
```

然后在 `~/.omp/agent/config.yml` 的 `modelRoles` 下配置 oracle 用的模型（脚本检测到缺失会提示）：

```yaml
modelRoles:
  oracle: anthropic/claude-fable-5-2:xhigh
```

换模型只改这一行，或在 `/model` 的 Roles 视图里改 `oracle` 角色；agent 文件不写死任何模型。`:xhigh` 是思考强度后缀。新开的会话会发现 agent 和 skill，已在运行的会话需要重开。

## 使用

一般不用手动操作：主 agent 从 task 工具的 agent 列表和 `consult-oracle` skill 得知何时召唤。也可以直接说"让 oracle 规划一下……"或"问问 oracle 为什么……"。

oracle 启动时看不到对话，简报质量决定回答质量。skill 要求主 agent 提供目标、现状、已尝试及报错原文、证据位置、当前假设和期望产出；长日志放进 `local://oracle-<slug>-brief.md`。

## 已知限制

- **只读只对内置工具是硬限制。** frontmatter 的 `tools` 管不到 MCP 工具和 `xd://` 设备，它们会叠加进子 agent，而子 agent 以 `yolo` 审批模式运行。提示词要求 oracle 只用搜索、读取类设备，并且优先级高于 MCP server 指令，但这仍是提示词约束。需要硬保证时，在 `config.yml` 的 `tools.approval` 里对危险工具设 `deny`，例如 `mcp__onessh_exec`、`mcp__onessh_file_write`。这会同时影响主 agent 和其他子 agent。
- **子 agent 对目录调用 `read` 会失败。** omp 18.19.0 中，任意子 agent（包括内置 `scout`）对目录路径调用 `read` 后，下一次 Anthropic 请求会带上引用 `ask` 的 `tool_removal`，然后返回 400：`tool_addition/tool_removal references unknown tool 'ask'`。已上报。提示词让 oracle 及其派出的 scout 改用 `glob` 列目录；上游修复后可删掉 `agents/oracle.md` 里的这条规则。
- **慢。** xhigh 思考下，一次咨询实测 6–10 分钟。`blocking: true` 让主 agent 等待结果。
- `lsp` 和 `ast_grep` 只在当前会话挂载时可用：`ast_grep` 默认关闭（`astGrep.enabled`），没有语言服务器时也不会有 `lsp`。

## 设计来源

调研过的同类实现，以及采纳了它们的哪些部分：

- [Amp Oracle](https://ampcode.com/news/oracle)：只读推理子 agent，负责规划、评审和调试，主 agent 负责执行。采纳了这套职责划分，以及"什么时候不该用 oracle"的写法。
- [oh-my-openagent `oracle.ts`](https://github.com/code-yeongyu/oh-my-openagent/blob/dev/packages/omo-opencode/src/agents/oracle.ts)：采纳了"务实最简"决策框架、单一主推荐、置信度标注、范围纪律、高风险自检，以及最终回复第一句就给结论。
- [steipete/oracle skill](https://github.com/steipete/oracle/blob/main/skills/oracle/SKILL.md)：采纳了其中的简报模板。oracle 对项目一无所知，所以要给项目概况、确切问题、已尝试的做法、报错原文、约束和期望产出。
- omp 自带的 plan 模式提示词：采纳了"决策完备的执行方案"标准，以及方案的章节结构（目标、步骤、关键文件、验证、假设与预案），并且不写非目标、备选方案等不承载决策的章节。
