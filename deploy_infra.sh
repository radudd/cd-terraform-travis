#!/bin/bash
if [[ x"$DOKKU_HOST" == "x" ]]; then
  # Install Terraform
  curl -sSL https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip -o terraform.zip
  sudo unzip terraform.zip -d /usr/bin/
  rm terraform.zip
  
  # Apply Terraform deployment
  cd terraform
  terraform init || exit 99
  terraform plan || exit 99
  terraform apply -auto-approve || exit 99
  
  # Commit changes
  echo -n "[Git]: Configuring git user.name..." && echo "git config user.name $GIT_USERNAME" | tee /dev/stderr | bash
  echo -n "[Git]: Setting remote repository..." && echo "git remote add base $GIT_REPO" | tee /dev/stderr | bash
  echo -n "[Git]: Checking out master" && echo "git checkout master" | tee /dev/stderr | bash
  echo -n "[Git]: Add to staging..." && echo "git add ." | tee /dev/stderr | bash
  echo -n "[Git]: Commiting changes ..." && echo "git commit -am \"`date +%Y%m%d-%H%M`: Terraforming [ci skip]\"" | tee /dev/stderr | bash
  echo -n "[Git]: Pushing to remote repo..." && echo "git push base master" | tee /dev/stderr | bash
else echo -e "[WARN] A static Dokku server is already defined: ${DOKKU_HOST} \n [WARN] Terraform will not proceed!"
fi
