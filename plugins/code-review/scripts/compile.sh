#!/usr/bin/env bash
set -euo pipefail

# compile.sh — Generate agent and skill files from prompt sources and compile.conf
#
# Usage:
#   ./scripts/compile.sh          # Compile all agents and skills in-place
#   ./scripts/compile.sh --check  # Verify compiled files are up to date (exit 1 if stale)
#
# Must be run from plugins/code-review/ or handles path resolution automatically.

# ---------------------------------------------------------------------------
# Path resolution — resolve all paths relative to the script's own location
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CONF_FILE="${PLUGIN_ROOT}/prompts/compile.conf"
PROMPTS_DIR="${PLUGIN_ROOT}/prompts"
AGENTS_DIR="${PLUGIN_ROOT}/agents"
SKILLS_DIR="${PLUGIN_ROOT}/skills"

# Known domains for name parsing
KNOWN_DOMAINS=("sre" "security" "architecture" "data")

# Counters
AGENT_COUNT=0
SKILL_COUNT=0
WARNINGS=0

# --check mode
CHECK_MODE=false
TEMP_DIR=""
DIFF_FOUND=false

if [[ "${1:-}" == "--check" ]]; then
    CHECK_MODE=true
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "${TEMP_DIR}"' EXIT
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Parse domain from agent name. The domain is a known prefix; the pillar is the remainder.
# e.g. sre-response -> domain=sre, pillar=response
# e.g. security-authn-authz -> domain=security, pillar=authn-authz
parse_domain_pillar() {
    local name="$1"
    PARSED_DOMAIN=""
    PARSED_PILLAR=""

    for d in "${KNOWN_DOMAINS[@]}"; do
        if [[ "${name}" == "${d}-"* ]]; then
            PARSED_DOMAIN="${d}"
            PARSED_PILLAR="${name#"${d}-"}"
            return 0
        fi
    done

    echo "  WARNING: Cannot determine domain for agent '${name}' — skipping" >&2
    (( WARNINGS++ )) || true
    return 1
}

# Read a file's contents if it exists; otherwise print a warning and return empty.
read_file_or_warn() {
    local filepath="$1"
    local context="$2"

    if [[ -f "${filepath}" ]]; then
        cat "${filepath}"
    else
        echo "  WARNING: ${context} not found: ${filepath}" >&2
        (( WARNINGS++ )) || true
        return 1
    fi
}

# Extract the ## Synthesis section from a file (content between ## Synthesis and next ## or EOF).
extract_synthesis_section() {
    local filepath="$1"

    if [[ ! -f "${filepath}" ]]; then
        return 1
    fi

    local in_section=false
    local content=""

    while IFS= read -r line || [[ -n "${line}" ]]; do
        if [[ "${in_section}" == true ]]; then
            # Stop at the next ## heading
            if [[ "${line}" =~ ^##\  ]] && [[ "${line}" != "## Synthesis" ]]; then
                break
            fi
            content+="${line}"$'\n'
        elif [[ "${line}" == "## Synthesis"* ]]; then
            in_section=true
            content+="${line}"$'\n'
        fi
    done < "${filepath}"

    if [[ -n "${content}" ]]; then
        printf '%s' "${content}"
        return 0
    fi

    return 1
}

# Write output to the correct location (real or temp for --check mode).
write_output() {
    local relative_path="$1"
    local content="$2"

    local target_dir
    local target_path

    if [[ "${CHECK_MODE}" == true ]]; then
        target_path="${TEMP_DIR}/${relative_path}"
    else
        target_path="${PLUGIN_ROOT}/${relative_path}"
    fi

    target_dir="$(dirname "${target_path}")"
    mkdir -p "${target_dir}"
    printf '%s' "${content}" > "${target_path}"

    # In check mode, compare with the real file
    if [[ "${CHECK_MODE}" == true ]]; then
        local real_path="${PLUGIN_ROOT}/${relative_path}"
        if [[ ! -f "${real_path}" ]]; then
            echo "  MISSING: ${relative_path}" >&2
            DIFF_FOUND=true
        elif ! diff -q "${real_path}" "${target_path}" > /dev/null 2>&1; then
            echo "  OUT OF SYNC: ${relative_path}" >&2
            DIFF_FOUND=true
        fi
    fi
}

# Concatenate content from multiple sources with blank lines between them.
# Arguments are file paths; missing files are skipped with warnings.
concat_sources() {
    local result=""
    local first=true

    for filepath in "$@"; do
        local content
        if content="$(read_file_or_warn "${filepath}" "Source file")"; then
            if [[ "${first}" == true ]]; then
                first=false
            else
                result+=$'\n\n'
            fi
            result+="${content}"
        fi
    done

    printf '%s' "${result}"
}

# ---------------------------------------------------------------------------
# Validate
# ---------------------------------------------------------------------------

if [[ ! -f "${CONF_FILE}" ]]; then
    echo "ERROR: compile.conf not found at ${CONF_FILE}" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Compile agents
# ---------------------------------------------------------------------------

echo "Compiling agents..."

while IFS='|' read -r type name model description; do
    # Skip comments and blank lines
    [[ -z "${type}" || "${type}" =~ ^[[:space:]]*# ]] && continue
    # Strip leading/trailing whitespace
    type="$(echo "${type}" | xargs)"
    name="$(echo "${name}" | xargs)"
    model="$(echo "${model}" | xargs)"
    description="$(echo "${description}" | xargs)"

    [[ "${type}" != "agent" ]] && continue

    # Parse domain and pillar
    if ! parse_domain_pillar "${name}"; then
        continue
    fi
    local_domain="${PARSED_DOMAIN}"
    local_pillar="${PARSED_PILLAR}"

    echo "  Agent: ${name} (domain=${local_domain}, pillar=${local_pillar})"

    # Build YAML frontmatter
    frontmatter="---
name: ${name}
description: ${description}. Spawned by /code-review:${local_domain} or /code-review:all.
model: ${model}
tools: Read, Grep, Glob
---"

    # Collect shared prompt files (alphabetical order, excluding synthesis.md)
    shared_files=()
    if [[ -d "${PROMPTS_DIR}/shared" ]]; then
        while IFS= read -r f; do
            local_basename="$(basename "${f}")"
            if [[ "${local_basename}" != "synthesis.md" && "${local_basename}" != ".gitkeep" ]]; then
                shared_files+=("${f}")
            fi
        done < <(find "${PROMPTS_DIR}/shared" -maxdepth 1 -name '*.md' -type f | sort)
    fi

    # Domain base file
    domain_base="${PROMPTS_DIR}/${local_domain}/_base.md"

    # Pillar prompt
    pillar_file="${PROMPTS_DIR}/${local_domain}/${local_pillar}.md"

    # Build source list
    source_files=()
    if [[ ${#shared_files[@]} -gt 0 ]]; then
        source_files+=("${shared_files[@]}")
    fi
    source_files+=("${domain_base}" "${pillar_file}")

    # Concatenate
    body="$(concat_sources "${source_files[@]}")"

    # Combine frontmatter + body
    if [[ -n "${body}" ]]; then
        output="${frontmatter}"$'\n\n'"${body}"$'\n'
    else
        output="${frontmatter}"$'\n'
    fi

    write_output "agents/${name}.md" "${output}"
    (( AGENT_COUNT++ )) || true

done < "${CONF_FILE}"

# ---------------------------------------------------------------------------
# Compile skills
# ---------------------------------------------------------------------------

echo "Compiling skills..."

while IFS='|' read -r type name model description; do
    # Skip comments and blank lines
    [[ -z "${type}" || "${type}" =~ ^[[:space:]]*# ]] && continue
    # Strip leading/trailing whitespace
    type="$(echo "${type}" | xargs)"
    name="$(echo "${name}" | xargs)"
    model="$(echo "${model}" | xargs)"
    description="$(echo "${description}" | xargs)"

    [[ "${type}" != "skill" ]] && continue

    echo "  Skill: ${name}"

    # Build YAML frontmatter
    frontmatter="---
name: ${name}
description: ${description}.
argument-hint: [path|PR#|.]
allowed-tools: Task, Read, Grep, Glob, Bash, Write
---"

    # Shared synthesis file
    synthesis_file="${PROMPTS_DIR}/shared/synthesis.md"

    if [[ "${name}" == "all" ]]; then
        # All skill: orchestration content + shared synthesis + all domain synthesis additions
        body=""

        # Orchestration instructions (scope detection, dispatch, output structure)
        all_base="${PROMPTS_DIR}/all/_base.md"
        if all_base_content="$(read_file_or_warn "${all_base}" "All skill base")"; then
            body="${all_base_content}"
        fi

        if synthesis_content="$(read_file_or_warn "${synthesis_file}" "Shared synthesis")"; then
            if [[ -n "${body}" ]]; then
                body+=$'\n\n'
            fi
            body+="${synthesis_content}"
        fi

        for d in "${KNOWN_DOMAINS[@]}"; do
            domain_base="${PROMPTS_DIR}/${d}/_base.md"
            if domain_synthesis="$(extract_synthesis_section "${domain_base}")"; then
                if [[ -n "${body}" ]]; then
                    body+=$'\n\n'
                fi
                body+="${domain_synthesis}"
            fi
        done
    else
        # Domain skill: gather synthesis from this domain's _base.md
        domain_base="${PROMPTS_DIR}/${name}/_base.md"
        body=""

        if synthesis_content="$(read_file_or_warn "${synthesis_file}" "Shared synthesis")"; then
            body="${synthesis_content}"
        fi

        if domain_synthesis="$(extract_synthesis_section "${domain_base}")"; then
            if [[ -n "${body}" ]]; then
                body+=$'\n\n'
            fi
            body+="${domain_synthesis}"
        fi
    fi

    # Combine frontmatter + body
    if [[ -n "${body}" ]]; then
        output="${frontmatter}"$'\n\n'"${body}"$'\n'
    else
        output="${frontmatter}"$'\n'
    fi

    write_output "skills/${name}/SKILL.md" "${output}"
    (( SKILL_COUNT++ )) || true

done < "${CONF_FILE}"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
echo "Compilation complete: ${AGENT_COUNT} agents, ${SKILL_COUNT} skills compiled."

if (( WARNINGS > 0 )); then
    echo "${WARNINGS} warning(s) — some source files were missing (expected during scaffolding)."
fi

if [[ "${CHECK_MODE}" == true ]]; then
    if [[ "${DIFF_FOUND}" == true ]]; then
        echo ""
        echo "CHECK FAILED: Some compiled files are out of sync. Run ./scripts/compile.sh to regenerate."
        exit 1
    else
        echo "CHECK PASSED: All compiled files are up to date."
        exit 0
    fi
fi
