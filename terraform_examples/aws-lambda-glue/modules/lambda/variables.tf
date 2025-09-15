variable "function_name" {
    description = "Lambda function name"
    type = string
}

variable "handler" {
    description = "Lambda function handler"
    type = string
    default = "lamnda_function.lambda_handler"
}

variable "runtime" {
    description = "Lambda runtime"
    type = string
    default = "python3.12"
}

variable "timeout" {
    description = "Lambda timeout in seconds"
    type = number
    default = 60
}

variable "lambda_zip_path" {
    description = "Path to the Lambda deployment package zip file"
    type = string
}

variable "attach_policies" {
    description = "Additional policy ARNs to attach to Lambda role"
    type = list(string)
    default = []
}
  
