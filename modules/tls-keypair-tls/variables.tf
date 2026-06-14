variable "algorithm" {
  description = "Key algorithm: ED25519, ECDSA, or RSA"
  type        = string
  default     = "ED25519"

  validation {
    condition     = contains(["ED25519", "ECDSA", "RSA"], var.algorithm)
    error_message = "algorithm must be one of ED25519, ECDSA, RSA."
  }
}

variable "ecdsa_curve" {
  description = "Curve used when algorithm is ECDSA"
  type        = string
  default     = "P256"
}

variable "rsa_bits" {
  description = "Key size in bits when algorithm is RSA"
  type        = number
  default     = 2048
}

variable "common_name" {
  description = "Certificate subject common name"
  type        = string
  default     = "demo.terramantle.dev"
}

variable "organization" {
  description = "Certificate subject organization"
  type        = string
  default     = "Terramantle Demo"
}

variable "validity_period_hours" {
  description = "How long the self-signed cert is valid, in hours"
  type        = number
  default     = 8760
}

variable "allowed_uses" {
  description = "Allowed key uses for the certificate"
  type        = list(string)
  default     = ["key_encipherment", "digital_signature", "server_auth"]
}
