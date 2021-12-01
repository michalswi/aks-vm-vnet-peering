output "host" {
  value = azurerm_kubernetes_cluster.kluster.kube_config.0.host
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.kluster.kube_config_raw
  sensitive = true
}