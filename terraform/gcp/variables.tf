variable "credentials_file" {
  description = "Path to the GCP credentials JSON file"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "account_id" {
  description = "Service account ID"
  type        = string
}

variable "display_name" {
  description = "Service account display name"
  type        = string
}

variable "gke_cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
}

variable "node_pool_name" {
  description = "Name of the node pool"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the node pool"
  type        = string
}