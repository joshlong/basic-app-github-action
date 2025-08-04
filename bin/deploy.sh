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
  
  export SECRETS=${APP_NAME}-secrets.env
  export SECRETS_FN=`pwd`/${SECRETS}
  
  echo "going to create ${SECRETS} secrets in the $NS namespace."

  # get each  of the keys passed to the plugin and use them to resolve 
  # the value and write them to a k8s secrets object
  
  SECRET_VARS=""
  
  IFS=',' read -ra KEY_ARRAY <<< "$ENV_KEYS"
  
  for key in "${KEY_ARRAY[@]}"; do
    value=$(eval echo \$${key})
    # SECRET_VARS+="${key}=${value}\n"
    echo "${key}=${value}" >> $SECRETS_FN
  done

  
  cat $SECRETS_FN

  kubectl delete secrets -n $NS $SECRETS || echo "no secrets to delete."
  kubectl create secret generic $SECRETS -n $NS --from-env-file $SECRETS_FN

}

get_image(){
  kubectl get "$1" -o json  | jq -r  ".spec.template.spec.containers[0].image" || echo "no old version to compare against"
}

echo "the namespace is $NS"
echo "the action path is ${ROOT_DIR}"

gcloud config set project $GKE_PROJECT
gcloud --quiet auth configure-docker
gcloud auth configure-docker us-docker.pkg.dev --quiet
kubectl get ns/${NS} || kubectl create namespace ${NS}
kubectl config set-context --current --namespace=${NS}
kubectl get pods

write_secrets
echo $ROOT_DIR
ls -la $ROOT_DIR
cd $ROOT_DIR/k8s/carvel/
python3 -c'print "hello"' 

# # MAIN APPS
# # and there are a bunch of apps we needs to deploy and they all share a similar setup
# for f in mogul-service mogul-gateway mogul-client ; do
  
#   echo "------------------"

#   IP=${NAMESPACE_NAME}-${f}-ip
#   echo "creating IP called ${IP} "
#   create_ip $IP
#   echo "created IP called ${IP} "
#   Y=app-${f}-data.yml
#   D=deployments/${f}-deployment
#   OLD_IMAGE=`get_image $D `
#   OUT_YML=out.yml
#   ytt -f $Y -f "$ROOT_DIR"/k8s/carvel/data-schema.yml -f "$ROOT_DIR"/k8s/carvel/deployment.yml |  kbld -f -  > ${OUT_YML}
#   cat ${OUT_YML}
#   cat ${OUT_YML} | kubectl apply  -n $NAMESPACE_NAME -f -
#   NEW_IMAGE=`get_image $D`
#   echo "comparing container images for the first container!"
#   echo $OLD_IMAGE
#   echo $NEW_IMAGE
#   if [ "$OLD_IMAGE" = "$NEW_IMAGE" ]; then
#     echo "no need to restart $D"
#   else
#    echo "restarting $D"
#    kubectl rollout restart $D
#   fi

# done


cd "$ROOT_DIR"
