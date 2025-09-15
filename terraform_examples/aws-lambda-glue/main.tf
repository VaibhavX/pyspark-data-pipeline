module "lambda_hello" {
    source = "./modules/lambda"
    function_name = "hello_lambda"
    handler = "lambda_function.lambda_handler"
    runtime = "python3.12"
    lambda_zip_path = "./lambda/hello_lambda.zip"
}


module "lambda_data_processor" {
    source = "./modules/lambda"
    function_name = "data_processor_lambda"
    handler = "processor.main"
    runtime = "python3.12"
    lambda_zip_path = "./lambda/processor_payload.zip"
    timeout = 120
    attach_policies = [
        "arn:aws:iam:aws:policy/AmazonS3ReadOnlyAccess"
    ]
}

#Glue Job module
#First, create IAM role for Glue
resource "aws_iam_role" "glue_role" {
    name = "glue_service_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Service = "glue.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "glue_service_policy" {
    role = aws_iam_role.glue_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

module "glue_job" {
    source = "./modules/glue_job"
    job_name = "example_glue_job"
    role_arn = aws_iam_role.glue_role.arn
    job_type = "glueetl"
    script_location = "s3://my-glue-scripts-bucket/scripts/my_glue_script.py"
    python_version = "3"
}
