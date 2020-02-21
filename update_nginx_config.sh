#!/bin/bash

export API_GATEWAY_URL=http://huya-live.mocklab.io/cdngw/backstreamurl
export REDIS_IP=10.150.216.116
export REDIRECT_CACHE_EXPIRE=60

envsubst '${API_GATEWAY_URL} ${REDIS_IP} ${REDIRECT_CACHE_EXPIRE}' < openresty/nginx/conf/nginx.conf > ~/nginx.conf
sudo cp -f ~/nginx.conf /usr/local/openresty/nginx/conf/
sudo systemctl reload openresty

