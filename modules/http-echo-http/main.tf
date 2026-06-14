# http-echo - a cloud-free demo module that fetches an external URL and echoes
# the response into Terraform state (mirrors the tf-test/main.tf pattern).
#
# The response body lands in state, which means any URLs / IPs it contains are
# visible to Terramantle's endpoint_scan. Pointed at httpbin.org/ip by default,
# the state ends up carrying your egress IP - exactly the kind of exposed
# endpoint the scanner is built to surface.

data "http" "echo" {
  url = var.url

  request_headers = var.request_headers

  # The default echo host (httpbin.org) is a flaky community service. Without a
  # timeout + retry, an outage there would fail every apply on the consuming
  # stack and could leave a state lock held. Keep the external dependency off
  # the critical path as much as the provider allows.
  request_timeout_ms = var.request_timeout_ms

  retry {
    attempts     = var.retry_attempts
    max_delay_ms = 2000
  }
}
