provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = local.default_tags
  }
}

terraform {
  required_version = ">= 1.4.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}