#!/usr/bin/env bash

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)

export KUBECONFIG=$(cat .kubeconfig)

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

NAMESPACE="openshift-operators"
BRANCH="main"
SERVER_NAME="default"
TYPE="operators"

COMPONENT_NAME="ibm-platform-navigator"

if [[ ! -f "argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml" ]]; then
  echo "ArgoCD config missing - argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
  exit 1
fi

echo "Printing argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
cat "argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"

if [[ ! -f "payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml" ]]; then
  echo "Application values not found - payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
  exit 1
fi

echo "Printing payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
cat "payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"


count=0
until kubectl get namespace "${NAMESPACE}" 1> /dev/null 2> /dev/null || [[ $count -eq 20 ]]; do
  echo "Waiting for namespace: ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for namespace: ${NAMESPACE}"
  exit 1
else
  echo "Found namespace: ${NAMESPACE}. Sleeping for 30 seconds to wait for everything to settle down"
  sleep 30
fi

SUBSCRIPTION="subscription/${COMPONENT_NAME}"
count=0
until kubectl get "${SUBSCRIPTION}" -n "${NAMESPACE}" || [[ $count -eq 20 ]]; do
  echo "Waiting for ${SUBSCRIPTION} in ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for ${SUBSCRIPTION} in ${NAMESPACE}"
  kubectl get subscription -n "${NAMESPACE}"
  exit 1
fi

CSV="ibm-integration-platform-navigator"
count=0
until [[ $(kubectl get csv -n "${NAMESPACE}" -l operators.coreos.com/${CSV}.${NAMESPACE}="" -o=jsonpath='{range .items[]}{.metadata.name}{"\n"}{end}' | wc -l) -gt 0 ]] || [[ $count -eq 20 ]]; do
  echo "Waiting for csv ${CSV} in ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for ${CSV} in ${NAMESPACE}"
  kubectl get csv -n "${NAMESPACE}"
  exit 1
fi

echo "Found CSV"
kubectl get csv -n "${NAMESPACE}" -l operators.coreos.com/${CSV}.${NAMESPACE}="" -o=jsonpath='{range .items[]}{.metadata.name}{"\n"}{end}'

## ***** Instance

NAMESPACE="gitops-cp-platform-navigator"
BRANCH="main"
SERVER_NAME="default"
TYPE="instances"

COMPONENT_NAME="ibm-platform-navigator-instance"

if [[ ! -f "argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml" ]]; then
  echo "ArgoCD config missing - argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
  exit 1
fi

echo "Printing argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
cat "argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"

if [[ ! -f "payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml" ]]; then
  echo "Application values not found - payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
  exit 1
fi

echo "Printing payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
cat "payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"

cd ..
rm -rf .testrepo

INSTANCE_NAME="integration-navigator"
CR="platformnavigator/${INSTANCE_NAME}"
count=0
until kubectl get "${CR}" -n "${NAMESPACE}" || [[ $count -eq 20 ]]; do
  echo "Waiting for ${CR} in ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for ${CR} in ${NAMESPACE}"
  kubectl get platformnavigator -n "${NAMESPACE}"
  exit 1
fi

DEPLOYMENT="deployment/${INSTANCE_NAME}"
count=0
until kubectl get "${DEPLOYMENT}" -n "${NAMESPACE}" || [[ $count -eq 20 ]]; do
  echo "Waiting for ${DEPLOYMENT} in ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for ${DEPLOYMENT} in ${NAMESPACE}"
  kubectl get deployment -n "${NAMESPACE}"
  exit 1
fi
