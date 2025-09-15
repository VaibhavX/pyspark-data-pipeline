#Core Resources

#IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
    name = "${var.function_name}_exec_role"
    
    assume_role_policy = jsonencode({
        Version = "20012-10-17",
        Statement = [
            {
                Action = "sts:AssumeRole",
                Effect = "Allow",
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}


#Attach AWS basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
    role = aws_iam_role.lambda_exec_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#Attach optional extra policy
resource "aws_iam_role_policy_attachment" "extra_policies" {
    for_each = toset(var.attach_policies)
    role = aws_iam_role.lambda_exec_role.name
    policy_arn = each.value
}

#Lambda Function
resource "aws_lambda_function" "this" {
    function_name = var.function_name
    role = aws_iam_role.lambda_exec_role.arn
    handler = var.handler
    runtime = var.runtime
    filename = var.lambda_zip_path
    source_code_hash = filebase64sha256(var.lambda_zip_path)
}