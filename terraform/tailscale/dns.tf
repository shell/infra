# Tailnet DNS: MagicDNS on, homelab zones resolved by Pi-hole (LXC 198)
# through the 192.168.10.0/24 subnet route (ts-router or ts-router-nuc,
# active-passive failover; see settings.tf). Everything else uses
# each device's own DNS (no global nameservers, override_local_dns off).
resource "tailscale_dns_configuration" "tailnet" {
  magic_dns = true

  split_dns {
    domain = "k8s.home"
    nameservers {
      address = "192.168.10.198"
    }
  }

  split_dns {
    domain = "sf.penk.in"
    nameservers {
      address = "192.168.10.198"
    }
  }
}

import {
  to = tailscale_dns_configuration.tailnet
  id = "dns_configuration"
}
