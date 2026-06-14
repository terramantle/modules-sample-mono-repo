# random-pet - a cloud-free demo module.
#
# Produces a friendly, unique name (e.g. "rolling-mantis-4f2a") with no cloud
# provider and no credentials. Applies instantly, so it is ideal for exercising
# the Terramantle state backend end to end without touching a cloud account.

resource "random_pet" "this" {
  length    = var.word_length
  separator = var.separator
  prefix    = var.prefix
}

resource "random_id" "suffix" {
  byte_length = var.suffix_bytes
}
