variable "prefix" {
  description = "Optional prefix prepended to the generated pet name"
  type        = string
  default     = ""
}

variable "separator" {
  description = "Separator between words in the pet name"
  type        = string
  default     = "-"
}

variable "word_length" {
  description = "Number of words in the pet name"
  type        = number
  default     = 2
}

variable "suffix_bytes" {
  description = "Number of random bytes used for the hex suffix"
  type        = number
  default     = 2
}
