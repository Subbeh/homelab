terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.70.0"
    }
  }
  required_version = ">= 1.5.7"

  cloud {
    organization = "sbbh-cloud"
    workspaces {
      name = "aws-security-account"
    }
  }
}

# Security account provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "security"
      ManagedBy   = "terraform"
    }
  }
}

provider "tfe" {
  organization = var.tfe_organization
}
