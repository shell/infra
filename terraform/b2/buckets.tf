# Homelab buckets in the B2 account
# Not managed here: personal buckets (managed in the B2 web UI) and B2's own
# "snapshot" bucket that the web UI creates for snapshot downloads.
#
# Every bucket has prevent_destroy: they hold data that Terraform can't recreate.

# Terraform state backend for every root in terraform/ (this one included)
resource "b2_bucket" "baleen_tf_state" {
  bucket_name = "baleen-tf-state"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Longhorn backup target (k8s/infrastructure/base/longhorn/release.yaml)
resource "b2_bucket" "xiky_homelab_backup" {
  bucket_name = "xiky-homelab-backup"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Proxmox Backup Server datastore (docs/proxmox-backup.md)
resource "b2_bucket" "pve_nuc_pbs" {
  bucket_name = "pve-nuc-pbs"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    algorithm = "AES256"
    mode      = "SSE-B2"
  }

  # "Keep only the last version": chunks removed by PBS garbage collection
  # must really be deleted, or the bucket never shrinks
  lifecycle_rules {
    file_name_prefix             = ""
    days_from_hiding_to_deleting = 1
  }

  lifecycle {
    prevent_destroy = true
  }
}
