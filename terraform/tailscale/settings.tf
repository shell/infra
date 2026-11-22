# Tailnet-wide settings, imported as they were live on 2026-11-21.
# The console's policy editor is locked: it shows the link below instead.
resource "tailscale_tailnet_settings" "this" {
  acls_externally_managed_on = true
  acls_external_link         = "https://git.sf.penk.in/vlad/infra/src/branch/main/terraform/tailscale/policy.hujson.tftpl"

  devices_approval_on            = true
  devices_auto_updates_on        = false
  devices_key_duration_days      = 180
  https_enabled                  = false
  network_flow_logging_on        = false
  posture_identity_collection_on = false
  # Two routers advertise the LAN: one active, the other takes over on failure
  route_selection                             = "active-passive-failover"
  users_approval_on                           = false
  users_role_allowed_to_join_external_tailnet = "admin"
}

import {
  to = tailscale_tailnet_settings.this
  id = "tailnet_settings"
}
