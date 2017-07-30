#!/bin/bash -eu

eval "$(jq -r '@sh "SWARM_MANAGER_IP=\(.swarm_manager_ip)"')"

WORKER_JOIN_TOKEN=$(ssh -i ../ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${SWARM_MANAGER_IP} docker swarm join-token worker -q)

jq -n --arg worker_join_token ${WORKER_JOIN_TOKEN} '{ "worker_join_token" : $worker_join_token }'
