# Public certificate material (safe to expose).

output "root_cert_pem" {
  description = "Tier 1 Root CA certificate (PEM)"
  value       = tls_self_signed_cert.root.cert_pem
}

output "intermediate_cert_pem" {
  description = "Tier 2 Intermediate CA certificate (PEM)"
  value       = tls_locally_signed_cert.intermediate.cert_pem
}

output "issuing_cert_pem" {
  description = "Tier 3 Issuing CA certificate (PEM)"
  value       = tls_locally_signed_cert.issuing.cert_pem
}

output "leaf_cert_pem" {
  description = "Leaf server certificate (PEM)"
  value       = tls_locally_signed_cert.leaf.cert_pem
}

# CA bundle: issuing + intermediate + root, in the order a client builds trust.
output "ca_bundle_pem" {
  description = "Concatenated CA chain (issuing -> intermediate -> root)"
  value = join("", [
    tls_locally_signed_cert.issuing.cert_pem,
    tls_locally_signed_cert.intermediate.cert_pem,
    tls_self_signed_cert.root.cert_pem,
  ])
}

# Full chain a server presents: leaf first, then the CA bundle.
output "full_chain_pem" {
  description = "Leaf certificate followed by the full CA chain"
  value = join("", [
    tls_locally_signed_cert.leaf.cert_pem,
    tls_locally_signed_cert.issuing.cert_pem,
    tls_locally_signed_cert.intermediate.cert_pem,
    tls_self_signed_cert.root.cert_pem,
  ])
}

# Private keys are stored in state regardless; mark them sensitive so they are
# not printed to CI logs. They are present on purpose for the state-scan demo.
output "leaf_private_key_pem" {
  description = "Leaf private key (sensitive - present in state for the scan demo)"
  value       = tls_private_key.leaf.private_key_pem
  sensitive   = true
}

output "issuing_private_key_pem" {
  description = "Issuing CA private key (sensitive - present in state for the scan demo)"
  value       = tls_private_key.issuing.private_key_pem
  sensitive   = true
}
