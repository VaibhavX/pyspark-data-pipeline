# This file contains all the output values

output "instance_id" {
    description = "ID of the EC2 instance"
    value = aws_instance.my_ec2_instance.id
}

output "instance_public_ip" {
    description = "Public IP address of the EC2 instance"
    value = aws_instance.my_ec2_instance.public_ip
}

# You can view these outputs after running `terraform apply` using `terraform output` command