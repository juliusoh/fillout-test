data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  lambda_arch = "arm64"
}

variable "name" {
  description = "The name of the lambda function"
  type        = string
  default     = "fillout-test"
}

variable "region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-west-1"
}