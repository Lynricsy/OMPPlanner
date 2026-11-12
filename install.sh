#!/usr/bin/env bash
# 把本仓库的 oracle agent 与 consult-oracle skill 软链到 omp 用户目录（可重复执行）。
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
agent_dir="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"

mkdir -p "$agent_dir/agents" "$agent_dir/skills"
ln -sfn "$repo/agents/oracle.md" "$agent_dir/agents/oracle.md"
ln -sfn "$repo/skills/consult-oracle" "$agent_dir/skills/consult-oracle"

echo "已安装到 $agent_dir"
if ! awk '/^modelRoles:/{f=1; next} /^[^[:space:]]/{f=0} f && /^[[:space:]]+oracle:/{found=1} END{exit !found}' "$agent_dir/config.yml" 2>/dev/null; then
  echo "提示：请在 $agent_dir/config.yml 的 modelRoles 下添加 oracle 角色，例如 oracle: anthropic/claude-fable-5-2:xhigh" >&2
fi
