packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "database" {
  ami_name      = "DATABASE"
  instance_type = "t2.micro"
  region        = "us-west-2"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
  tags = {
    Name = "Database-MongoDB"
    Role = "Database"
  }
}

build {
  name    = "database-build"
  sources = ["source.amazon-ebs.database"]

  provisioner "shell" {
    inline = [
      # Mise à jour des sources apt
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",

      # Ajout des dépôts nécessaires
      "sudo add-apt-repository universe -y",
      "sudo apt-get update -y",

      # Installation des dépendances de base
      "sudo apt-get install -y gnupg curl software-properties-common",

      # Installation de fail2ban
      "sudo apt-get install -y fail2ban",
      "sudo systemctl enable fail2ban",
      "sudo systemctl start fail2ban",

      # Configuration de l'utilisateur packer
      "sudo useradd -m -s /bin/bash packer",
      "echo 'packer:packer' | sudo chpasswd",
      "echo 'packer ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/packer",

      # Installation de MongoDB
      "curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor",
      "echo 'deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y mongodb-org",

      # Configuration de MongoDB
      "sudo systemctl enable mongod",
      "sudo systemctl start mongod",

      # Configuration de la sécurité MongoDB
      "sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf",
      "sudo systemctl restart mongod",

      # Configuration de fail2ban pour MongoDB
      "echo '[mongodb]' | sudo tee -a /etc/fail2ban/jail.local",
      "echo 'enabled = true' | sudo tee -a /etc/fail2ban/jail.local",
      "echo 'port = 27017' | sudo tee -a /etc/fail2ban/jail.local",
      "echo 'filter = mongodb' | sudo tee -a /etc/fail2ban/jail.local",
      "echo 'logpath = /var/log/mongodb/mongod.log' | sudo tee -a /etc/fail2ban/jail.local",
      "echo 'maxretry = 3' | sudo tee -a /etc/fail2ban/jail.local",
      "echo 'bantime = 3600' | sudo tee -a /etc/fail2ban/jail.local",
      "sudo systemctl restart fail2ban",

      # Nettoyage
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*"
    ]
  }
}