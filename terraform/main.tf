data "aws_availability_zones" "available" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================
# Rede
# ============================================

resource "aws_vpc" "tc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tc-oficina-vpc"
  }
}

resource "aws_internet_gateway" "tc" {
  vpc_id = aws_vpc.tc.id

  tags = {
    Name = "tc-oficina-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.tc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "tc-oficina-subnet-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.tc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "tc-oficina-subnet-private-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.tc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tc.id
  }

  tags = {
    Name = "tc-oficina-rt-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.tc.id

  tags = {
    Name = "tc-oficina-rt-private"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ============================================
# ECR
# ============================================

resource "aws_ecr_repository" "tc" {
  name                 = "tc-oficina"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ============================================
# Kubernetes k3s em EC2 (cluster auto-gerenciado)
#   - Cluster K8s real (control plane + workers)
#   - HPA: metrics-server ja embutido no k3s
# ============================================

resource "aws_key_pair" "k3s" {
  key_name   = var.k3s_key_name
  public_key = file("${path.module}/k3s-key.pub")
}

resource "aws_security_group" "k3s" {
  name        = "tc-oficina-k3s-sg"
  description = "Security group do cluster k3s (EC2)"
  vpc_id      = aws_vpc.tc.id

  ingress {
    description = "SSH (CI/CD)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "API do Kubernetes (kubectl)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort da aplicacao"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Comunicacao interna da VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tc-oficina-k3s-sg"
  }
}

resource "aws_instance" "k3s_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.k3s_server_instance_type
  subnet_id                   = aws_subnet.public[0].id
  private_ip                  = "10.0.0.10"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.k3s.key_name
  vpc_security_group_ids      = [aws_security_group.k3s.id]

  user_data = base64encode(templatefile("${path.module}/userdata-server.sh", {
    k3s_token         = var.k3s_token
    ecr_url           = aws_ecr_repository.tc.repository_url
    region            = var.aws_region
    ecr_access_key    = var.ecr_access_key_id
    ecr_secret_key    = var.ecr_secret_access_key
    ecr_session_token = var.ecr_session_token
  }))

  root_block_device {
    volume_size           = 12
    volume_type           = "gp3"
    delete_on_termination = true
    tags = {
      Name = "tc-oficina-k3s-server-root"
    }
  }

  tags = {
    Name = "tc-oficina-k3s-server"
  }

  depends_on = [aws_internet_gateway.tc]
}

resource "aws_eip" "k3s" {
  domain   = "vpc"
  instance = aws_instance.k3s_server.id

  tags = {
    Name = "tc-oficina-k3s-eip"
  }
}

resource "aws_instance" "k3s_worker" {
  count                       = var.k3s_worker_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.k3s_worker_instance_type
  subnet_id                   = aws_subnet.public[count.index % 2].id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.k3s.key_name
  vpc_security_group_ids      = [aws_security_group.k3s.id]

  user_data = base64encode(templatefile("${path.module}/userdata-worker.sh", {
    k3s_token         = var.k3s_token
    server_private_ip = "10.0.0.10"
    ecr_url           = aws_ecr_repository.tc.repository_url
    region            = var.aws_region
    ecr_access_key    = var.ecr_access_key_id
    ecr_secret_key    = var.ecr_secret_access_key
    ecr_session_token = var.ecr_session_token
  }))

  root_block_device {
    volume_size           = 12
    volume_type           = "gp3"
    delete_on_termination = true
    tags = {
      Name = "tc-oficina-k3s-worker-${count.index + 1}-root"
    }
  }

  tags = {
    Name = "tc-oficina-k3s-worker-${count.index + 1}"
  }

  depends_on = [aws_instance.k3s_server]
}