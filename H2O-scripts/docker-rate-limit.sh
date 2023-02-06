# create a registry secret to work around docker rate limit

if [ "$1" == "" ]
then
  echo "usage: ./docker-rate-limit.sh NAMESPACE"
  exit
fi

NAMESPACE="$1"

kubectl create secret docker-registry myregistrykey \
  --namespace=$NAMESPACE \
  --docker-server=docker.io \
  --docker-username=$DOCKERUSER \
  --docker-password="$DOCKERPASS"

kubectl patch serviceaccount default \
  -p '{"imagePullSecrets": [{"name": "myregistrykey"}]}' \
  -n $NAMESPACE
