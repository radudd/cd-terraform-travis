#!/bin/bash
# Deploy App to Dokku

export DOKKU_HOST=${DOKKU_HOST:-`cd terraform && terraform output public_dns`}
if [[ -n $DOKKU_HOST ]]; then
    ssh-keyscan ${DOKKU_HOST} >> ~/.ssh/known_hosts
    git remote add dokku dokku@${DOKKU_HOST}:${APP_NAME}
    git fetch --unshallow
    until ssh -q -o StrictHostKeyChecking=no ${DOKKU_HOST} -l dokku ssh-keys:list; do echo "[WARN] Dokku not ready ... please wait" && sleep 30; done; git push dokku master
    echo http://${DOKKU_HOST}:${APP_PORT}
  else echo "[ERROR] Dokku host not defined..."
    exit 99
fi
