resource "cloudflare_zero_trust_access_identity_provider" "google" {
  account_id = local.cloudflare_account_id
  name       = "Google"
  type       = "google"

  config {
    client_id     = local.google_client_id
    client_secret = local.google_client_secret
  }
}

resource "cloudflare_zero_trust_access_policy" "allowed_household" {
  account_id = local.cloudflare_account_id
  name       = "allowed household emails"
  decision   = "allow"

  include {
    email = local.access_allowed_emails
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_zero_trust_access_application" "headlamp" {
  account_id                = local.cloudflare_account_id
  name                      = "Headlamp"
  domain                    = "headlamp.penk.in"
  type                      = "self_hosted"
  session_duration          = "24h"
  auto_redirect_to_identity = true
  allowed_idps              = [cloudflare_zero_trust_access_identity_provider.google.id]

  policies = [cloudflare_zero_trust_access_policy.allowed_household.id]
}
