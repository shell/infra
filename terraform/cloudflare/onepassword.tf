# Secrets live in the 1Password "Homelab" vault (service account: forgejo-runner).
# Each item keeps its fields in a "terraform" section: the provider only
# exposes custom fields that belong to a section.

data "onepassword_vault" "homelab" {
  name = "Homelab"
}

# Ephemeral: only feeds the cloudflare provider block, never written to state
ephemeral "onepassword_item" "cloudflare_token" {
  vault = data.onepassword_vault.homelab.uuid
  title = "cloudflare-terraform-token"
}

# Regular data sources: these values are resource arguments, so they end up
# in state either way
data "onepassword_item" "cloudflare" {
  vault = data.onepassword_vault.homelab.uuid
  title = "cloudflare-terraform"
}

data "onepassword_item" "access_google" {
  vault = data.onepassword_vault.homelab.uuid
  title = "cloudflare-access-google"
}

locals {
  cf_fields     = data.onepassword_item.cloudflare.section_map["terraform"].field_map
  google_fields = data.onepassword_item.access_google.section_map["terraform"].field_map

  cloudflare_api_token = ephemeral.onepassword_item.cloudflare_token.section_map["terraform"].field_map["api_token"].value
  tunnel_secret        = local.cf_fields["tunnel_secret"].value
  google_client_id     = local.google_fields["client_id"].value
  google_client_secret = local.google_fields["client_secret"].value

  # The provider marks every field sensitive. These three were plain variables
  # before (and the IP is public DNS anyway); keep them readable in plans.
  cloudflare_account_id = nonsensitive(local.cf_fields["account_id"].value)
  vps_ip                = nonsensitive(local.cf_fields["vps_ip"].value)
  access_allowed_emails = nonsensitive(split(",", local.google_fields["allowed_emails"].value))
}
