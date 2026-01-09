#!/bin/bash
set -e

# Log everything
exec > /var/log/bootstrap.log 2>&1

echo "Updating system..."
yum update -y

echo "Installing Docker..."
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

echo "Installing Nginx..."
amazon-linux-extras enable nginx1
yum install -y nginx
systemctl start nginx
systemctl enable nginx

echo "Installing Certbot..."
yum install -y certbot python3-certbot-nginx

echo "Installing Git..."
yum install -y git

echo "Cloning app repo..."
git clone https://github.com/Bobcharliee/hello-svc.git /opt/app

echo "Building Docker image..."
docker build -t myapp /opt/app

echo "Running containers..."
docker run -d --restart always -p 8080:8080 --name prod hello-svc
docker run -d --restart always -p 8081:8080 --name staging hello-svc

echo "Creating Nginx config..."
cat <<EOF > /etc/nginx/conf.d/hello.conf

# Production - HTTP Redirect
server {
    listen 80;
    server_name production.anyth.store;

    return 301 https://$host$request_uri;

}

# Staging - HTTP Redirect
server {
    listen 80;
    server_name staging.anyth.store;

    return 301 https://$host$request_uri;

}
EOF

nginx -t && systemctl reload nginx

# echo "Bootstrap completed"
