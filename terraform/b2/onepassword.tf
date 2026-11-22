# Secrets live in the 1Password "Homelab" vault (service account: forgejo-runner).
# The item keeps its fields in a "terraform" section: the provider only
# exposes custom fields that belong to a section.
#
# Item "b2-terraform", section "terraform":
#   application_key_id, application_key
# B2 key: all buckets, with at least listBuckets, readBuckets, writeBuckets, readBucketEncryption, writeBucketEncryption, readBucketRetentions, writeBucketRetentions, readBucketReplications, writeBucketReplications, readBucketLifecycleRules, writeBucketLifecycleRules
# The web UI can't pick capabilities; create it with the CLI:
#   b2 key create <name> <comma-separated capabilities>
# (Not the state-backend key: homelab-tf-runner is scoped to baleen-tf-state.)

data "onepassword_vault" "homelab" {
  name = "Homelab"
}

# Ephemeral: only feeds the b2 provider block, never written to state
ephemeral "onepassword_item" "b2" {
  vault = data.onepassword_vault.homelab.uuid
  title = "b2-terraform"
}

locals {
  b2_fields = ephemeral.onepassword_item.b2.section_map["terraform"].field_map

  b2_application_key_id = local.b2_fields["application_key_id"].value
  b2_application_key    = local.b2_fields["application_key"].value
}
