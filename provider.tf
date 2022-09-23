provider "google" {
  project = var.project_id
  credentials = "gcp_key_terraform.json"
  region      = var.region
}

terraform {
	required_providers {
		google = {
	    version = "~> 4.31.0"
		}
  }
}
