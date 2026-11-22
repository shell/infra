terraform {
  # >= 1.10 for ephemeral resources (onepassword.tf)
  required_version = ">= 1.10"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.4"
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

# Auth from the environment: OP_SERVICE_ACCOUNT_TOKEN (CI, or local),
# or OP_ACCOUNT for 1Password desktop-app sign-in on the Mac.
provider "onepassword" {}

provider "cloudflare" {
  api_token = local.cloudflare_api_token
  rps       = 3
}
