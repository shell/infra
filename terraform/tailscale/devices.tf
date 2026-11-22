# Infrastructure devices: function tags (see tagOwners in policy.hujson.tftpl)
# and key expiry off, so an always-on node never silently drops off the tailnet.
# Tagged devices are owned by their tags, not a user: they get no access of
# their own, only what the policy grants to people reaching them.
locals {
  # Device name (first label of its MagicDNS name) => tags
  device_tags = {
    "ts-router"     = ["tag:exit-node", "tag:router"]
    "ts-router-nuc" = ["tag:exit-node", "tag:router"]
    "zima-msk"      = ["tag:exit-node"]
    "zima-rov"      = ["tag:exit-node"]
    "srv1517572"    = ["tag:exit-node", "tag:relay"]
  }
}

resource "tailscale_device_tags" "this" {
  for_each = local.device_tags

  device_id = local.devices[each.key].node_id
  tags      = each.value

  # The tags must be defined in tagOwners before a device can carry them
  depends_on = [tailscale_acl.policy]
}

resource "tailscale_device_key" "this" {
  for_each = local.device_tags

  device_id           = local.devices[each.key].node_id
  key_expiry_disabled = true
}

# srv1517572 was already tagged (tag:relay) before Terraform
import {
  to = tailscale_device_tags.this["srv1517572"]
  id = local.devices["srv1517572"].node_id
}

import {
  for_each = local.device_tags
  to       = tailscale_device_key.this[each.key]
  id       = local.devices[each.key].node_id
}
