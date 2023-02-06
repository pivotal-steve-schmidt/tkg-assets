#!/bin/bash

. ./config

kubectl create -f - <<xxEOFxx
apiVersion: installers.tmc.cloud.vmware.com/v1alpha1
kind: AgentInstall
metadata:
  name: tmc-agent-installer-config
  namespace: ${TMC_NAMESPACE}
spec:
  operation: INSTALL
  registrationLink: "${TMC_MGMT_REGISTRATION_URL}"
xxEOFxx
