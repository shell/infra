# Secrets (API token, tunnel secret, OAuth client, allowed emails, VPS IP)
# come from 1Password: see onepassword.tf.

variable "zone_id" {
  description = "Cloudflare zone ID"
  type        = string
  default     = "58c9b190951f16693081984b12d63835"
}
