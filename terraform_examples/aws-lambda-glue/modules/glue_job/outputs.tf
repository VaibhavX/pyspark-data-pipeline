
output "glue_job_name" {
    description = "Name of the Glue Job"
    value = aws_glue_job.this.name
}

output "glue_job_arn" {
    description = "ARN of the Glue Job"
    value = aws_glue_job.this.arn
}
