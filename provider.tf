terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# تكوين المزود (Provider) ليعمل مع LocalStack محلياً
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # توجيه خدمة S3 إلى LocalStack بدل خوادم AWS الحقيقية
  endpoints {
    s3 = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sqs = "http://localhost:4566" 
    iam = "http://localhost:4566" 
    lambda = "http://localhost:4566" 
  }
}
