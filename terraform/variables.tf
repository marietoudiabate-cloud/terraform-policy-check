variable "project_id" { type = string }

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env doit valoir dev, staging ou prod."
  }
}

variable "owner" { type = string }

variable "admin_cidr" {
  type        = string
  description = "Seule IP autorisée en SSH (format x.x.x.x/32)"
}

variable "ssh_user" {
  type    = string
  default = "ansible"
}

variable "ssh_pub_key_path" {
  type    = string
  default = "~/.ssh/gcp_lab.pub"
}