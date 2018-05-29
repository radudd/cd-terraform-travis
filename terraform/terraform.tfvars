# The default setup OS user. For Ubuntu on AWS the user is ubuntu
remote_user = "ubuntu"
# The region in AWS where the EC2 instance will be deployed
region = "eu-west-1"
# The list of the source IPs allowed to access the EC2 instance. Default: unrestricted access
cidr_blocks = ["0.0.0.0/0"]
# Path to SSH public key to be used for EC2 instance and for the Dokku application
public_key_path = "../.ssh/aws_terraform.pub"
# Dokku version to be installed
dokku_version = "v0.12.7"
