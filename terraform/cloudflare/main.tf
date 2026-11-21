terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket                      = "baleen-tf-state"
    key                         = "homelab/cloudflare/terraform.tfstate"
    region                      = "us-west-001"
    endpoints                   = { s3 = "https://s3.us-west-001.backblazeb2.com" }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
  rps       = 3
}
