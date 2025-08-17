terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.68.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.5.7"

  cloud {
    organization = "sbbh-cloud"
    workspaces {
      name = "aws-organization"
    }
  }
}

# Management account provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "management"
      ManagedBy   = "terraform"
    }
  }
}

# Security account provider
provider "aws" {
  alias  = "security"
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::${module.security_account.account_id}:role/OrganizationAccountAccessRole"
  }
}

# Sandbox account provider
provider "aws" {
  alias  = "sandbox"
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::${module.sandbox_account.account_id}:role/OrganizationAccountAccessRole"
  }
}

# Production account provider
provider "aws" {
  alias  = "production"
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::${module.production_account.account_id}:role/OrganizationAccountAccessRole"
  }
}

provider "tfe" {
  organization = var.tfe_organization
}

