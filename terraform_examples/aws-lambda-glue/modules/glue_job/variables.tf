variable "job_name" {
    description = "Name of the Glue job"
    type = string
}

variable "script_location"{
    description = "S3 path to the Glue script"
    type = string
    default = ""
}

variable "role_arn" {
    description = "IAM Role ARN for the Glue job"
    type = string
    default = "glue-role"
}

variable "job_type" {
    description = "Type of GLue job: 'pythonshell' or 'glueetl'"
    type = string
    default = "pythonshell"
}

variable "python_version" {
    description = "Python version for the Glue job (2 or 3)"
    type = string
    default = "3"
}

variable "max_capacity" {
    description = "Maximum capacity for the Glue job data processing units (DPUs)"
    type = number
    default = 2
}