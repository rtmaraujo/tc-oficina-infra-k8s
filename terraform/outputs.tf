output "k3s_server_ip" {
  description = "IP publico do no server do cluster k3s"
  value       = aws_eip.k3s.public_ip
}

output "k3s_server_private_ip" {
  description = "IP privado do no server do cluster k3s"
  value       = aws_instance.k3s_server.private_ip
}

output "ecr_repository_url" {
  description = "URL do repositorio ECR da imagem da aplicacao"
  value       = aws_ecr_repository.tc.repository_url
}