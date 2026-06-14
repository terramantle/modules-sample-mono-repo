output "name" {
  description = "The generated pet name"
  value       = random_pet.this.id
}

output "unique_name" {
  description = "The pet name with a short random hex suffix appended"
  value       = "${random_pet.this.id}${var.separator}${random_id.suffix.hex}"
}
