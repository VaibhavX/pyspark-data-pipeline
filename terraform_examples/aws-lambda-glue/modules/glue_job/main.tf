

resource "aws_glue_job" "this" {
    name = var.job_name
    role_arn = var.role_arn

    command {
        name = var.job_type
        script_location = var.script_location
        python_version = var.python_version
    }

    max_capacity = var.max_capacity
}

