---
name: consult-oracle
description: "Briefs and dispatches the read-only oracle subagent for planning and hard problems. Use when about to start a large multi-subsystem or multi-session task, after two failed fix attempts at the same bug, when evidence contradicts itself, or before an irreversible architecture, security, data, or performance decision."
---

# consult-oracle

## Scope

`oracle` 是只读顾问 subagent，模型取自 `@oracle` 角色（最贵的顶级模型）。它慢、贵，并且启动时对当前对话一无所知。本 skill 规定何时召唤它、如何写简报、如何使用它的回复。

不涵盖：代码定位与广度搜索（用 `scout`）、执行改动（自己做或派 `task`）。

## 何时召唤

- **规划**：任务跨多个子系统或多个会话、需要切分给并行子 agent、或方案选错的返工代价高。先自己或用 `scout` 粗探出相关文件，再召唤 oracle 定方案。
- **卡住**：同一问题两次修复失败；证据互相矛盾；不知道下一步该查什么；即将做难以回滚的决定。
- **不召唤**：第一次尝试；查找、定位；读代码就能回答的问题；命名、格式等琐事。召唤的成本以分钟和美元计。

## 调用约束

- oracle 单独占一次 `task` 调用，不与其他 agent 同批：`context` 会注入同批每个子 agent。它是阻塞式的，结果在这次调用里直接返回，一次常需数分钟。
- oracle 不能运行命令、测试或复现，也不改任何文件：它需要的运行结果由你先跑好放进简报，它回复里的命令由你执行。不要让它"验证一下"或"顺手修掉"。
- 你处于 plan 模式时，oracle 派不了 `scout`，只能自己逐个读文件：简报里的文件清单要给全。

## 简报

oracle 看不到你的对话，简报就是它的全部世界；缺什么它就只能猜什么。`context` 与 `task` 合起来必须覆盖：

1. **目标**：要达到的可观测终态，以及用户原始诉求中的关键原话。
2. **现状**：相关模块、入口文件、硬约束（兼容性、不能改的文件、性能预算）。
3. **已尝试**：每次尝试做了什么、结果如何。错误信息与测试输出贴原文，不要概括——概括会丢掉 oracle 最需要的细节。
4. **证据位置**：`path:line`、相关提交、日志路径。
5. **当前假设**：你怀疑什么，明确标为假设，方便它推翻。
6. **要什么产出**：执行方案 / 根因与下一步 / 方案评审。

超过几十行的日志、diff、复现输出，先写进 `local://oracle-<slug>-brief.md`，简报里只给路径；oracle 能直接 `read` 它。

追问同一问题（补充检查结果、提出反证）时，用 `write agent://<上次 oracle 的 id>` 直接给原 oracle 发消息：它保留已读过的代码与推理，休眠后也会被唤醒。换了问题才新开一个，并在简报里附上 `agent://<上次的 id>` 供它读取上次的完整回复。

```json
{
  "context": "# 目标\n...\n# 现状\n...\n# 已尝试\n1. ... → 报错原文见 local://oracle-ws-reconnect-brief.md\n# 当前假设\n...",
  "tasks": [
    {
      "agent": "oracle",
      "task": "给出根因排序、能区分假设的最便宜检查，以及推荐修复。",
      "solutionSpace": "根因未定；已排除网络层超时"
    }
  ]
}
```

## 拿到回复后

- 内联结果被截成预览时，先 `read agent://<id>` 取全文再行动。
- 当作强建议而非命令：动手前抽查它依赖的关键断言（路径、API、行为）。
- 顾问回复先跑它给的判别性检查，再改代码。结果落在它的分支预案之外时，带着新证据按上面的追问方式再问，不要自己硬改。
- 与它有分歧：把你的反证发给它，不要静默忽略。
- 规划回复：完整方案在它回复给出的 `local://<slug>-plan.md` 里（回复首行写"方案未落盘"时，方案就在回复正文），先读全文再按步骤执行；你处于 plan 模式时，把它并入你自己的计划文件走正常审批。「待用户决定」各项用 `ask` 交给用户，带上它推荐的默认值。
