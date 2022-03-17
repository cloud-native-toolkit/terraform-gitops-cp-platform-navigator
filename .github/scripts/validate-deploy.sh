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
OPERATOR_SUFFIX="operator"

if [[ ! -f "argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}-${OPERATOR_SUFFIX}.yaml" ]]; then
  echo "ArgoCD config missing - argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}-${OPERATOR_SUFFIX}.yaml"
  exit 1
fi

echo "Printing argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}-${OPERATOR_SUFFIX}.yaml"
cat "argocd/2-services/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}-${OPERATOR_SUFFIX}.yaml"

if [[ ! -f "payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}-${OPERATOR_SUFFIX}/values.yaml" ]]; then
  echo "Application values not found - payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}-${OPERATOR_SUFFIX}/values.yaml"
  exit 1
fi

echo "Printing payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}-${OPERATOR_SUFFIX}/values.yaml"
cat "payload/2-services/namespace/${NAMESPACE}/${COMPONENT_NAME}-${OPERATOR_SUFFIX}/values.yaml"


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
COMPONENT_NAME="ibm-integration-platform-navigator"
SUBSCRIPTION="subscription/${COMPONENT_NAME}"
count=0
until kubectl get "${SUBSCRIPTION}" -n "${NAMESPACE}" || [[ $count -eq 60 ]]; do
  echo "Waiting for ${SUBSCRIPTION} in ${NAMESPACE}"
  count=$((count + 1))
  sleep 60
done

if [[ $count -eq 60 ]]; then
  echo "Timed out waiting for ${SUBSCRIPTION} in ${NAMESPACE}"
  kubectl get subscription -n "${NAMESPACE}"
  exit 1
fi

CSV="ibm-integration-platform-navigator"
count=0
until [[ $(kubectl get csv -n "${NAMESPACE}" -l operators.coreos.com/${CSV}.${NAMESPACE}="" -o=jsonpath='{range .items[]}{.metadata.name}{"\n"}{end}' | wc -l) -gt 0 ]] || [[ $count -eq 60 ]]; do
  echo "Waiting for csv ${CSV} in ${NAMESPACE}"
  count=$((count + 1))
  sleep 60
done
 
if [[ $count -eq 60 ]]; then
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
#For cooling period
sleep 300
INSTANCE_NAME="integration-navigator"
CR="platformnavigator/${INSTANCE_NAME}"
count=0
until kubectl get "${CR}" -n "${NAMESPACE}" || [[ $count -eq 30 ]]; do
  echo "Waiting for ${CR} in ${NAMESPACE}"
  count=$((count + 1))
  sleep 30
done

if [[ $count -eq 30 ]]; then
  echo "Timed out waiting for ${CR} in ${NAMESPACE}"
  kubectl get platformnavigator -n "${NAMESPACE}"
  exit 1
fi

count=0
until [[ $(kubectl get deployment -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${INSTANCE_NAME}" | wc -l) -gt 0 ]] || [[ $count -eq 90 ]]; do
  echo "Waiting for deployment in ${NAMESPACE} with label app.kubernetes.io/instance=${INSTANCE_NAME}"
  count=$((count + 1))
  sleep 60
done

if [[ $count -eq 60 ]]; then
  echo "Timed out waiting for deployment in ${NAMESPACE} with label app.kubernetes.io/instance=${INSTANCE_NAME}"
  kubectl get deployment -n "${NAMESPACE}"
  exit 1
fi

DEPLOYMENT_NAME=$(kubectl get deployment -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${INSTANCE_NAME}" -o jsonpath='{range .items[]}{.metadata.name}{"\n"}{end}')
echo "Waiting for deployment rollout: ${DEPLOYMENT_NAME}"
oc rollout status deployment "${DEPLOYMENT_NAME}" -n "${NAMESPACE}" --timeout=10m
