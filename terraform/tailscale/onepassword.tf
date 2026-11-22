# Secrets live in the 1Password "Homelab" vault (service account: forgejo-runner).
# Items keep their fields in a "terraform" section: the provider only
# exposes custom fields that belong to a section.
#
# Item "tailscale-terraform", section "terraform": oauth_client_id, oauth_client_secret
#   OAuth client: admin console -> Settings -> Trust credentials -> OAuth, scopes:
#   Policy File: write, DNS: write, Devices Core: write, Devices Routes: write,
#   Feature Settings: write; client tag: tag:terraform. A client can only apply
#   tags its own tags own, so tagOwners in policy.hujson.tftpl lists tag:terraform
#   as an owner of every function tag.
#
# Item "tailscale-users", section "terraform": one field per tailnet user,
#   <name> = login email, used as ${users.<name>} in policy.hujson.tftpl.
#   The repo is public, so emails stay out of the code. Not ephemeral: the
#   rendered policy (with the emails) is stored in state anyway. Keep no
#   secrets in this item, they would land in state too.

data "onepassword_vault" "homelab" {
  name = "Homelab"
}

# Ephemeral: only feeds the provider block, never written to state
ephemeral "onepassword_item" "tailscale" {
  vault = data.onepassword_vault.homelab.uuid
  title = "tailscale-terraform"
}

data "onepassword_item" "tailscale_users" {
  vault = data.onepassword_vault.homelab.uuid
  title = "tailscale-users"
}

locals {
  ts_fields = ephemeral.onepassword_item.tailscale.section_map["terraform"].field_map

  ts_oauth_client_id     = local.ts_fields["oauth_client_id"].value
  ts_oauth_client_secret = local.ts_fields["oauth_client_secret"].value

  ts_users = {
    for k, f in data.onepassword_item.tailscale_users.section_map["terraform"].field_map : k => f.value
  }
}
