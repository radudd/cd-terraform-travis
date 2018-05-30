#!/bin/bash
# Deploy App to Dokku

export DOKKU_HOST=${DOKKU_HOST:-`cd terraform && terraform output public_dns`}

# Remote AWS keys. They are not necesarry anymore
rm -rf ~/.aws

if [[ -n $DOKKU_HOST ]]; then
    ssh-keyscan ${DOKKU_HOST} >> ~/.ssh/known_hosts
    git remote add dokku dokku@${DOKKU_HOST}:${APP_NAME}
    git fetch --unshallow 2>/dev/null
    count=0; until ssh -q -o StrictHostKeyChecking=no ${DOKKU_HOST} -l dokku ssh-keys:list || (( count++ >= 10 )) ; do 
      echo "[WARN] Dokku not ready ... please wait" && sleep 30
    done

    echo -n "[OK] Dokku is able to accept deployments now ..." && git push dokku master

    echo http://${DOKKU_HOST}:${TF_VAR_app_port}
  else echo "[ERROR] Dokku host not defined..."
    exit 99
fi

