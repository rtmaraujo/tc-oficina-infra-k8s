variable "aws_region" {
  description = "Regiao da AWS"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "k3s_key_name" {
  description = "Nome da key pair SSH do cluster k3s"
  type        = string
  default     = "tc-oficina-k3s"
}

variable "k3s_server_instance_type" {
  description = "Tipo da instancia EC2 do no server (control plane)"
  type        = string
  default     = "t3.small"
}

variable "k3s_worker_instance_type" {
  description = "Tipo da instancia EC2 dos nos workers"
  type        = string
  default     = "t3.small"
}

variable "k3s_worker_count" {
  description = "Quantidade de nos workers do cluster k3s"
  type        = number
  default     = 2
}

variable "k3s_token" {
  description = "Token compartilhado do cluster k3s (via secret)"
  type        = string
  sensitive   = true
}

variable "ecr_access_key_id" {
  description = "AWS Access Key para autenticacao no ECR (via secret)"
  type        = string
  sensitive   = true
}

variable "ecr_secret_access_key" {
  description = "AWS Secret Key para autenticacao no ECR (via secret)"
  type        = string
  sensitive   = true
}

variable "ecr_session_token" {
  description = "AWS Session Token para autenticacao no ECR (via secret)"
  type        = string
  sensitive   = true
}