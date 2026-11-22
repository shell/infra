terraform {
  # >= 1.10 for ephemeral resources (onepassword.tf)
  required_version = ">= 1.10"

  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.14"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.4"
    }
  }

  # State lives in baleen-tf-state, which this root also manages (buckets.tf).
  # prevent_destroy on that bucket keeps the backend from being deleted under us.
  backend "s3" {
    bucket                      = "baleen-tf-state"
    key                         = "homelab/b2/terraform.tfstate"
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

provider "b2" {
  application_key_id = local.b2_application_key_id
  application_key    = local.b2_application_key
}
