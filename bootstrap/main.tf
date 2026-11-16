terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "~> 6.0" }
  }
}

provider "google" {
  project = "expertdevops"
  region  = "us-central1"
}

resource "google_storage_bucket" "tfstate" {
  name                        = "expertdevops-tfstate-md"
  location                    = "us-central1"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  labels = {
    managed_by = "terraform"
    purpose    = "tfstate"
  }
}