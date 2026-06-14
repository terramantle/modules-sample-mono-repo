output "release_id" {
  description = "The random release id embedded in the manifest"
  value       = random_string.release_id.result
}

output "manifest_path" {
  description = "Path the manifest was written to"
  value       = local_file.manifest.filename
}

output "manifest_json" {
  description = "The rendered manifest as a JSON string"
  value       = local_file.manifest.content
}
