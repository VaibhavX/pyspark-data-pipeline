
output "lambda_function_name" {
    description = "Lambda function name"
    value = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
    description = "Lambda function ARN"
    value = aws_lambda_function.this.arn
}

output "execution_role_arn" {
    description = "Execution role ARN"
    value = aws_iam_role.lambda_exec_role.arn
}