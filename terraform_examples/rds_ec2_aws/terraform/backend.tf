# Configure the backend for Terraform using Local Backend
terraform {
  backend "local" {
      ### CHNAGE THE AWS ACCOUNT ID ###
    path = "/home/coder/.local/share/code-server/User/user-<AWS-ACCOUNT-ID>-us-east-1.state" # Path to the local state file
  }
}