terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.29.0"
    }

    null = {
      source = "hashicorp/null"
      version = "3.2.2"
    }

  }
}

provider "aws" {
  # Configuration options
  region                   = "eu-north-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "devopsU"

}