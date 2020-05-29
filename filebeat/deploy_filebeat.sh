#! /bin/bash

# Before execution, set up environment variables
# export ES_USER=eugeneyu
# export ES_PASSWORD=abc

curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.7.0-amd64.deb
sudo dpkg -i filebeat-7.7.0-amd64.deb

sudo filebeat modules enable nginx

envsubst '${ES_USER} ${ES_PASSWORD}' < ./filebeat.yml > /etc/filebeat/filebeat.yml

sudo service filebeat start