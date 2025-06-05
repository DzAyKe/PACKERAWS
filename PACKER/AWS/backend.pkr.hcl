packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "BACKEND"
  instance_type = "t2.micro"
  region        = "us-west-2"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"/*  */
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  name    = "learn-packer"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  
    provisioner "shell" {
    inline = [
      "set -eux",

    # Activer le dépôt universe
    "sudo add-apt-repository universe -y",

    # Mise à jour des dépôts
    "sudo apt-get update -y",

    # Système à jour
    "sudo apt-get upgrade -y",

    # Installation des dépendances
    "sudo apt-get install -y nodejs fail2ban",

    #Enable Fail2Ban
    "sudo systemctl enable fail2ban",

    # Création de l'utilisateur 'packer' avec mot de passe
    "sudo useradd -m -s /bin/bash packer || true",
    "echo 'packer:packer' | sudo chpasswd"
    ]
  }
}
