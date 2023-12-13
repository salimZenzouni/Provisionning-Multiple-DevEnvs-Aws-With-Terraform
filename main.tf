# Virtual private cloud network
resource "aws_vpc" "v2_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "public-vpc"
  }
}

# Public subnet
resource "aws_subnet" "v2_public_subnet" {
  vpc_id                  = aws_vpc.v2_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.v2_vpc.cidr_block, 8, 1) # 0: returning the first subnet
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = {
    Name = "public-subnet-dev"
  }
}

# Route table
resource "aws_route_table" "v2_route_table" {
  vpc_id = aws_vpc.v2_vpc.id

  tags = {
    Name = "dev-public-route-table"
  }
}

# Route
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.v2_route_table.id
  gateway_id             = aws_internet_gateway.v2_internet_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

# Internet Gateway
resource "aws_internet_gateway" "v2_internet_gateway" {
  vpc_id = aws_vpc.v2_vpc.id
  tags = {
    Name = "dev-internet-gateway"
  }
}

# Associating the route table to the gateway
resource "aws_route_table_association" "v2_rt_asso" {
  route_table_id = aws_route_table.v2_route_table.id
  subnet_id      = aws_subnet.v2_public_subnet.id
}

# Security group
resource "aws_security_group" "v2_pulic_security_group" {
  vpc_id = aws_vpc.v2_vpc.id

  # inbound traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  #outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-public-security-group"
  }
}

# External data source to generate SSH key and read public key content
data "external" "ssh_key_gen" {
  count = local.instances_count

  program = ["${path.module}/generate_ssh_key.sh",
    "test_key-${count.index}",
  "${pathexpand("~/.ssh/")}"]
}

# Aws key pairs resource
resource "aws_key_pair" "generated_key" {
  count      = local.instances_count 
  key_name   = "${local.ssh_key_name}-${count.index}"
  public_key = data.external.ssh_key_gen[count.index].result.public_key

  depends_on = []
}

# Ec2 instances
resource "aws_instance" "v2_dev_ubuntu" {
  count                  = local.instances_count
  instance_type          = var.ec2_type
  ami                    = data.aws_ami.server_ami.id
  vpc_security_group_ids = [aws_security_group.v2_pulic_security_group.id]
  subnet_id              = aws_subnet.v2_public_subnet.id
  key_name               = aws_key_pair.generated_key[count.index].key_name
  user_data              = file("userdata.tpl")

  tags = {
    Name = "ansible-node-${count.index}"
  }

  provisioner "local-exec" {
    command = templatefile("linux-ssh-config.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu",
      identityfile = "${pathexpand("~/.ssh/${local.ssh_key_name}-${count.index}")}"
    })

    interpreter = ["bash", "-c"]

  }

  # dependencies
  depends_on = [aws_key_pair.generated_key]
}