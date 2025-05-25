variable "client_id" {
  description = "Client ID"
  type        = string
}

variable "client_secret" {
  description = "Client secret"
  type        = string
}

variable "subscription_id" {
  description = "Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Location"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix"
  type        = string
}

variable "node_pool_name" {
  description = "Node pool name"
  type        = string
}

variable "node_count" {
  description = "Node count"
  type        = number
}

variable "vm_size" {
  description = "VM size"
  type        = string
}

variable "identity_type" {
  description = "Identity type"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}