# Generate a new SSH key pair
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.pk.public_key_openssh
}

# Save the private key locally
resource "local_file" "ssh_key" {
  filename        = "${path.module}/${var.project_name}-key.pem"
  content         = tls_private_key.pk.private_key_pem
  file_permission = "0400"
}

# Get latest Ubuntu 22.04 AMI ID from SSM
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

# EC2 Instance in Private Subnet - depends on NAT Gateway
resource "aws_instance" "strapi_app" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.strapi_sg.id]
  key_name                    = aws_key_pair.kp.key_name
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  # Explicit dependency on NAT Gateway and route table association
  depends_on = [
    aws_nat_gateway.main,
    aws_route_table_association.private
  ]

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              set -ex
              
              echo "=== Starting Strapi Setup ==="
              echo "Timestamp: $(date)"
              
              # ============================================
              # WAIT FOR INTERNET CONNECTIVITY VIA NAT GATEWAY
              # ============================================
              echo "=== Waiting for NAT Gateway connectivity ==="
              MAX_RETRIES=30
              RETRY_COUNT=0
              
              while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
                if curl -s --connect-timeout 5 https://google.com > /dev/null 2>&1; then
                  echo "Internet connectivity established via NAT Gateway!"
                  break
                fi
                RETRY_COUNT=$((RETRY_COUNT + 1))
                echo "Waiting for internet connectivity... attempt $RETRY_COUNT/$MAX_RETRIES"
                sleep 10
              done
              
              if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
                echo "ERROR: Could not establish internet connectivity after $MAX_RETRIES attempts"
                exit 1
              fi
              
              # ============================================
              # SYSTEM UPDATE
              # ============================================
              echo "=== System Update ==="
              apt-get update -y
              apt-get upgrade -y
              
              # ============================================
              # INSTALL DOCKER
              # ============================================
              echo "=== Installing Docker ==="
              apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
              
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
              
              echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
              
              usermod -aG docker ubuntu
              
              # ============================================
              # INSTALL NODE.JS 22
              # ============================================
              echo "=== Installing Node.js 22 ==="
              curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
              apt-get install -y nodejs
              
              # ============================================
              # CREATE STRAPI ON HOST (NOT IN DOCKER BUILD)
              # ============================================
              echo "=== Creating Strapi Application ==="
              cd /home/ubuntu
              
              # Set environment to skip all prompts
              export CI=true
              export STRAPI_DISABLE_REMOTE_DATA_TRANSFER=true
              export STRAPI_TELEMETRY_DISABLED=true
              
              # Create Strapi app as ubuntu user (pipe 'n' to skip A/B testing prompt)
              echo "n" | sudo -u ubuntu -E npx create-strapi-app@latest strapi --quickstart --no-run --skip-cloud
              
              # ============================================
              # CREATE DOCKERFILE
              # ============================================
              echo "=== Creating Dockerfile ==="
              cat > /home/ubuntu/strapi/Dockerfile << 'DOCKERFILE'
              FROM node:22-alpine
              
              RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev vips-dev
              
              WORKDIR /srv/app
              
              COPY package*.json ./
              RUN npm ci
              
              COPY . .
              RUN npm run build
              
              EXPOSE 1337
              
              ENV HOST=0.0.0.0
              ENV PORT=1337
              ENV NODE_ENV=production
              
              CMD ["npm", "run", "start"]
              DOCKERFILE
              
              # ============================================
              # CREATE DOCKER COMPOSE
              # ============================================
              echo "=== Creating docker-compose.yml ==="
              cat > /home/ubuntu/strapi/docker-compose.yml << 'COMPOSE'
              services:
                strapi:
                  build: .
                  container_name: strapi
                  restart: unless-stopped
                  ports:
                    - "1337:1337"
                  environment:
                    - HOST=0.0.0.0
                    - PORT=1337
                    - NODE_ENV=production
                  volumes:
                    - strapi-uploads:/srv/app/public/uploads
              volumes:
                strapi-uploads:
              COMPOSE
              
              # ============================================
              # CREATE .DOCKERIGNORE
              # ============================================
              echo "=== Creating .dockerignore ==="
              cat > /home/ubuntu/strapi/.dockerignore << 'IGNORE'
              node_modules
              .tmp
              .cache
              build
              .git
              *.log
              IGNORE
              
              chown -R ubuntu:ubuntu /home/ubuntu/strapi
              
              # ============================================
              # BUILD AND START CONTAINER
              # ============================================
              echo "=== Building Docker Image ==="
              cd /home/ubuntu/strapi
              sudo -u ubuntu docker compose build
              
              echo "=== Starting Strapi Container ==="
              sudo -u ubuntu docker compose up -d
              
              echo "=== Strapi Setup Complete ==="
              echo "Timestamp: $(date)"
              EOF

  tags = {
    Name = "${var.project_name}-ec2"
  }
}
