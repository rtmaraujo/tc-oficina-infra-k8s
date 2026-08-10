output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.tc.name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.tc.endpoint
}

output "ecr_repository_url" {
  description = "URL do repositorio ECR da imagem da aplicacao"
  value       = aws_ecr_repository.tc.repository_url
}

output "kubeconfig_command" {
  description = "Comando para gerar o kubeconfig do cluster"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.tc.name} --region ${var.aws_region}"
}
