#!/bin/bash

kubectl create deployment hello-server \
    --image=us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0

  # securityContext:
    # runAsUser: 1000
    # runAsGroup: 3000
    # fsGroup: 2000

# uncomment for direct LB expose
# kubectl expose deployment hello-server --type LoadBalancer --port 80 --target-port 8080

# uncomment for ingress expose, uses nodeport for svc
#  prereqs: contour
#  change: hosname in hello-ingress.yaml
kubectl expose deployment hello-server --port 80 --target-port 8080
kubectl apply -f hello-ingress.yaml
curl -v -H "Host: hello.h2o-4-2395.h2o.vmware.com" http://10.220.10.5


# uncomment for ingress with tls
#  prereqs: contour, cert-manager
#  change: hosname in hello-ingress.yaml
kubectl expose deployment hello-server --port 80 --target-port 8080
kubectl apply -f hello-cert-yaml
kubectl apply -f hello-ingress-tls.yaml
curl -v -H "Host: hello.h2o-4-2395.h2o.vmware.com" https://10.220.10.5
