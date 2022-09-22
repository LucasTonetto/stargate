provider "google" {
  project = var.project_id
  credentials = "dp6-stargate-f2626d0fa52e.json"
  region      = var.region
}

terraform {
	required_providers {
		google = {
	    version = "~> 4.31.0"
		}
  }
}
