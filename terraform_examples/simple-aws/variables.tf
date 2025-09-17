variable "instance_name" {
    description = "Value of the Name tag for the EC2 instance"
    type = string
    default = "MyEC2Instance"
}

variable "instance_type" {
    description = "Type of EC2 instance"
    type = string
    default = "t2.micro"
}

# if you dont have default value, you must provide a value when running terraform apply like below
# terraform apply -var="instance_type=t3.micro"
# Better approach is to create a terraform.tfvars file and define the variable values there