# Approved (enabled) subnet routes and exit nodes. The device still has to
# advertise a route (tailscale set --advertise-routes / --advertise-exit-node)
# before it takes effect; this only approves it.
locals {
  exit_node = ["0.0.0.0/0", "::/0"]
  lan       = "192.168.10.0/24"

  # Device name (first label of its MagicDNS name) => approved routes
  approved_routes = {
    "ts-router"     = concat(local.exit_node, [local.lan])
    "ts-router-nuc" = concat(local.exit_node, [local.lan])
    "zima-msk"      = local.exit_node
    "zima-rov"      = local.exit_node
    "srv1517572"    = local.exit_node # Hostinger VPS
  }

  # Hostnames aren't unique (both ZimaBoards report "casaos"), MagicDNS names are
  devices = { for d in data.tailscale_devices.all.devices : split(".", d.name)[0] => d }
}

data "tailscale_devices" "all" {}

resource "tailscale_device_subnet_routes" "this" {
  for_each = local.approved_routes

  device_id = local.devices[each.key].node_id
  routes    = each.value
}

import {
  for_each = local.approved_routes
  to       = tailscale_device_subnet_routes.this[each.key]
  id       = local.devices[each.key].node_id
}
