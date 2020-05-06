
variable "client_id" {}
variable "client_secret" {}

variable rg_name {
    default = "mk8srg"
}

variable location {
    default = "westeurope"
}

variable "dns_prefix" {
    default = "mk8s"
}

variable cluster_name {
    default = "mk8s"
}

variable "agent_count" {
    default = 1
}

variable "kubernetes_version" {
  default = "1.15.10"
}

variable "network_plugin" {
    default = "azure"
    # default = "kubenet"
    # default = "flannel"
    # default = "cilium"
}