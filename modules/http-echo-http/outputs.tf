output "status_code" {
  description = "HTTP status code returned by the URL"
  value       = data.http.echo.status_code
}

# Sensitive so it is not dumped to CI logs. The whole point is that the state
# SCANNER finds the embedded endpoint, not that we also print it to a log.
output "response_body" {
  description = "Raw response body (stored in state - feeds the endpoint scan)"
  value       = data.http.echo.response_body
  sensitive   = true
}
