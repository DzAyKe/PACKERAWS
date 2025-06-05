# PACKERAWS

Liaison AWS :
Installation de AWS CLI

https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

```jsx
aws configure
```

nous serons menez à renseigner notre key créer précédemment sur AWS

```jsx
AWS Access Key ID [None]: <ta_clé>
AWS Secret Access Key [None]: <ta_secret_clé>
Default region name [None]: eu-west-3        # (ex : Paris)
Default output format [None]: json           # (ou table, text)
```

Création de l’image VM avec Packer:

fronted.pkr.hcl

```hcl
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
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  name    = "learn-packer"
  sources = ["source.amazon-ebs.ubuntu"]

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
    "sudo apt-get install -y nginx fail2ban",

    #Enable Fail2Ban
    "sudo systemctl enable fail2ban",

    # Création de l'utilisateur 'packer' avec mot de passe
    "sudo useradd -m -s /bin/bash packer || true",
    "echo 'packer:packer' | sudo chpasswd"
  ]
}

}

```
lancement des commandes 

Vérification de la commande
```jsx
packer validate .(nom du fichier) 
```
Mettre a jours les plugins de la config

```jsx
packer init .
```
Build la config

```jsx
packer build .
```

Nous réalisons les même commande pour les deux fichier suivant:

backend.pkr.hcl
```hcl

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

```

et le fichier database.pkr.hcl

```hcl 
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
```

une fois les 3 AMI créer sur AWS 

nous pouvons faire le fichier terraform:

main.tf
```tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "fcs_frontend" {
  ami           = "ami-0f5dd381e07b0943a"
  instance_type = "t3.micro"
  key_name = "terraform_ec2_key"

  tags = {
    Name = "FCS-FRONTEND"
  }
}

resource "aws_instance" "fcs_backend" {
  ami           = "ami-01e89ce81fbe4acf2"
  instance_type = "t3.micro"
  key_name = "terraform_ec2_key"

  tags = {
    Name = "FCS-BACKEND"
 }
}

resource "aws_instance" "fcs_database" {
  ami           = "ami-0e27c3a2c52a5ac69"
  instance_type = "t3.micro"
  key_name = "terraform_ec2_key"

  tags = {
    Name = "FCS-DATABASE"
 }
}

resource "aws_key_pair" "terraform_ec2_key" {
  key_name = "terraform_ec2_key"
  public_key = "${file("terraform_ec2_key.pub")}"
}
```

Nous pouvons donc créer la clé ssh afin de se connecter sur les Instances
```
ssh-keygen -f terraform_ec2_key
```

une fois cela fait nous pouvons executer notre script Terraform:
```jsx
terraform init
```

```jsx
terraform plan
```

```jsx
terraform apply

```

nous pouvons ensuite nous connecter en SSH sur les instance afin de vérifier:

```

ssh -i terraform_ec2_key ubuntu@"instance"
```

