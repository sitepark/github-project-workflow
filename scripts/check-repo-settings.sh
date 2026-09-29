#!/usr/bin/env bash
#
# Checks the GitHub settings of all repositories matched by a config file
# (see repo-settings/*.json) and reports every deviation from the target values.
#
# Usage: check-repo-settings.sh <config.json> [--apply]
#
#   --apply  correct all deviations, then check again
#
# Exit codes: 0 = no deviations, 1 = deviations found, 2 = errors (e.g. missing token permissions)
#
# Requires: gh (authenticated via GH_TOKEN with scopes repo and read:org;
#           --apply additionally needs admin:org to change team roles), jq

set -euo pipefail

usage="usage: $0 <config.json> [--apply]"
config_file=${1:?$usage}
apply=false
if [[ "${2:-}" == "--apply" ]]; then
  apply=true
elif [[ -n "${2:-}" ]]; then
  echo "$usage" >&2
  exit 2
fi

owner=$(jq -r '.owner' "$config_file")
pattern=$(jq -r '.repoPattern' "$config_file")
config_name=$(basename "$config_file" .json)

deviations=()
errors=()

# Converts a GET branch protection response into the format of the PUT request,
# so that it can be compared with the target configuration.
normalize_protection='
  if . == null then null else {
    required_status_checks: (.required_status_checks | if . == null then null else
      {strict, checks: ([.checks[] | {context, app_id}] | sort_by(.context))} end),
    enforce_admins: .enforce_admins.enabled,
    required_pull_request_reviews: (.required_pull_request_reviews | if . == null then null else {
      dismiss_stale_reviews,
      require_code_owner_reviews,
      require_last_push_approval,
      required_approving_review_count,
      bypass_pull_request_allowances: {
        users: ([.bypass_pull_request_allowances.users[]?.login] | sort),
        teams: ([.bypass_pull_request_allowances.teams[]?.slug] | sort),
        apps: ([.bypass_pull_request_allowances.apps[]?.slug] | sort)
      }
    } end),
    restrictions: (.restrictions | if . == null then null else {
      users: ([.users[]?.login] | sort),
      teams: ([.teams[]?.slug] | sort),
      apps: ([.apps[]?.slug] | sort)
    } end),
    required_linear_history: .required_linear_history.enabled,
    allow_force_pushes: .allow_force_pushes.enabled,
    allow_deletions: .allow_deletions.enabled,
    block_creations: .block_creations.enabled,
    required_conversation_resolution: .required_conversation_resolution.enabled,
    lock_branch: .lock_branch.enabled,
    allow_fork_syncing: .allow_fork_syncing.enabled
  } end'

# Same sort order as normalize_protection, applied to the target configuration.
sort_protection='
  if . == null then null else
    (if .required_status_checks != null then .required_status_checks.checks |= sort_by(.context) else . end)
    | (if .required_pull_request_reviews != null
        then .required_pull_request_reviews.bypass_pull_request_allowances |= map_values(sort) else . end)
  end'

# Prints "key<TAB>actual<TAB>target" for every leaf that differs between two JSON documents.
# shellcheck disable=SC2016 # $actual, $target etc. are jq variables
diff_json='
  def flat($p): if type == "object" and length > 0
    then (to_entries[] as $e | $e.value | flat($p + [$e.key]))
    else {key: (if $p == [] then "(root)" else $p | join(".") end), value: tojson} end;
  ([$actual | flat([])] | from_entries) as $a
  | ([$target | flat([])] | from_entries) as $t
  | ($a + $t | keys[]) as $k
  | select($a[$k] != $t[$k])
  | [$k, ($a[$k] // "(not set)"), ($t[$k] // "(not set)")] | @tsv'

report() {
  local repo=$1 area=$2 key=$3 actual=$4 target=$5
  deviations+=("$repo|$area|$key|$actual|$target")
  printf '%s | %s | %s | %s → %s\n' "$repo" "$area" "$key" "$actual" "$target"
}

error() {
  errors+=("$1")
  printf 'ERROR: %s\n' "$1" >&2
}

# Maps a role name as reported by GitHub to the permission value of the PUT request.
team_permission() {
  case $1 in
    read) echo pull ;;
    write) echo push ;;
    *) echo "$1" ;;
  esac
}

check_repository() {
  local repo=$1 target=$2 actual diff
  actual=$(gh api "repos/$owner/$repo")
  diff=$(jq -rn --argjson actual "$actual" --argjson target "$target" \
    '$target | to_entries[] | select($actual[.key] != .value) | [.key, ($actual[.key] | tojson), (.value | tojson)] | @tsv')
  [[ -z "$diff" ]] && return 0
  while IFS=$'\t' read -r key actual_value target_value; do
    report "$repo" repository "$key" "$actual_value" "$target_value"
  done <<< "$diff"
  if $apply; then
    jq -n --argjson actual "$actual" --argjson target "$target" \
      '$target | with_entries(select($actual[.key] != .value))' \
      | gh api -X PATCH "repos/$owner/$repo" --input - > /dev/null
  fi
}

check_vulnerability_alerts() {
  local repo=$1 target=$2 out actual
  if out=$(gh api "repos/$owner/$repo/vulnerability-alerts" 2>&1); then
    actual=true
  elif [[ "$out" == *"HTTP 404"* ]]; then
    actual=false
  else
    error "$repo: cannot read vulnerability alerts: $out"
    return 0
  fi
  [[ "$actual" == "$target" ]] && return 0
  report "$repo" vulnerability-alerts enabled "$actual" "$target"
  if $apply; then
    if [[ "$target" == true ]]; then
      gh api -X PUT "repos/$owner/$repo/vulnerability-alerts" > /dev/null
    else
      gh api -X DELETE "repos/$owner/$repo/vulnerability-alerts" > /dev/null
    fi
  fi
}

# Dependabot security updates, requires enabled vulnerability alerts.
check_automated_security_fixes() {
  local repo=$1 target=$2 out actual
  if ! out=$(gh api "repos/$owner/$repo/automated-security-fixes" --jq '.enabled' 2>&1); then
    error "$repo: cannot read automated security fixes: $out"
    return 0
  fi
  actual=$out
  [[ "$actual" == "$target" ]] && return 0
  report "$repo" automated-security-fixes enabled "$actual" "$target"
  if $apply; then
    if [[ "$target" == true ]]; then
      gh api -X PUT "repos/$owner/$repo/automated-security-fixes" > /dev/null
    else
      gh api -X DELETE "repos/$owner/$repo/automated-security-fixes" > /dev/null
    fi
  fi
}

check_team() {
  local repo=$1 team=$2 target=$3 out actual
  if out=$(gh api "orgs/$owner/teams/$team/repos/$owner/$repo" \
    -H "Accept: application/vnd.github.v3.repository+json" --jq '.role_name' 2>&1); then
    actual=$out
  elif [[ "$out" == *"HTTP 404"* ]]; then
    actual="(no access)"
  else
    error "$repo: cannot read permission of team $team: $out"
    return 0
  fi
  [[ "$actual" == "$target" ]] && return 0
  report "$repo" team "$team" "$actual" "$target"
  if $apply; then
    gh api -X PUT "orgs/$owner/teams/$team/repos/$owner/$repo" \
      -f permission="$(team_permission "$target")" > /dev/null
  fi
}

check_branch_protection() {
  local repo=$1 branch=$2 target=$3 out actual diff
  if out=$(gh api "repos/$owner/$repo/branches/$branch/protection" 2>&1); then
    actual=$(jq -c "$normalize_protection" <<< "$out")
  elif [[ "$out" == *"Branch not protected"* ]]; then
    actual=null
  else
    error "$repo: cannot read branch protection of $branch: $out"
    return 0
  fi
  target=$(jq -c "$sort_protection" <<< "$target")
  if [[ "$actual" == null || "$target" == null ]]; then
    [[ "$actual" == "$target" ]] && return 0
    report "$repo" "branch-protection ($branch)" protection \
      "$([[ "$actual" == null ]] && echo "(not protected)" || echo "(protected)")" \
      "$([[ "$target" == null ]] && echo "(not protected)" || echo "(protected)")"
  else
    diff=$(jq -rn --argjson actual "$actual" --argjson target "$target" "$diff_json")
    [[ -z "$diff" ]] && return 0
    while IFS=$'\t' read -r key actual_value target_value; do
      report "$repo" "branch-protection ($branch)" "$key" "$actual_value" "$target_value"
    done <<< "$diff"
  fi
  if $apply; then
    if [[ "$target" == null ]]; then
      gh api -X DELETE "repos/$owner/$repo/branches/$branch/protection" > /dev/null
    else
      gh api -X PUT "repos/$owner/$repo/branches/$branch/protection" --input - <<< "$target" > /dev/null
    fi
  fi
}

write_summary() {
  [[ -z "${GITHUB_STEP_SUMMARY:-}" ]] && return 0
  {
    echo "## Repository settings: $config_name"
    echo
    if ((${#deviations[@]} == 0)); then
      echo "No deviations in ${#repos[@]} repositories."
    else
      if $apply; then
        echo "${#deviations[@]} deviations in ${#repos[@]} repositories corrected."
      else
        echo "${#deviations[@]} deviations in ${#repos[@]} repositories."
      fi
      echo
      echo "| Repository | Area | Key | Actual | Target |"
      echo "|---|---|---|---|---|"
      local line
      for line in "${deviations[@]}"; do
        echo "| ${line//|/ | } |"
      done
    fi
    if ((${#errors[@]} > 0)); then
      echo
      echo "### Errors"
      echo
      local e
      for e in "${errors[@]}"; do
        echo "- ${e//$'\n'/ }"
      done
    fi
  } >> "$GITHUB_STEP_SUMMARY"
}

# Fail early if the token cannot read the configured teams (scope read:org missing).
while read -r team; do
  [[ -z "$team" ]] && continue
  if ! out=$(gh api "orgs/$owner/teams/$team" 2>&1); then
    echo "ERROR: cannot read team $owner/$team, the token probably lacks the scope read:org: $out" >&2
    exit 2
  fi
done < <(jq -r '.teams // {} | keys[]' "$config_file")

mapfile -t repos < <(
  gh repo list "$owner" --no-archived --limit 1000 --json name --jq '.[].name' \
    | grep -E "$pattern" \
    | grep -vxF -f <(jq -r '.exclude // [] | .[]' "$config_file"; echo "") \
    | sort
)

for repo in "${repos[@]}"; do
  config=$(jq -c --arg repo "$repo" '(del(.overrides) * (.overrides[$repo] // {}))' "$config_file")

  if [[ $(jq '.repository != null' <<< "$config") == true ]]; then
    check_repository "$repo" "$(jq -c '.repository' <<< "$config")"
  fi
  if [[ $(jq '.vulnerabilityAlerts != null' <<< "$config") == true ]]; then
    check_vulnerability_alerts "$repo" "$(jq '.vulnerabilityAlerts' <<< "$config")"
  fi
  if [[ $(jq '.automatedSecurityFixes != null' <<< "$config") == true ]]; then
    check_automated_security_fixes "$repo" "$(jq '.automatedSecurityFixes' <<< "$config")"
  fi
  while IFS=$'\t' read -r team permission; do
    [[ -z "$team" ]] && continue
    check_team "$repo" "$team" "$permission"
  done < <(jq -r '.teams // {} | to_entries[] | [.key, .value] | @tsv' <<< "$config")
  if [[ $(jq '.branchProtection != null' <<< "$config") == true ]]; then
    check_branch_protection "$repo" \
      "$(jq -r '.branchProtection.branch' <<< "$config")" \
      "$(jq -c '.branchProtection.protection' <<< "$config")"
  fi
done

echo "Checked ${#repos[@]} repositories, ${#deviations[@]} deviations, ${#errors[@]} errors."

if $apply && ((${#deviations[@]} > 0)); then
  write_summary
  echo "Deviations corrected, checking again ..."
  exec "$0" "$config_file"
fi

write_summary

if ((${#errors[@]} > 0)); then
  exit 2
fi
if ((${#deviations[@]} > 0)); then
  exit 1
fi
