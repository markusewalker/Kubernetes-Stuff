terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.36.1"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
}

resource "google_service_account" "google_service_account" {
  account_id   = var.account_id
  display_name = var.display_name
}

resource "google_container_cluster" "google_container_cluster" {
  name                     = var.gke_cluster_name
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = var.node_count
}

resource "google_container_node_pool" "node_pool" {
  name       = var.node_pool_name
  location   = var.region
  cluster    = google_container_cluster.google_container_cluster.name
  node_count = 3

  node_config {
    preemptible  = true
    machine_type = var.machine_type

    service_account = google_service_account.google_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}