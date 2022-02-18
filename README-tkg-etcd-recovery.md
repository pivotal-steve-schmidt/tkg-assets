# Recovering etcd on TKG

Fri 18 Feb 2022 18:41:44 CET / schmidtst@vmware.com

1. Create a backup of the etcd data
2. Restore the etcd data - on the same cluster, or a new one
3. Troubleshooting
4. Manifest etcd.yaml

Based on research and finally on this blog post:
https://itnext.io/breaking-down-and-fixing-etcd-cluster-d81e35b9260d

## Creating a backup of the etcd data

We will first connect to the jump host and from there login to the control plane.
On the control plane we will setup the etcdcl command to perform a snapshot.

Once the snapshot is taken, it could be copied to a secure location, but this is not part
of this document.

### Connecting to the jump host

Login to the system where you deployed the management cluster (e.g. jump host)

`ssh steve@ubuntu-206.haas-206.pez.pivotal.io`

`kubectl config get-contexts`

``` 
CURRENT   NAME                                      CLUSTER            AUTHINFO                 NAMESPACE 
          tkg-mgmt-man-admin@tkg-mgmt-man           tkg-mgmt-man       tkg-mgmt-man-admin       
*         tkg-cl-2-admin@tkg-cl-2                   tkg-cl-2           tkg-cl-2-admin 
```

Set context to the workload cluster you want to backup and recover later on

`kubectl config use-context tkg-cl-2-admin@tkg-cl-2`

Assuming you have a cluster with a single control plane node.
Set the IP Address to the control plane node IP.

`export CP_IP=$(kubectl get nodes -o wide | grep control | awk '{print $7}')`

NOTE: You can also use the kube-vip IP of the control plane from the kubeconfig file.

### Login to the control plane

`ssh -i .ssh/id_rsa capv@$CP_IP`

Get the container ID for etcd

`CONTAINER_ID=$(sudo crictl ps -a --label io.kubernetes.container.name=etcd --label io.kubernetes.pod.namespace=kube-system | awk 'NR>1{r=$1} $0~/Running/{exit} END{print r}')`

Set an alias to run the etcdctl command within this container

`alias etcdctl='sudo crictl exec "$CONTAINER_ID" etcdctl --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert /etc/kubernetes/pki/etcd/ca.crt'`

Retrieve the name and endpoints

`etcdctl member list`

```
d5fa7bb933c66ca6, started, tkg-cl-2-control-plane-2whkx, https://10.195.71.209:2380, https://10.195.71.209:2379, false
```
`export NODE_NAME=$(etcdctl member list | awk -F, '{print $3}')`
`export ETCD_URL=$(etcdctl member list | awk -F, '{print $4}')`

Create a backup of the etcd data. The directory /var/lib/etcd is accessible from withtin the container and from the outside.
See the manifest "/etc/kubernetes/manifests/etcd.yaml".

`etcdctl snapshot save /var/lib/etcd/snap1.db`

```
{"level":"info","ts":1645178450.3360484,"caller":"snapshot/v3_snapshot.go:119","msg":"created temporary db file","path":"/var/lib/etcd/snap1.db.part"}
{"level":"info","ts":"2022-02-18T10:00:50.344Z","caller":"clientv3/maintenance.go:200","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":1645178450.3448164,"caller":"snapshot/v3_snapshot.go:127","msg":"fetching snapshot","endpoint":"127.0.0.1:2379"}
{"level":"info","ts":"2022-02-18T10:00:50.456Z","caller":"clientv3/maintenance.go:208","msg":"completed snapshot read; closing"}
Snapshot saved at /var/lib/etcd/snap1.db
{"level":"info","ts":1645178450.46341,"caller":"snapshot/v3_snapshot.go:142","msg":"fetched snapshot","endpoint":"127.0.0.1:2379","size":"8.2 MB","took":0.125041931}
{"level":"info","ts":1645178450.4635258,"caller":"snapshot/v3_snapshot.go:152","msg":"saved","path":"/var/lib/etcd/snap1.db"}
```

Now the backup is available on the control plane. 
To protect against loss of the data on the control plane node, copy the file to a safe location.
Take note of the NODE_NAME and the ETCD_URL in case you want to set them to the values at time of backup.

## Restoring the backup

Login in again to the control plane node (see previous section).
Make sure that NODE_NAME and ETCD_URL are set to the desired values.

`CONTAINER_ID=$(sudo crictl ps -a --label io.kubernetes.container.name=etcd --label io.kubernetes.pod.namespace=kube-system | awk 'NR>1{r=$1} $0~/Running/{exit} END{print r}')`

`alias etcdctl='sudo crictl exec "$CONTAINER_ID" etcdctl --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert /etc/kubernetes/pki/etcd/ca.crt'`

`export NODE_NAME=$(etcdctl member list | awk -F, '{print $3}')`

`export ETCD_URL=$(etcdctl member list | awk -F, '{print $4}')`

`etcdctl snapshot restore /var/lib/etcd/snap1.db --data-dir=/var/lib/etcd/restore --name=${NODE_NAME} --initial-advertise-peer-urls=${ETCD_URL} --initial-cluster=${NODE_NAME}=${ETCD_URL}`

Example with variable expansion: etcdctl snapshot restore /var/lib/etcd/snap1.db --data-dir=/var/lib/etcd/restore --name=tkg-cl-2-control-plane-2whkx --initial-advertise-peer-urls=https://10.195.71.209:2380 --initial-cluster=tkg-cl-2-control-plane-2whkx=https://10.195.71.209:2380

```
ial-advertise-peer-urls=https://10.195.71.209:2380 --initial-cluster=tkg-cl-2-control-plane-2whkx=https://10.195.71.209:2380
{"level":"info","ts":1645179154.9172177,"caller":"snapshot/v3_snapshot.go:296","msg":"restoring snapshot","path":"/var/lib/etcd/snap1.db","wal-dir":"/var/lib/etcd/restore/member/wal","data-dir":"/var/lib/etcd/restore","snap-dir":"/var/lib/etcd/restore/member/snap"}
{"level":"info","ts":1645179154.9688592,"caller":"mvcc/kvstore.go:380","msg":"restored last compact revision","meta-bucket-name":"meta","meta-bucket-name-key":"finishedCompactRev","restored-compact-revision":10921}
{"level":"info","ts":1645179155.0572793,"caller":"membership/cluster.go:392","msg":"added member","cluster-id":"d24656eadd799e5f","local-member-id":"0","added-peer-id":"d5fa7bb933c66ca6","added-peer-peer-urls":["https://10.195.71.209:2380"]}
{"level":"info","ts":1645179155.0596738,"caller":"snapshot/v3_snapshot.go:309","msg":"restored snapshot","path":"/var/lib/etcd/snap1.db","wal-dir":"/var/lib/etcd/restore/member/wal","data-dir":"/var/lib/etcd/restore","snap-dir":"/var/lib/etcd/restore/member/snap"}
```

### Stopping etcd and starting with the recovered data

Move the etcd yaml to the current working directory. This will also stop the etcd container.

`sudo mv /etc/kubernetes/manifests/etcd.yaml .`

Now move the old content away and replace with the restored values.

`sudo mv /var/lib/etcd/member /var/lib/etcd/member.old && sudo mv /var/lib/etcd/restore/member /var/lib/etcd`

Copy the etcd yaml back in place.

`sudo cp etcd.yaml /etc/kubernetes/manifests/etcd.yaml`

Verify the etcd pod is running again.

`sudo crictl ps`

Note that the other system pods will also restart

```
CONTAINER           IMAGE               CREATED             STATE               NAME                               ATTEMPT             POD ID
7eb783c69939c       913ad1cc80ba0       2 minutes ago       Running             vsphere-cloud-controller-manager   2                   5fed10fba2c6c
2d1d31fc72401       6f7c29e5ac889       2 minutes ago       Running             etcd                               0                   ec21f86b38b0f
3b38ada587565       640b7ee0df98b       2 minutes ago       Running             kube-scheduler                     4                   1d1f2ea290da3
fde7405d7ca20       060eb69223237       2 minutes ago       Running             kube-controller-manager            4                   e1cbf63ccb793
8134ab4634f6e       6fdd0d6f6ccc7       2 minutes ago       Running             csi-provisioner                    1                   5d7f179c2d4fd
125b9bb43443b       e4729de44ddc0       2 minutes ago       Running             vsphere-syncer                     1                   5d7f179c2d4fd
b248927d41ddd       ca62a14e6d5e6       2 minutes ago       Running             csi-resizer                        1                   5d7f179c2d4fd
812fe0f1fab98       dbc8dd3a5329d       2 minutes ago       Running             csi-attacher                       1                   5d7f179c2d4fd
8c8b391cca853       05d7f1f146f50       2 minutes ago       Running             kube-vip                           3                   0c7bd41549d90
fed315fea9e8e       bc959b6bc3eb2       5 hours ago         Running             manager                            0                   c53dbc799c44a
4451be5750430       b0c779cd83001       5 hours ago         Running             antrea-controller                  0                   38d94642c2af9
80534aa1c8f7a       c9265e1ac0f2c       5 hours ago         Running             coredns                            0                   6598fe735c871
189d5d0545173       0076b17e8c71c       5 hours ago         Running             kapp-controller                    1                   a68d47c339966
55d6895d8af1f       9d61c59dc968e       5 hours ago         Running             liveness-probe                     0                   5d7f179c2d4fd
e2bf7c4a04bbb       bcc0b4d6c920b       5 hours ago         Running             vsphere-csi-controller             0                   5d7f179c2d4fd
dbbecd3e084e7       c9265e1ac0f2c       5 hours ago         Running             coredns                            0                   3640d520aaa5c
61f05d6f8c3d5       b0c779cd83001       5 hours ago         Running             antrea-ovs                         0                   7a41c8e9a4a60
3c9bdce08c0b7       b0c779cd83001       5 hours ago         Running             antrea-agent                       0                   7a41c8e9a4a60
d8af10e3d24b7       9d61c59dc968e       5 hours ago         Running             liveness-probe                     0                   5dfba6a4ed893
024a653c1121c       bcc0b4d6c920b       5 hours ago         Running             vsphere-csi-node                   0                   5dfba6a4ed893
b6e81d3b006f1       2ec91df31da7d       5 hours ago         Running             node-driver-registrar              0                   5dfba6a4ed893
f89d2e7ce9033       2eaab091566a9       5 hours ago         Running             kube-proxy                         0                   4659c1d8d3816
d5a72df18949d       0b9437b832f65       5 hours ago         Running             kube-apiserver                     2                   a0f43ee93e73e
```

Also check the pods

`sudo crictl pods`

```
POD ID              CREATED             STATE               NAME                                                     NAMESPACE           ATTEMPT             RUNTIME
c53dbc799c44a       4 hours ago         Ready               tanzu-capabilities-controller-manager-76c54b97b5-fjdmp   tkg-system          0                   (default)
38d94642c2af9       4 hours ago         Ready               antrea-controller-7d5d4d7d74-b8mlp                       kube-system         0                   (default)
6598fe735c871       4 hours ago         Ready               coredns-8dcb5c56b-rk8xg                                  kube-system         0                   (default)
3640d520aaa5c       4 hours ago         Ready               coredns-8dcb5c56b-j5nlt                                  kube-system         2                   (default)
5d7f179c2d4fd       4 hours ago         Ready               vsphere-csi-controller-cbd954fd-pl7j9                    kube-system         0                   (default)
5fed10fba2c6c       4 hours ago         Ready               vsphere-cloud-controller-manager-tsq2w                   kube-system         0                   (default)
5dfba6a4ed893       4 hours ago         Ready               vsphere-csi-node-klhpd                                   kube-system         0                   (default)
a68d47c339966       4 hours ago         Ready               kapp-controller-df65ccc8b-k5lnz                          tkg-system          0                   (default)
7a41c8e9a4a60       4 hours ago         Ready               antrea-agent-pjkvv                                       kube-system         0                   (default)
4659c1d8d3816       4 hours ago         Ready               kube-proxy-8z6mn                                         kube-system         0                   (default)
a0f43ee93e73e       6 hours ago         Ready               kube-apiserver-tkg-cl-2-control-plane-2whkx              kube-system         0                   (default)
e1cbf63ccb793       6 hours ago         Ready               kube-controller-manager-tkg-cl-2-control-plane-2whkx     kube-system         0                   (default)
0c7bd41549d90       6 hours ago         Ready               kube-vip-tkg-cl-2-control-plane-2whkx                    kube-system         0                   (default)
1d1f2ea290da3       6 hours ago         Ready               kube-scheduler-tkg-cl-2-control-plane-2whkx              kube-system         0                   (default)
dea30ee2446b8       6 hours ago         Ready               etcd-tkg-cl-2-control-plane-2whkx                        kube-system         0                   (default)
```

### Verify
Set the new container id and query etcd

`CONTAINER_ID=$(sudo crictl ps -a --label io.kubernetes.container.name=etcd --label io.kubernetes.pod.namespace=kube-system | awk 'NR>1{r=$1} $0~/Running/{exit} END{print r}')`
`alias etcdctl='sudo crictl exec "$CONTAINER_ID" etcdctl --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert /etc/kubernetes/pki/etcd/ca.crt'`
`etcdctl member list`

```
d5fa7bb933c66ca6, started, tkg-cl-2-control-plane-2whkx, https://10.195.71.209:2380, https://10.195.71.209:2379, false
```

If all looks fine here, logout and verify from the outside.
Exit from the control plane.

`exit`

On the jump host

`kubectl get all -A`

NOTE: It might take some time for all the objects to restart.
Be patient and troubleshoot if some pods are not in the state running.

## Troubleshooting

I had the case where two vsphere-csi-controller pods were present. One Ready the other NotReady. 

`sudo crictl pods`

```
POD ID              CREATED             STATE               NAME                                                     NAMESPACE           ATTEMPT             RUNTIME
c53dbc799c44a       4 hours ago         Ready               tanzu-capabilities-controller-manager-76c54b97b5-fjdmp   tkg-system          0                   (default)
...
5d7f179c2d4fd       4 hours ago         Ready               vsphere-csi-controller-cbd954fd-pl7j9                    kube-system         0                   (default)
2d1debb35208b       4 hours ago         NotReady            vsphere-csi-controller-cbd954fd-vxs82                    kube-system         1                   (default)
...
dea30ee2446b8       6 hours ago         Ready               etcd-tkg-cl-2-control-plane-2whkx                        kube-system         0                   (default)
```

In this situation I removed the "NotReady" pod with. Notice the error returned. However the command succeded and the NotReady pod was gone.

`sudo crictl rmp 2d1debb35208b`

```
getting sandbox status of pod "2d1debb35208b": rpc error: code = NotFound desc = an error occurred when try to find sandbox: not found
```

## Manifest for etcd

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/etcd.advertise-client-urls: https://10.195.71.209:2379
  creationTimestamp: null
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
  containers:
  - command:
    - etcd
    - --advertise-client-urls=https://10.195.71.209:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt
    - --cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_25
6_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd
    - --initial-advertise-peer-urls=https://10.195.71.209:2380
    - --initial-cluster=tkg-cl-2-control-plane-2whkx=https://10.195.71.209:2380
    - --key-file=/etc/kubernetes/pki/etcd/server.key
    - --listen-client-urls=https://127.0.0.1:2379,https://10.195.71.209:2379
    - --listen-metrics-urls=http://127.0.0.1:2381
    - --listen-peer-urls=https://10.195.71.209:2380
    - --name=tkg-cl-2-control-plane-2whkx
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    - --snapshot-count=10000
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    image: projects.registry.vmware.com/tkg/etcd:v3.4.13_vmware.15
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /health
        port: 2381
        scheme: HTTP
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    name: etcd
    resources:
      requests:
        cpu: 100m
        memory: 100Mi
    startupProbe:
      failureThreshold: 48
      httpGet:
        host: 127.0.0.1
        path: /health
        port: 2381
        scheme: HTTP
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /var/lib/etcd
      name: etcd-data
    - mountPath: /etc/kubernetes/pki/etcd
      name: etcd-certs
  hostNetwork: true
  priorityClassName: system-node-critical
  volumes:
  - hostPath:
      path: /etc/kubernetes/pki/etcd
      type: DirectoryOrCreate
    name: etcd-certs
  - hostPath:
      path: /var/lib/etcd
      type: DirectoryOrCreate
    name: etcd-data
status: {}
```
