# Tailnet policy file (hosts, tags, grants, SSH, tests). Edit policy.hujson.tftpl:
# the admin console's editor is locked (settings.tf).
# Tailscale runs the "tests" section on every save and rejects a policy that fails them.
resource "tailscale_acl" "policy" {
  acl = templatefile("${path.module}/policy.hujson.tftpl", { users = local.ts_users })
}

# Imported from the live tailnet 2026-11-21
import {
  to = tailscale_acl.policy
  id = "acl"
}
