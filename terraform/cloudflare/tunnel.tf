resource "cloudflare_zero_trust_tunnel_cloudflared" "k8s_dashboards" {
  account_id = local.cloudflare_account_id
  name       = "dell-optiplex-k8s"
  secret     = local.tunnel_secret
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "k8s_dashboards" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.k8s_dashboards.id

  config {
    ingress_rule {
      hostname = "headlamp.penk.in"
      service  = "http://my-headlamp.kube-system.svc.cluster.local:80"
    }
    ingress_rule {
      hostname = "maptoposter.penk.in"
      service  = "http://maptoposter-web.apps.svc.cluster.local:5000"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_record" "headlamp_tunnel" {
  zone_id = var.zone_id
  name    = "headlamp"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.k8s_dashboards.id}.cfargotunnel.com"
  proxied = true
}

resource "cloudflare_record" "maptoposter_tunnel" {
  zone_id = var.zone_id
  name    = "maptoposter"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.k8s_dashboards.id}.cfargotunnel.com"
  proxied = true
}

output "tunnel_token" {
  value     = cloudflare_zero_trust_tunnel_cloudflared.k8s_dashboards.tunnel_token
  sensitive = true
}
