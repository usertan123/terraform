terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.24.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
#   access_key = "my-access-key"
#   secret_key = "my-secret-key"
  profile    = "new-user"
}