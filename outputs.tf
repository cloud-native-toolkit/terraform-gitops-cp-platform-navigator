output "name" {
  description = "The name of the platform navigator instance"
  value       = local.instance_name
  depends_on  = [null_resource.setup_instance_gitops]
}

output "namespace" {
  description = "The namespace where the platform navigator instance has been deployed"
  value       = var.namespace
  depends_on  = [null_resource.setup_instance_gitops]
}
