#!/bin/bash

# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# chmod 700 get_helm.sh
# ./get_helm.sh

# helm repo add bitnami https://charts.bitnami.com/bitnami

. ./config

# kubectl apply -f ./tanzu2-storageclass.yaml
kubectl create ns ${BLOGNS}
helm install ${BLOGNS} --set persistence.storageClass=$APPSTORAGECLASS \
	--set global.storageClass=$APPSTORAGECLASS bitnami/wordpress \
	--set wordpressBlogName="${CUSTOMERNAME}" \
	-n ${BLOGNS}

echo "To re-display this info: $ helm status ${BLOGNS} -n ${BLOGNS}"
