# tls-keypair - a cloud-free demo module that DELIBERATELY writes secret
# material into Terraform state.
#
# The generated private key is stored verbatim in state (Terraform always does
# this for tls_private_key). When this state is pushed to Terramantle, the
# trufflehog scanner should flag the embedded private key. That is the point:
# this module exists to demonstrate state-scanning finding a real secret.

resource "tls_private_key" "this" {
  algorithm   = var.algorithm
  ecdsa_curve = var.algorithm == "ECDSA" ? var.ecdsa_curve : null
  rsa_bits    = var.algorithm == "RSA" ? var.rsa_bits : null
}

resource "tls_self_signed_cert" "this" {
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name  = var.common_name
    organization = var.organization
  }

  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.allowed_uses
}
