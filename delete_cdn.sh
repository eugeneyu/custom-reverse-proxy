#!/bin/bash

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

gcloud compute forwarding-rules delete $FORWARD_RULE_NAME --global --quiet

gcloud compute target-http-proxies delete $TARGET_PROXY_NAME --quiet

gcloud compute url-maps delete $URLMAP_NAME --quiet

gcloud compute backend-services delete $BACKEND_NAME --global --quiet

gcloud beta compute --project=$PROJECT_ID instance-groups managed delete $INSTANCE_GROUP_NAME --region=$REGION --quiet

gcloud compute health-checks delete http $HEALTHCHECK_NAME --project=$PROJECT_ID --quiet

gcloud beta compute --project=$PROJECT_ID instance-templates delete $INSTANCE_TEMPLATE_NAME --quiet

gcloud compute images delete $IMAGE_NAME --project=$PROJECT_ID --quiet


gcloud beta compute --project=$PROJECT_ID instances delete $BASE_INSTANCE_NAME --zone=$ZONE --quiet
