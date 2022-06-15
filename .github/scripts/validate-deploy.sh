#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

source "${SCRIPT_DIR}/validation-functions.sh"

BIN_DIR=$(cat .bin_dir)

export PATH="${BIN_DIR}:${PATH}"

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)

export KUBECONFIG=$(cat .kubeconfig)

if ! command -v jq 1> /dev/null 2> /dev/null; then
  echo "oc cli not found" >&2
  exit 1
fi

if ! command -v oc 1> /dev/null 2> /dev/null; then
  echo "oc cli not found" >&2
  exit 1
fi

if ! command -v kubectl 1> /dev/null 2> /dev/null; then
  echo "kubectl cli not found" >&2
  exit 1
fi

SUBSCRIPTION_NAMESPACE=$(jq -r '.subscription_namespace // "openshift-operators"' gitops-output.json)
SUBSCRIPTION_NAME=$(jq -r '.subscription_name // "my-module"' gitops-output.json)
SUBSCRIPTION_TYPE=$(jq -r '.subscription_type // "operators"' gitops-output.json)

NAMESPACE=$(jq -r '.namespace // "gitops-cp-platform-navigator"' gitops-output.json)
COMPONENT_NAME=$(jq -r '.name // "my-module"' gitops-output.json)
BRANCH=$(jq -r '.branch // "main"' gitops-output.json)
SERVER_NAME=$(jq -r '.server_name // "default"' gitops-output.json)
LAYER=$(jq -r '.layer_dir // "2-services"' gitops-output.json)
TYPE=$(jq -r '.type // "instances"' gitops-output.json)

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

set -e

validate_gitops_content "${SUBSCRIPTION_NAMESPACE}" "${LAYER}" "${SERVER_NAME}" "${SUBSCRIPTION_TYPE}" "${SUBSCRIPTION_NAME}" "values.yaml"
validate_gitops_content "${NAMESPACE}" "${LAYER}" "${SERVER_NAME}" "${TYPE}" "${COMPONENT_NAME}" "values.yaml"

check_k8s_namespace "${NAMESPACE}"

check_k8s_resource "${SUBSCRIPTION_NAMESPACE}" subscription "ibm-integration-platform-navigator"
check_k8s_resource "${NAMESPACE}" csv "ibm-integration-platform-navigator.*"
INSTANCE_NAME="integration-navigator"
check_k8s_resource "${NAMESPACE}" platformnavigator "${INSTANCE_NAME}"

count=0
while [[ -z "${DEPLOYMENT_NAME}" ]] && [[ $count -lt 30 ]]; do
  DEPLOYMENT_NAME=$(kubectl get deployment -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${INSTANCE_NAME}" --output JSON | jq -r '.items | first | .metadata.name // empty')

  count=$((count + 1))
  sleep 120
done

if [[ -z "${DEPLOYMENT_NAME}" ]]; then
  echo "Deployment not found: label=app.kubernetes.io/instance=${INSTANCE_NAME}" >&2
  kubectl get deployment -n "${NAMESPACE}" --show-labels >&2
  exit 1
fi

check_k8s_resource "${NAMESPACE}" deployment "${DEPLOYMENT_NAME}"


## ***** Instance

#NAMESPACE="gitops-cp-platform-navigator"
#BRANCH="main"
#SERVER_NAME="default"
#TYPE="instances"
#
#COMPONENT_NAME="ibm-platform-navigator-instance"
#
#if [[ ! -f "argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml" ]]; then
#  echo "ArgoCD config missing - argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
#  exit 1
#fi
#
#echo "Printing argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
#cat "argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
#
#if [[ ! -f "payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml" ]]; then
#  echo "Application values not found - payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
#  exit 1
#fi
#
#echo "Printing payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
#cat "payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
#
#cd ..
#rm -rf .testrepo
##For cooling period
#sleep 300
#INSTANCE_NAME="integration-navigator"
#CR="platformnavigator/${INSTANCE_NAME}"
#count=0
#until kubectl get "${CR}" -n "${NAMESPACE}" || [[ $count -eq 30 ]]; do
#  echo "Waiting for ${CR} in ${NAMESPACE}"
#  count=$((count + 1))
#  sleep 30
#done
#
#if [[ $count -eq 30 ]]; then
#  echo "Timed out waiting for ${CR} in ${NAMESPACE}"
#  kubectl get platformnavigator -n "${NAMESPACE}"
#  exit 1
#fi
#
#count=0
#until [[ $(kubectl get deployment -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${INSTANCE_NAME}" | wc -l) -gt 0 ]] || [[ $count -eq 90 ]]; do
#  echo "Waiting for deployment in ${NAMESPACE} with label app.kubernetes.io/instance=${INSTANCE_NAME}"
#  count=$((count + 1))
#  sleep 60
#done
#
#if [[ $count -eq 60 ]]; then
#  echo "Timed out waiting for deployment in ${NAMESPACE} with label app.kubernetes.io/instance=${INSTANCE_NAME}"
#  kubectl get deployment -n "${NAMESPACE}"
#  exit 1
#fi
#
#DEPLOYMENT_NAME=$(kubectl get deployment -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${INSTANCE_NAME}" -o jsonpath='{range .items[]}{.metadata.name}{"\n"}{end}')
#echo "Waiting for deployment rollout: ${DEPLOYMENT_NAME}"
#oc rollout status deployment "${DEPLOYMENT_NAME}" -n "${NAMESPACE}" --timeout=10m
