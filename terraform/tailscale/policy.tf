# Tailnet policy file (ACLs, grants, SSH, tests). Edit policy.hujson.tftpl,
# not the admin console: the next apply overwrites console edits.
# Tailscale runs the "tests" section on every save and rejects a policy that fails them.
resource "tailscale_acl" "policy" {
  acl = templatefile("${path.module}/policy.hujson.tftpl", { users = local.ts_users })
}

# Imported from the live tailnet 2026-11-21
import {
  to = tailscale_acl.policy
  id = "acl"
}
