terraform {
  backend "s3" {
    bucket         = "tfstate-personal"
    region         = "us-west-1"
    dynamodb_table = "tfstate-personal"
    key            = "fillout-test.tfstate"
  }
}