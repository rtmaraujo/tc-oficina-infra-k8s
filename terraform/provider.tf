terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }

  backend "s3" {
    bucket = "tc-oficina-terraform-state"
    key    = "infra-k8s/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = aws_eks_cluster.tc.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.tc.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.tc.token
}
