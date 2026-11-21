variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "zone_id" {
  description = "Cloudflare zone ID"
  type        = string
  default     = "58c9b190951f16693081984b12d63835"
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID (Account Home sidebar in the dashboard)"
  type        = string
}

variable "tunnel_secret" {
  description = "Random 32+ byte base64 secret for the cloudflared tunnel"
  type        = string
  sensitive   = true
}

variable "google_client_id" {
  description = "OAuth 2.0 Client ID from Google Cloud Console"
  type        = string
  sensitive   = true
}

variable "google_client_secret" {
  description = "OAuth 2.0 Client secret from Google Cloud Console"
  type        = string
  sensitive   = true
}

variable "access_allowed_emails" {
  description = "Emails allowed through the Cloudflare Access policy for the k8s dashboards"
  type        = list(string)
}
variable "vps_ip" {
  description = "Public IPv4 of the Hostinger VPS (srv1517572)"
  type        = string
}
