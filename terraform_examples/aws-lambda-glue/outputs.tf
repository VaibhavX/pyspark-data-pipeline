output "hello_lambda_arn" {
    value = module.lambda_hello.lambda_function_arn
}

output "data_processor_lambda_arn" {
    value = module.lambda_data_processor.lambda_function_arn
}

