terraform {
  required_providers {
    railway = {
      source  = "terraform-community-providers/railway"
      version = "~> 0.4"
    }
  }
}

resource "railway_project" "this" {
  name = var.project_name
}

resource "railway_service" "this" {
  project_id = railway_project.this.id
  name       = var.service_name
}
