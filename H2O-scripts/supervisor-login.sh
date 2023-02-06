. ./config           # configure SUPERVISOR=wcp.haas-###.pez.vmware.com
. ./.secrets        # create and populate with KUBECTL_VSPHERE_PASSWORD=
kubectl vsphere login --insecure-skip-tls-verify --server ${SUPERVISOR} -u administrator@vsphere.local
