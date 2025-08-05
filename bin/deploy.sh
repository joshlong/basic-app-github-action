#!/usr/bin/env bash

set -e
set -o pipefail

create_ip(){
  ipn=$1
  if [ -z "$ipn" ]; then
    echo "you didn't specify the name of the IP address to create "
  else
    gcloud compute addresses list --format json | jq '.[].name' -r | grep $ipn || gcloud compute addresses create $ipn --global
  fi
}

write_secrets(){
  
  export SECRETS_NAME=${SERVICE}-secrets.env
  export SECRETS_FN=`pwd`/${SECRETS_NAME}
  
  SECRET_VARS=""
  
  IFS=',' read -ra KEY_ARRAY <<< "$ENV_KEYS"
  
  for key in "${KEY_ARRAY[@]}"; do
    value=$(eval echo \$${key})
    # SECRET_VARS+="${key}=${value}\n"
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

APP_YML=${ROOT_DIR}/bin/k8s/carvel/app-app-data.yml
$ROOT_DIR/bin/manifest_gen/main.py > ${APP_YML}


for f in app ; do
  IP=${NS}-${f}-ip
  Y=${ROOT_DIR}/bin/k8s/carvel/app-${f}-data.yml
  D=deployments/${f}-deployment
  OUT_YML=out.yml
  ytt -f $Y -f "$ROOT_DIR"/bin/k8s/carvel/data-schema.yml -f "$ROOT_DIR"/bin/k8s/carvel/deployment.yml |  kbld -f -  > ${OUT_YML}

  cat ${OUT_YML} | kubectl apply  -n ${NS} -f -

  echo "--------------------------"
  echo "Final Kubernetes YAML:"
  echo "--------------------------"
  cat ${OUT_YML}
  echo "--------------------------"

  # NEW_IMAGE=`get_image $D`
  # echo "comparing container images for the first container!"
  # echo $OLD_IMAGE
  # echo $NEW_IMAGE
  # if [ "$OLD_IMAGE" = "$NEW_IMAGE" ]; then
    # echo "no need to restart $D"
  # else
   # echo "restarting $D"
   # kubectl rollout restart $D
  # fi

done


