resource "aws_key_pair" "tf200-nginxweb-key" {
  key_name   = "tf200-nginxweb-key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_instance" "nginxweb" {
  ami                    = var.amis[var.region]
  instance_type          = "${var.instance_type}"
  subnet_id              = var.subnet_ids[var.region]
  vpc_security_group_ids  = [var.vpc_security_group_ids[var.region]]
  key_name               = "${aws_key_pair.tf200-nginxweb-key.id}"

  connection {
    user        = "ubuntu"
    type        = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y nginx",
      "sudo ufw allow 'Nginx Full'",
      "sudo ufw delete allow 'Nginx HTTP'"
    ]
  }

  provisioner "file" {
    content     = <<EOT
${acme_certificate.certificate.certificate_pem}

${acme_certificate.certificate.issuer_pem}

    EOT
    destination = "/tmp/${var.site_record}.${var.site_domain}_full_chain.pem"
  }  

  provisioner "file" {
    content     = <<EOT
${acme_certificate.certificate.private_key_pem}
    EOT
    destination = "/tmp/${var.site_record}.${var.site_domain}_private_key.pem"
  }  



  provisioner "file" {
    content     = <<EOT
    server {
        server_name cert-test-a.guselietov.com;
        listen 443 ssl;
        ssl_certificate /etc/nginx/${var.site_record}.${var.site_domain}_full_chain.pem;
        ssl_certificate_key /etc/nginx/${var.site_record}.${var.site_domain}_private_key.pem;

        root /var/www/html;

        index index.html index.htm index.nginx-debian.html;

        location / {
                try_files $uri $uri/ =404;
        }

    }    
    EOT
    destination = "/tmp/${var.site_record}.${var.site_domain}.conf"
  }

provisioner "remote-exec" {
    inline = [
      "sudo ln -s /etc/nginx/sites-available/${var.site_record}.${var.site_domain}.conf /etc/nginx/sites-enabled/",
      "sudo add-apt-repository ppa:certbot/certbot -y",
      "sudo apt install python-certbot-nginx -y",
      "sudo certbot --nginx -d cert-test-a.guselietov.com --non-interactive --agree-tos -m andrii@guselietov.com",
      "sudo /etc/init.d/nginx reload",
      "sudo tar -czvf /tmp/lte.tgz /etc/letsencrypt/",
      "sudo tar -czvf /tmp/nginx.tgz /etc/nginx"
    ]
  }

  tags = {
    "Name"      = "web-nginx",
    "andriitag" = "true",
  }
}
