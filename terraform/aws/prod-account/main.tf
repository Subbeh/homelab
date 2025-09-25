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
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.7"

  cloud {
    organization = "sbbh-cloud"
    workspaces {
      name = "aws-prod-account"
    }
  }
}

# Production account provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}

provider "tfe" {
  organization = var.tfe_organization
}

provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
}
