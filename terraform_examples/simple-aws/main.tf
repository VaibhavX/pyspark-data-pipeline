#provider block
provider "aws" {
    profile = "default"
    region = "us-east-1"
}


#Resources Block
#EC2 Instance
resource "aws_instance" "my_ec2_instance" {
    ami          = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
    instance_type = var.instance_type

    tags = {
        Name = var.instance_name
    }
}