#!/bin/bash


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


# PRODUCTION – HTTP REDIRECT

server {
    listen 80;
    server_name production.anyth.store;

    return 301 https://$host$request_uri;
}


# STAGING – HTTP REDIRECT

server {
    listen 80;
    server_name staging.anyth.store;

    return 301 https://$host$request_uri;
}


# PRODUCTION – HTTPS

server {
    listen 443 ssl http2;
    server_name production.anyth.store;

    # TLS (Let's Encrypt)
    ssl_certificate     /etc/letsencrypt/live/production.anyth.store/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/production.anyth.store/privkey.pem;

    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Logs
    access_log /var/log/nginx/production_access.log;
    error_log  /var/log/nginx/production_error.log;

    location / {
        proxy_pass http://127.0.0.1:8080;

        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}


# STAGING – HTTPS

server {
    listen 443 ssl http2;
    server_name staging.anyth.store;

    # TLS (Let's Encrypt)
    ssl_certificate     /etc/letsencrypt/live/production.anyth.store/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/production.anyth.store/privkey.pem;

    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Logs
    access_log /var/log/nginx/staging_access.log;
    error_log  /var/log/nginx/staging_error.log;

    location / {
        proxy_pass http://127.0.0.1:8081;

        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

EOF

nginx -t && systemctl reload nginx

# echo "Bootstrap completed"
