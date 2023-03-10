#!/usr/bin/env bash

set -eo pipefail

# Set env var
ADMIN_PWD=$(oc get secret admin-user-details -n tools --template={{.data.initial_admin_password}} | base64 -d)
ZEN_URL=$(oc get zenservice lite-cr --template={{.status.url}})
BEARER_TOKEN=$(curl -k -X POST -H 'cache-control: no-cache' -H 'content-type: application/json' -d "{\"username\":\"admin\",\"password\":\"$ADMIN_PWD\"}" https://$ZEN_URL/icp4d-api/v1/authorize | jq '.token' | tr -d '"')

# Configure cpdctl
cpdctl config user set admin --username=admin --password=$ADMIN_PWD
cpdctl config profile set admin --url https://$ZEN_URL
cpdctl config context set admin --user admin --profile admin
cpdctl config context use admin
cpdctl config context list
cpdctl project list

# Import Data Governance artifacts
curl -k -X POST -H 'cache-control: no-cache' -H "Authorization: Bearer $BEARER_TOKEN" -F "file=@/cpd-resources/data-governance-artifacts.zip" "https://$ZEN_URL/v3/governance_artifact_types/import"

