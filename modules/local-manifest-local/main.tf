# local-manifest - a cloud-free demo module.
#
# Renders a small JSON manifest (with a random release id) to a local file. The
# rendered content is also stored in state, so this stack contributes ordinary
# non-secret data for the state scanner to walk.

resource "random_string" "release_id" {
  length  = 8
  special = false
  upper   = false
}

locals {
  manifest = {
    app         = var.app_name
    environment = var.environment
    release_id  = random_string.release_id.result
    metadata    = var.metadata
  }
}

resource "local_file" "manifest" {
  filename        = var.output_path
  content         = jsonencode(local.manifest)
  file_permission = "0644"
}
