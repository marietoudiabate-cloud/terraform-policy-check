locals {
  name = "infraval-${var.env}"
  labels = {
    env        = var.env
    owner      = var.owner
    project    = "infra-validation"
    managed_by = "terraform"
  }
}

resource "google_compute_network" "vpc" {
  name                    = "${local.name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${local.name}-subnet"
  ip_cidr_range = "10.10.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"   # agrège les logs toutes les 10 min, donc moins de volume
    flow_sampling        = 0.5                 # garde 50 % des flux, ce qui limite le coût
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_ssh_admin" {
  name          = "${local.name}-allow-ssh-admin"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  source_ranges = [var.admin_cidr]
  target_tags   = ["web"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "allow_http" {
  name          = "${local.name}-allow-http"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_instance" "web" {
  name         = "${local.name}-web-01"
  machine_type = "e2-micro"
  tags         = ["web"]
  labels       = local.labels

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }

  metadata = {
    ssh-keys               = "${var.ssh_user}:${file(pathexpand(var.ssh_pub_key_path))}"
    block-project-ssh-keys = "true"
  }

  shielded_instance_config {
    enable_secure_boot = true
  }
}

resource "random_id" "suffix" {
  byte_length = 3
}

resource "google_storage_bucket" "artifacts" {
  name                        = "${local.name}-artifacts-${random_id.suffix.hex}"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true
  labels                      = local.labels
  versioning {
    enabled = true
  }
}