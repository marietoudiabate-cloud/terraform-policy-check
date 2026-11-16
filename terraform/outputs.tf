output "web_public_ip" { value = google_compute_instance.web.network_interface[0].access_config[0].nat_ip }
output "web_name" { value = google_compute_instance.web.name }
output "bucket_name" { value = google_storage_bucket.artifacts.name }
output "ssh_user" { value = var.ssh_user }