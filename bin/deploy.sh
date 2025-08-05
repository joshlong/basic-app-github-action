#!/usr/bin/env bash

set -e
set -o pipefail

create_ip(){
  ipn=$1
  if [ -z "$ipn" ]; then
    echo "you didn't specify the name of the IP address to create "
  else
    gcloud compute addresses list --format json | jq '.[].name' -r | grep $ipn || gcloud compute addresses create $ipn --global
    echo "working with the IP named ${ipn} "
  fi
}

write_secrets(){
  
  export SECRETS_NAME=${SERVICE}-secrets
  export SECRETS_FN=`pwd`/${SECRETS_NAME}.env
  
  SECRET_VARS=""
  
  IFS=',' read -ra KEY_ARRAY <<< "$ENV_KEYS"
  
  for key in "${KEY_ARRAY[@]}"; do
    value=$(eval echo \$${key})
    echo "${key}=${value}" >> $SECRETS_FN
  done

  kubectl delete secrets -n $NS $SECRETS_NAME || echo "no secrets to delete."
  kubectl create secret generic $SECRETS_NAME -n $NS --from-env-file $SECRETS_FN

}

get_image(){
  kubectl get "$1" -o json  | jq -r  ".spec.template.spec.containers[0].image" || echo "no old version to compare against"
}


gcloud config set project $GKE_PROJECT
gcloud auth configure-docker us-docker.pkg.dev --quiet
kubectl get ns/${NS} || kubectl create namespace ${NS}
kubectl config set-context --current --namespace=${NS}
kubectl get pods

write_secrets
cd $ROOT_DIR 

APP_YML=${ROOT_DIR}/bin/k8s/carvel/app-${SERVICE}-data.yml
$ROOT_DIR/bin/manifest_gen/main.py > ${APP_YML}

IP=${NS}-${SERVICE}-ip
create_ip $IP

D=deployments/${SERVICE}-deployment
OUT_YML=out.yml
ytt -f $APP_YML -f "$ROOT_DIR"/bin/k8s/carvel/data-schema.yml -f "$ROOT_DIR"/bin/k8s/carvel/deployment.yml |  kbld -f -  > ${OUT_YML}

cat ${OUT_YML} | kubectl apply  -n ${NS} -f -

echo "--------------------------"
echo "Final Kubernetes YAML:"
echo "--------------------------"
cat ${OUT_YML}
echo "--------------------------"

