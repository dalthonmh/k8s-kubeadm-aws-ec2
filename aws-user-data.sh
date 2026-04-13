#! /bin/bash
sudo apt-get update
sudo apt-get install -y nginx
sudo sed -i 's/80 default_server/81 default_server/g' /etc/nginx/sites-available/default
echo "<h1>Test AWS</h1>" | sudo tee /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
sudo systemctl enable nginx
