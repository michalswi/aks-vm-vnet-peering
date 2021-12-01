variable "client_id" {}
variable "client_secret" {}

variable "name" {
  default = "demo"
}

variable "location" {
  default = "westeurope"
}

variable "dns_prefix" {
  default = "mk8s"
}

variable "agent_count" {
  default = 1
}

variable "kubernetes_version" {
  default = "1.19.11"
}

variable "network_plugin" {
  default = "azure"
}
