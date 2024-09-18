current_tfwsp=$(terraform workspace show)
terraform init
terraform plan -var-file=envs/${current_tfwsp}.tfvars
terraform apply -var-file=envs/${current_tfwsp}.tfvars