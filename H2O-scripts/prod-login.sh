. ./config
. ../.secrets

kubectl vsphere login --insecure-skip-tls-verify --server ${SUPERVISOR} \
  --tanzu-kubernetes-cluster-namespace ${NAMESPACE} --tanzu-kubernetes-cluster-name ${PRODCLUSTERNAME} \
  -u administrator@vsphere.local
