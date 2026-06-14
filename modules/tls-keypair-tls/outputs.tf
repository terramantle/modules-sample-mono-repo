output "public_key_pem" {
  description = "PEM-encoded public key"
  value       = tls_private_key.this.public_key_pem
}

output "public_key_openssh" {
  description = "OpenSSH-formatted public key"
  value       = tls_private_key.this.public_key_openssh
}

output "cert_pem" {
  description = "PEM-encoded self-signed certificate"
  value       = tls_self_signed_cert.this.cert_pem
}

# Deliberately sensitive: surfacing the private key is what gives the state
# scanner something to find. Marked sensitive so it is not printed to CI logs.
output "private_key_pem" {
  description = "PEM-encoded private key (sensitive - present in state for the scan demo)"
  value       = tls_private_key.this.private_key_pem
  sensitive   = true
}
