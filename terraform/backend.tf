terraform {
  backend "s3" {
    bucket = "tf-state"
    key    = "infra.tfstate"

    region                      = "ap-southeast-4"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
}
