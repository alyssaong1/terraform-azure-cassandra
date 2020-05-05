wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip

sudo apt install unzip
unzip terraform_0.12.24_linux_amd64.zip

sudo mv terraform /usr/local/bin/

rm terraform_0.12.24_linux_amd64.zip

terraform -v 