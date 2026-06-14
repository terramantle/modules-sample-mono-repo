variable "url" {
  description = "URL to fetch. Its response body is stored in state."
  type        = string
  default     = "https://httpbin.org/ip"
}

variable "request_headers" {
  description = "Optional headers to send with the request"
  type        = map(string)
  default = {
    Accept = "application/json"
  }
}

variable "request_timeout_ms" {
  description = "Per-request timeout in milliseconds"
  type        = number
  default     = 5000
}

variable "retry_attempts" {
  description = "Number of retry attempts if the request fails (keeps a flaky echo host off the critical path)"
  type        = number
  default     = 3
}
