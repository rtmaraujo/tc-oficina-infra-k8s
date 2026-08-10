variable "aws_region" {
  description = "Regiao da AWS"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
  default     = "tc-oficina"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_count" {
  description = "Quantidade inicial de nos do EKS"
  type        = number
  default     = 2
}

variable "node_min" {
  description = "Quantidade minima de nos"
  type        = number
  default     = 2
}

variable "node_max" {
  description = "Quantidade maxima de nos"
  type        = number
  default     = 10
}

variable "node_instance_type" {
  description = "Tipo da instancia EC2 dos nos"
  type        = string
  default     = "t3.medium"
}
