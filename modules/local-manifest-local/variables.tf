variable "app_name" {
  description = "Application name written into the manifest"
  type        = string
  default     = "demo-app"
}

variable "environment" {
  description = "Environment label written into the manifest"
  type        = string
  default     = "sandbox"
}

variable "metadata" {
  description = "Arbitrary key/value metadata merged into the manifest"
  type        = map(string)
  default     = {}
}

variable "output_path" {
  description = "Path the rendered manifest is written to"
  type        = string
  default     = "manifest.json"
}
