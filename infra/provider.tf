terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "my-terraform-state-bucket-ahmad-2026"
    key     = "terraform.tfstate"
    region  = "ap-southeast-2"
  }
}

variable "use_localstack" {
  type    = bool
  default = true
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

locals {
  ls = "http://localhost:4566"
}

provider "aws" {
  region = var.aws_region

  # القيم التالية لـ LocalStack فقط، وعلى AWS تُترك لسلسلة بيانات الاعتماد الحقيقية
  access_key                  = var.use_localstack ? "test" : null
  secret_key                  = var.use_localstack ? "test" : null
  skip_credentials_validation = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  s3_use_path_style           = var.use_localstack

  dynamic "endpoints" {
    for_each = var.use_localstack ? [1] : []
    content {
      dynamodb = local.ls
      sqs      = local.ls
      lambda   = local.ls
      iam      = local.ls
      sts      = local.ls
      s3       = local.ls
    }
  }
}