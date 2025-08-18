data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "role_access_policy" {
  statement {
    sid     = "AllowS3Access"
    effect  = "Allow"
    actions = [
      "s3:List*",
      "s3:Get*"
    ]
    resources = [
      "arn:aws:s3:::<SOURCE_LOCATION>",
      "arn:aws:s3:::<SOURCE_LOCATION>/*"
    ]
  }
}