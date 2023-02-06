# psp:vmware-system-privileged
# psp:vmware-system-restricted
kubectl create clusterrolebinding psp:authenticated --clusterrole=psp:vmware-system-restricted --group=system:authenticated
