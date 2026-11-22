resource "cloudflare_record" "terraform_managed_resource_04670919a4e64b2183f68f100a359073_0" {
  content = local.vps_ip
  name    = "penk.in"
  proxied = true
  ttl     = 1
  type    = "A"
  zone_id = "58c9b190951f16693081984b12d63835"
}

resource "cloudflare_record" "terraform_managed_resource_c139fb84b0b209ac980d328b3ee11f44_4" {
  comment = "SF Homelab"
  content = "192.168.10.141"
  name    = "*.sf"
  proxied = false
  ttl     = 300
  type    = "A"
  zone_id = "58c9b190951f16693081984b12d63835"
}

resource "cloudflare_record" "terraform_managed_resource_f976558874d70ef469baa2bccb55752f_9" {
  content = "fm1.penk.in.dkim.fmhosted.com"
  name    = "fm1._domainkey"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "58c9b190951f16693081984b12d63835"
}

resource "cloudflare_record" "terraform_managed_resource_d946111a9c89b0ec528ce8743ac57015_10" {
  content = "fm2.penk.in.dkim.fmhosted.com"
  name    = "fm2._domainkey"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "58c9b190951f16693081984b12d63835"
}

resource "cloudflare_record" "terraform_managed_resource_d9b67b518c845f8a763a6e6b153ed9af_11" {
  content = "fm3.penk.in.dkim.fmhosted.com"
  name    = "fm3._domainkey"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "58c9b190951f16693081984b12d63835"
}

resource "cloudflare_record" "terraform_managed_resource_e23cb3edbeda4f0aef771f5ac9eee48c_13" {
  content = "penk.in"
  name    = "www"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  zone_id = "58c9b190951f16693081984b12d63835"
}

resource "cloudflare_record" "terraform_managed_resource_bbf0e6e1756a8dd79d3676636615592f_14" {
  content  = "in2-smtp.messagingengine.com"
  name     = "penk.in"
  priority = 20
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = "58c9b190951f16693081984b12d63835"
}

resource "cloudflare_record" "terraform_managed_resource_1f90f4bf2c01b5bdbf92116d9f1aae3e_15" {
  content  = "in1-smtp.messagingengine.com"
  name     = "penk.in"
  priority = 10
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = "58c9b190951f16693081984b12d63835"
}

resource "cloudflare_record" "terraform_managed_resource_bda2e6b5fe9488a1c858c74c8d5d9dbe_20" {
  content = "v=DMARC1; p=none; rua=mailto:penkinv@gmail.com"
  name    = "_dmarc"
  proxied = false
  ttl     = 1
  type    = "TXT"
  zone_id = "58c9b190951f16693081984b12d63835"
}

resource "cloudflare_record" "terraform_managed_resource_1b770ee617f29d1a79ee35a3cc0c87ca_23" {
  content = "v=spf1 include:spf.messagingengine.com ?all"
  name    = "penk.in"
  proxied = false
  ttl     = 1
  type    = "TXT"
  zone_id = "58c9b190951f16693081984b12d63835"
}

resource "cloudflare_record" "meet_penkin" {
  comment = "Jitsi Meet on Hostinger VPS"
  content = local.vps_ip
  name    = "meet"
  proxied = false
  ttl     = 300
  type    = "A"
  zone_id = var.zone_id
}

resource "cloudflare_record" "umami_penkin" {
  comment = "Umami analytics on Hostinger VPS"
  content = local.vps_ip
  name    = "umami"
  proxied = true
  ttl     = 1
  type    = "A"
  zone_id = var.zone_id
}

resource "cloudflare_record" "france_guide_penkin" {
  comment = "France guide on Hostinger VPS"
  content = local.vps_ip
  name    = "france-guide"
  proxied = true
  ttl     = 1
  type    = "A"
  zone_id = var.zone_id
}

resource "cloudflare_record" "penk_in_preview" {
  comment = "penk.in preview on Hostinger VPS"
  content = local.vps_ip
  name    = "new"
  proxied = true
  ttl     = 1
  type    = "A"
  zone_id = var.zone_id
}
