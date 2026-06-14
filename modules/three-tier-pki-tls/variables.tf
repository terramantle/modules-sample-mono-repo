variable "org_name" {
  description = "Organization name used in every CA and leaf subject"
  type        = string
  default     = "Terramantle Demo"
}

variable "key_algorithm" {
  description = "Key algorithm for all keys in the chain: ECDSA, RSA, or ED25519"
  type        = string
  default     = "ECDSA"

  validation {
    condition     = contains(["ECDSA", "RSA", "ED25519"], var.key_algorithm)
    error_message = "key_algorithm must be one of ECDSA, RSA, ED25519."
  }
}

variable "ecdsa_curve" {
  description = "Curve used when key_algorithm is ECDSA"
  type        = string
  default     = "P384"
}

variable "rsa_bits" {
  description = "Key size in bits when key_algorithm is RSA"
  type        = number
  default     = 4096
}

variable "root_validity_hours" {
  description = "Root CA validity in hours (default 10 years)"
  type        = number
  default     = 87600
}

variable "intermediate_validity_hours" {
  description = "Intermediate CA validity in hours (default 5 years)"
  type        = number
  default     = 43800
}

variable "issuing_validity_hours" {
  description = "Issuing CA validity in hours (default 2 years)"
  type        = number
  default     = 17520
}

variable "leaf_validity_hours" {
  description = "Leaf (server) certificate validity in hours (default 90 days)"
  type        = number
  default     = 2160
}

variable "leaf_common_name" {
  description = "Common name for the leaf server certificate"
  type        = string
  default     = "service.demo.terramantle.dev"
}

variable "leaf_dns_names" {
  description = "Subject Alternative Names (DNS) for the leaf certificate"
  type        = list(string)
  default     = ["service.demo.terramantle.dev"]
}
