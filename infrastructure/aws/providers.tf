# CloudFront only accepts ACM certificates from us-east-1, so the whole stack
# lives there.
provider "aws" {
  region  = "us-east-1"
  profile = var.aws_profile

  default_tags {
    tags = var.tags
  }
}
