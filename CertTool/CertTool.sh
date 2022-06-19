#!/bin/sh

echo "Whitetail Militia CertTool"
read -p "FQDN : " fqdn
echo "Generating CSR..."
openssl req -new -newkey rsa:4096 -nodes -keyout $fqdn.key -out $fqdn.csr -subj "/C=US/ST=New_York/L=Rochester/O=Whitetail Militia/OU=IT Department/CN=$fqdn" -addext "subjectAltName = DNS:$fqdn"
echo "CSR Generated Successfully!"
echo "Here is the CSR:\n"
cat $fqdn.csr
echo "\nPaste the signed cert below (ctrl-d when done):\n"
cert_val=$(cat)
echo "Saving TLS key/cert"
mv $fqdn.key /etc/ssl/private/$fqdn.key
echo "${cert_val}" > /etc/ssl/certs/$fqdn.crt
read -p "What port is the service on? : " service_port
echo "Generating configuration..."

config_file="
server {
    listen 80;
    server_name $fqdn;
    return 301 https://\$host\$request_uri;
}

server {
  listen 443 ssl;
  server_name  $fqdn;

  # add Strict-Transport-Security to prevent man in the middle attacks
  add_header Strict-Transport-Security \"max-age=31536000\" always;

  # SSL
  ssl_certificate /etc/ssl/certs/$fqdn.crt;
  ssl_certificate_key /etc/ssl/private/$fqdn.key;

  # Recommendations from
  # https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
  ssl_protocols TLSv1.1 TLSv1.2;
  ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:10m;

  # required to avoid HTTP 411: see Issue #1486
  # (https://github.com/docker/docker/issues/1486)
  chunked_transfer_encoding on;

  location / {
    proxy_pass http://127.0.0.1:$service_port/;
    proxy_set_header Host \$http_host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

    proxy_set_header X-Forwarded-Proto \$scheme;

    proxy_buffering off;
    proxy_request_buffering off;
  }
}
"

echo "Loading in configuration..."
echo "${config_file}" > /etc/nginx/sites-available/$fqdn.conf
ln -s /etc/nginx/sites-available/$fqdn.conf /etc/nginx/sites-enabled/$fqdn.conf

echo "Bouncing Nginx service..."
service nginx restart

echo "Cleaning up..."

# Clean up
rm $fqdn.csr

echo "Done! Thanks for using CertTool."
