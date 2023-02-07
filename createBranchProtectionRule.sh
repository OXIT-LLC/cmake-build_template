#!/bin/bash
set -ue
err() { echo 1>&2 "$*"; }
die() { err "ERROR: $*"; exit 1; }
mustBool() {
        [[ "${1#*=}" = "true" || "${1#*=}" = "false" ]] ||
                die "bad boolean property value: $1"
}
mustInt() {
        [[ "${1#*=}" =~ [0-9]+ ]] ||
                die "bad integer property value: $1"
}

[ $# -ge 4 ] || {
        err "usage: $0 <HOST> <ORG> <REPO> <PATTERN> [<PROPERTIES>]"
        err " <HOST>:           GitHub hostname for the request (default: github.com)"
        err " <ORG>:            Organization name (github repo owner)"
        err " <REPO>:           Repository name"
        err " <PATTERN>:        Branch name pattern (branch protection rule name)"
        err " <PROPERTIES>:(optinal)"
        err "                   dismissesStaleReviews=true|false"
        err "                   requiresApprovingReviewCount=INTEGER"
        err "                   requiresApprovingReviews=true|false"
        err "                   requiresCodeOwnerReviews=true|false"
        err "                   restrictPushes=true|false"
        err " "
        err "============================= Example ============================="
        err "./createBranchProtectionRule.sh github.com OXIT-LLC cmake-build_template testing\\"
        err " requiresApprovingReviews=true\\"
        err " requiresCodeOwnerReviews=true\\"
        err " requiredApprovingReviewCount=1\\"
        err " requiresStatusChecks=true\\"
        err " requiresStrictStatusChecks=false\\"
        err " requiredStatusCheckContexts=continuous-integration/jenkins/pr-merge\\"
        err " requiresLinearHistory=true"
        err "==================================================================="
        exit 1
}
hostname="$1"
org="$2"
repo="$3"
pattern="$4"
shift 4

repoNodeId="$(gh api --hostname "$hostname" "repos/$org/$repo" --jq .node_id)"
[[ -n "$repoNodeId" ]] || die "could not determine repo nodeId"

graphql="
mutation createBranchProtectionRule {
        createBranchProtectionRule(input: {
                repositoryId: \"$repoNodeId\"
                pattern: \"$pattern\""

seen=()
requiredStatusCheckContexts=()
for property in "$@"; do
        for eSeen in "${seen[@]:-}"; do
                [[ "${eSeen%%=*}" = "${property%%=*}" ]] &&
                # Allow duplication of multivalued properties
                [[ "${eSeen%%=*}" != "requiredStatusCheckContexts" ]] &&
                die "Duplicate property: $property"
        done
        seen+=("${property}")

        case "$property" in
        requiredStatusCheckContexts=*)
                requiredStatusCheckContexts+=("${property#*=}")
                ;;
        \
                allowsDeletions=* | \
                allowsForcePushes=* | \
                dismissesStaleReviews=* | \
                isAdminEnforced=* | \
                requiresApprovingReviews=* | \
                requiresCodeOwnerReviews=* | \
                requiresCommitSignatures=* | \
                requiresLinearHistory=* | \
                requiresStatusChecks=* | \
                requiresStrictStatusChecks=* | \
                restrictPushes=* | \
                restrictsPushes=* | \
                restrictsReviewDismissals=* \
        )
                mustBool "$property"
                graphql="$graphql
                ${property%%=*}: ${property#*=}"
                ;;
        requiredApprovingReviewCount=*)
                mustInt "$property"
                graphql="$graphql
                ${property%%=*}: ${property#*=}"
                ;;
        *)
                die "unknown property: $property"
        esac
done

if [ -n "${requiredStatusCheckContexts[*]:-}" ]; then
        graphql="$graphql
                requiredStatusCheckContexts: [
"
        i=0
        for context in "${requiredStatusCheckContexts[@]}"; do
                [ $i -ne 0 ] && graphql="$graphql,
"
                i=$((1+$i))
                graphql="$graphql"$'\t\t\t'"\"$context\""
        done
        graphql="$graphql
                ]
"
fi

graphql="$graphql
        }) {
                branchProtectionRule {
                        allowsDeletions
                        allowsForcePushes
                        creator { login }
                        databaseId
                        dismissesStaleReviews
                        isAdminEnforced
                        pattern
                        repository { nameWithOwner }
                        requiredApprovingReviewCount
                        requiresApprovingReviews
                        requiredStatusCheckContexts
                        requiresCodeOwnerReviews
                        requiresCommitSignatures
                        requiresLinearHistory
                        requiresStatusChecks
                        requiresStrictStatusChecks
                        restrictsPushes
                        restrictsReviewDismissals
                }
                clientMutationId
        }
}"

gh api --hostname "$hostname" graphql -F "query=$graphql" ||
        die "GraphQL update failed: $graphql"
echo ""
echo "SUCCESS: Branch protection rule successfully created"
