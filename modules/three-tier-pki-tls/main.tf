# three-tier-pki - a cloud-free demo module that builds a full three-tier
# certificate authority chain entirely with the `tls` provider:
#
#   Tier 1  Root CA          (self-signed, long-lived, offline-style)
#   Tier 2  Intermediate CA  (signed by the Root)
#   Tier 3  Issuing CA       (signed by the Intermediate)
#   Leaf    Server cert      (issued by the Issuing CA)
#
# Every CA private key is stored verbatim in Terraform state, so this is also a
# rich target for state-scanning: pushing the consuming stack's state to
# Terramantle should have trufflehog flag THREE CA private keys plus the leaf
# key. That is intentional - it shows the scanner walking a realistic, layered
# secret structure rather than a single key.

# ─────────────────────────────────────────────────────────────────────────────
# Tier 1 - Root CA (self-signed)
# ─────────────────────────────────────────────────────────────────────────────
resource "tls_private_key" "root" {
  algorithm   = var.key_algorithm
  ecdsa_curve = var.key_algorithm == "ECDSA" ? var.ecdsa_curve : null
  rsa_bits    = var.key_algorithm == "RSA" ? var.rsa_bits : null
}

resource "tls_self_signed_cert" "root" {
  private_key_pem = tls_private_key.root.private_key_pem

  subject {
    common_name  = "${var.org_name} Root CA"
    organization = var.org_name
  }

  is_ca_certificate     = true
  validity_period_hours = var.root_validity_hours
  set_subject_key_id    = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Tier 2 - Intermediate CA (signed by Root)
# ─────────────────────────────────────────────────────────────────────────────
resource "tls_private_key" "intermediate" {
  algorithm   = var.key_algorithm
  ecdsa_curve = var.key_algorithm == "ECDSA" ? var.ecdsa_curve : null
  rsa_bits    = var.key_algorithm == "RSA" ? var.rsa_bits : null
}

resource "tls_cert_request" "intermediate" {
  private_key_pem = tls_private_key.intermediate.private_key_pem

  subject {
    common_name  = "${var.org_name} Intermediate CA"
    organization = var.org_name
  }
}

resource "tls_locally_signed_cert" "intermediate" {
  cert_request_pem   = tls_cert_request.intermediate.cert_request_pem
  ca_private_key_pem = tls_private_key.root.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root.cert_pem

  is_ca_certificate     = true
  validity_period_hours = var.intermediate_validity_hours
  set_subject_key_id    = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Tier 3 - Issuing CA (signed by Intermediate)
# ─────────────────────────────────────────────────────────────────────────────
resource "tls_private_key" "issuing" {
  algorithm   = var.key_algorithm
  ecdsa_curve = var.key_algorithm == "ECDSA" ? var.ecdsa_curve : null
  rsa_bits    = var.key_algorithm == "RSA" ? var.rsa_bits : null
}

resource "tls_cert_request" "issuing" {
  private_key_pem = tls_private_key.issuing.private_key_pem

  subject {
    common_name  = "${var.org_name} Issuing CA"
    organization = var.org_name
  }
}

resource "tls_locally_signed_cert" "issuing" {
  cert_request_pem   = tls_cert_request.issuing.cert_request_pem
  ca_private_key_pem = tls_private_key.intermediate.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.intermediate.cert_pem

  is_ca_certificate     = true
  validity_period_hours = var.issuing_validity_hours
  set_subject_key_id    = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Leaf - server certificate issued by the Issuing CA
# ─────────────────────────────────────────────────────────────────────────────
resource "tls_private_key" "leaf" {
  algorithm   = var.key_algorithm
  ecdsa_curve = var.key_algorithm == "ECDSA" ? var.ecdsa_curve : null
  rsa_bits    = var.key_algorithm == "RSA" ? var.rsa_bits : null
}

resource "tls_cert_request" "leaf" {
  private_key_pem = tls_private_key.leaf.private_key_pem

  subject {
    common_name  = var.leaf_common_name
    organization = var.org_name
  }

  dns_names = var.leaf_dns_names
}

resource "tls_locally_signed_cert" "leaf" {
  cert_request_pem   = tls_cert_request.leaf.cert_request_pem
  ca_private_key_pem = tls_private_key.issuing.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.issuing.cert_pem

  validity_period_hours = var.leaf_validity_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
