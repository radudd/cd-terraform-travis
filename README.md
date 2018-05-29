# Build a CD Pipeline with TravisCI, Dokku, AWS and Terraform (for a Node.js application)

There are basically two approches: complete automated deployment(including infrastructure creation with Terraform) and separate infrastructure and application deployments.

## Use cases
- Complete automated deployment: Dynamic infrastructure which runs on demand. Travis CI will check and deploy the required infrastructure with Terraform (if not already present). After it will deploy the application to Dokku using a Dockerfile
- Separate deployments for infrastructure and application: Infrastructure is static and doesn't need to be often redeployed. In this case, infrastructure will be deployed at the beginning of the process with Terraform and the CD pipeline will contain just the application deployment to Dokku as a Dockerfile

## Requirements
- Travis CLI https://github.com/travis-ci/travis.rb

- Terraform https://releases.hashicorp.com/terraform *(Only if using static infrastructure and Terraform is used to deploy it initially)*

## Create and encrypt your access keys
After checking out the repository, you need to create a tarball containing both your AWS access keys and your ssh-keypair. Copy your ~/.aws folder to the checked out repo and generate a new ssh-keypair
```shell
cp -pR ~/.aws .
mkdir .ssh && ssh-keygen -q -f .ssh/aws_terraform -C aws_terraform_ssh_key -N '' 
```
Compress them in a tarball
```shell
tar cvf aws.tar .aws .ssh
```
Encrypt them using Travis CLI
```shell
travis login    # Your GitHub credentials
travis encrypt-file aws.tar --add
```
This will encrypt aws.tar file (generating aws.tar.enc file) with a symmetric encryption using a key kept secure in your Travis account.
Now you can safely delete the .aws, .ssh folders and aws.tar file. Anyway, if you still want to use Terraform locally, don't delete the .ssh folder. It will not be commited to remote repository since is specified in .gitignore.

## Authorize your public ssh key to your GitHub account
Terraform will require write access to the remote repo to push the tfstate files. We will use the same ssh key as for the Dokku server and application. https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/

## Update .travis.yml
Another thing which needs to be done is to update the environemnt variables from  *(.travis.yml)* file
```
  # The name that Dokku will use for your application
  - APP_NAME="sample-node-app"
  # Port on which your application is running
  - TF_VAR_app_port=3000
  # Git username to be used by the commits from Travis CI build servers
  - GIT_USERNAME="Travis CI"
  # Your own GitHub repository for which you want to achieve CD
  - GIT_REPO="git@github.com:radudd/travis-cd"
  # This is important. Keep this variable undefined, if you want TravisCI to run Terraform to deploy your infrastructure. Otherwise, define your static EC2 instance here and TravisCI will skip Terraform deployment
  - DOKKU_HOST=""
```

## Ready to test
That's all, now commit your changes and push them to your repository. 
Dont't forget that if you want to run Terraform locally you'll need to have the ssh keys in the .ssh folder in repository home and to export the TF_VAR_app_port variable

## Relevant files
- *terraform/main.tf*
This is the main Terraform configuration file. It will create a Security Group, a ssh public key based on the ssh key you provided at the previous step and an EC2 instance based on Ubuntu 16.04. The EC2 instance will use a cloud-init script, defined by the commands in the user_data section in order to install and configure Dokku. *(An additional improvment for this workflow would be to create a custom AMI with Dokku already preinstalled and use this AMI-ID for the later deployments)*
- *terraform/terraform.tfvars*
This is used to parametrize the main.tf file. Feel free to update it if necessary.
- *deploy_infra.sh*
A script that contains all the steps required for Travis CI to deploy the AWS infrastructure. Additionally this script commits the new *(terraform.tfstate)* files to the remote repository. If DOKKU_HOST is defined with a static hostname, this script will not run.
- *deploy_app.sh*
Script for deploying the Node.js application to Dokku using the Dockerfile.
- *Dockerfile*
*(Customized for Node.js)*. This is needed to deploy your application as a Docker container instead as with buildpacks. If Dokku detects a Dockerfile in the repo and there is no BUILDPACK_URL variable set its config set, nor a .buildpacks file present, then Dokku deploys according to the Dockerfile.
- *.travis.yml*
*(Customized for Node.js)*. Here is defined the CD pipeline. Don't forget to update the environment variables from global section. The first line of the *before_install* section is populated by travis --encrypt-file filename --add. After the file is decrypted it is untared and the components are copied to the correct location. Additionally the ssh agent is started and the your private key is added to it.
There are two steps in the *deploy* phase: one to create the AWS infrastructure and the other to deploy the application to Dokku.
- *.gitignore*
- *aws.tar.enc*

## Improvments that could be considered
Following improvements could be considered:
- Extend Terraform by creating an ELB and a DNS entry
- Create a custom AMI with Dokku already installed
- Dokku: use virtual hosts  
```shell
dokku add-global domain.name
``` 
