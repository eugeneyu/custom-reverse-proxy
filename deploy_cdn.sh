#!/bin/bash

# Nginx conf settings
# For basic CDN deployment with nginx_basic_proxy.conf, only CDN_CACHE_EXPIRE and ORIGIN_URL need to be updated before deploying.
export NGINX_TEMPLATE=https://raw.githubusercontent.com/eugeneyu/custom-reverse-proxy/master/openresty/nginx/conf/nginx_basic_proxy.conf
export CDN_CACHE_EXPIRE=604800
export ORIGIN_URL=https://www.google.com
export API_GATEWAY_URL=http://huya-live.mocklab.io/cdngw/backstreamurl
export REDIS_IP=10.150.216.116
export REDIRECT_CACHE_EXPIRE=60

# gcloud command settings
export PROJECT_ID=youzhi-lab
export BASE_INSTANCE_NAME=google-cdn-proxy-base
export IMAGE_NAME=google-cdn-proxy-base-image
export INSTANCE_TEMPLATE_NAME=google-cdn-proxy-ig-temp-v1
export HEALTHCHECK_NAME=healthckeck-google-cdn-proxy
export INSTANCE_GROUP_NAME=ig-google-cdn-proxy
export BACKEND_NAME=bs-google-cdn-proxy
export URLMAP_NAME=glb-google-cdn
export TARGET_PROXY_NAME=target-google-cdn-proxy
export FORWARD_RULE_NAME=forward-rule-google-cdn-proxy
export REGION=asia-east2
export ZONE=asia-east2-a
export INSTANCE_GROUP_ZONES=asia-east2-a,asia-east2-b,asia-east2-c

# 1. Create base VM, with openresty installed
gcloud beta compute --project=$PROJECT_ID instances create $BASE_INSTANCE_NAME --zone=$ZONE --machine-type=n1-standard-1 --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE --tags=cdn-proxy,http-server,https-server --image=ubuntu-1804-bionic-v20200129a --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=$BASE_INSTANCE_NAME --reservation-affinity=any --metadata=startup-script=wget\ -O\ -\ https://raw.githubusercontent.com/eugeneyu/custom-reverse-proxy/master/openresty/gce_startup.sh\ \|\ bash
sleep 60
	
# 2. Create custom Image
gcloud compute images create $IMAGE_NAME --project=$PROJECT_ID --source-disk=$BASE_INSTANCE_NAME --source-disk-zone=$ZONE --storage-location=$REGION --force
	
# 3. Create instance template

gcloud beta compute --project=$PROJECT_ID instance-templates create $INSTANCE_TEMPLATE_NAME --machine-type=n1-standard-4 --network-tier=PREMIUM --maintenance-policy=MIGRATE --tags=cdn-proxy,http-server,https-server --image=$IMAGE_NAME --image-project=$PROJECT_ID --boot-disk-size=100GB --boot-disk-type=pd-standard --boot-disk-device-name=$INSTANCE_TEMPLATE_NAME --reservation-affinity=any --metadata=startup-script="#! /bin/bash
export ORIGIN_URL=${ORIGIN_URL}
export CDN_CACHE_EXPIRE=${CDN_CACHE_EXPIRE}
export API_GATEWAY_URL=${API_GATEWAY_URL}
export REDIS_IP=${REDIS_IP}
export REDIRECT_CACHE_EXPIRE=${REDIRECT_CACHE_EXPIRE}
wget $NGINX_TEMPLATE --output-document=nginx.conf
cp /usr/local/openresty/nginx/conf/nginx.conf /usr/local/openresty/nginx/conf/nginx_def.conf
envsubst '\${ORIGIN_URL} \${CDN_CACHE_EXPIRE} \${API_GATEWAY_URL} \${REDIS_IP} \${REDIRECT_CACHE_EXPIRE}' < ./nginx.conf > /usr/local/openresty/nginx/conf/nginx.conf
systemctl restart openresty"

# 4. Create Instance Group

gcloud compute health-checks create http $HEALTHCHECK_NAME --project=$PROJECT_ID --port=80 --request-path=/ --proxy-header=NONE --check-interval=5 --timeout=5 --unhealthy-threshold=2 --healthy-threshold=2

gcloud beta compute --project=$PROJECT_ID instance-groups managed create $INSTANCE_GROUP_NAME --base-instance-name=$INSTANCE_GROUP_NAME --template=$INSTANCE_TEMPLATE_NAME --size=1 --zones=$INSTANCE_GROUP_ZONES --instance-redistribution-type=PROACTIVE --health-check=$HEALTHCHECK_NAME --initial-delay=60

gcloud beta compute --project "$PROJECT_ID" instance-groups managed set-autoscaling "$INSTANCE_GROUP_NAME" --region "$REGION" --cool-down-period "60" --max-num-replicas "10" --min-num-replicas "1" --target-cpu-utilization "0.6" --mode "on"


# 5. Create LB

gcloud compute backend-services create $BACKEND_NAME \
--protocol HTTP \
--health-checks $HEALTHCHECK_NAME \
--global \
--enable-cdn \
--timeout=60

gcloud compute backend-services add-backend $BACKEND_NAME \
--balancing-mode=UTILIZATION \
--max-utilization=0.8 \
--capacity-scaler=1 \
--instance-group=$INSTANCE_GROUP_NAME \
--instance-group-region=$REGION \
--global

gcloud compute url-maps create $URLMAP_NAME \
--default-service $BACKEND_NAME

gcloud compute target-http-proxies create $TARGET_PROXY_NAME \
--url-map $URLMAP_NAME 

gcloud compute forwarding-rules create $FORWARD_RULE_NAME \
--global \
--target-http-proxy=$TARGET_PROXY_NAME \
--ports=80
