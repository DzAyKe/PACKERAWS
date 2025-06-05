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

fichier.pkr.hcl

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
  ami_name      = "NOM AMI"
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
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
}

```
