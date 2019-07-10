# gigabyte-website

## Deployment

### Terraform

Use Terraform to instantiate the t2.micro Ubuntu instance on AWS cloud with the 
following commands:
```
$ terraform init
$ terraform plan
$ terraform apply
# To terminate EC2 instance
$ terraform destroy
```

Check that your new EC2 instance exists on your AWS Web console. It will have 
the name `ec2-as1-staging-gigabyte`.

Reconcile the Terraform state file with the actual AWS infrastructure to update 
public IP address of the staging_dockerhost instance with the elastic IP 
address:
```
$ terraform refresh
```

If this is not done then Ansible will try to use the initial IP address of 
your EC2 instance and you will get a server not found error since the server
will not be associated with your elastic IP address.

### Ansible

The machines controlled by Ansible are usually defined in a hosts file which 
lists the host machines and how they are grouped together. Our hosts file is 
located at `ops/infrastructure/inventories/hosts` and contains the following 
content:
```
[landing_host]

# Do not add any IP address here as it is dynamically managed using 
# terraform-inventory

[landing_host:vars]

ansible_ssh_private_key_file= {{ vault_landing_private_key_file_location }}
ansible_user="root"
ansible_become="true"
gigabytejournal_environment = landing

[all:vars]

gitlab_url = {{ vault_gitlab_url }}
```

Our hosts file does not list any machines. Instead, a tool called 
terraform-inventory generates a dynamic Ansible inventory from a Terraform state 
file. Nonetheless, the hosts file is still used to reference variables for 
hosts.

One particular variable to note is `gitlab_private_token`. Its value is the 
contents of a file located at `~/.gitlab_private_token`. Create this file using 
the GitLab personal access token that you will use to access the GitLab API. 
N.B. The read_user and read_registry scopes are not required when creating the 
private token.
The values of some of the variables in the hosts file are sensitive and for this 
reason, the actual values are encrypted within an Ansible vault file which needs 
to be located at ops/infrastructure/group_vars/all/vault. This vault file should 
NOT be version controlled as defined in the .gitignore file.

Create the vault file in the `ops/infrastructure/group_vars/all` directory:
```
$ pwd
~/gigadb-website
# Make a directory for group variables
$ mkdir ops/infrastructure/group_vars 
# Make a directory for all
$ mkdir ops/infrastructure/group_vars/all
# Create vault file
$ ansible-vault create ops/infrastructure/group_vars/all/vault
```

You will be prompted to enter a password, which you will need to share with 
others needing access to the vault. The variables below with appropriate values 
need to be placed in the vault file:
```
# Path to AWS pem file
vault_landing_private_key_file_location: ~/.ssh/aws-ubuntu18_04-keys.pem
```

Save the vault file when you are done. Since the vault file is encrypted, you 
will see something like this if you try to edit the file in a text editor:
```
$ANSIBLE_VAULT;1.2;AES256;dev
37636561366636643464376336303466613062633537323632306566653533383833366462366662
6565353063303065303831323539656138653863353230620a653638643639333133306331336365
62373737623337616130386137373461306535383538373162316263386165376131623631323434
3866363862363335620a376466656164383032633338306162326639643635663936623939666238
3161
```

To open the encrypted vault file for editing, use the command below and input 
the password when prompted:
```
$ ansible-vault edit ops/infrastructure/group_vars/all/vault
```

Provide Ansible with the password to access the vault file during the execution 
of playbooks by storing the password to the vault file in a `~/.vault_pass.txt`
file.

Roles are used in Ansible to perform tasks on machines such as installing a
software package. An Ansible role consists of a group of variables, tasks, files 
and handlers stored in a standardised file structure. There are a number of 
roles in ops/infrastructure/roles for installing Docker, PostgreSQL and security 
tools on hosts. Other roles are required which are available from public 
repositories.

Download these roles:
```
$ ansible-galaxy install -r requirements.yml
```

#### Ansible playbook execution

Provision the EC2 instance using Ansible:
```
$ ansible-playbook -vvv -i inventories staging-playbook.yml --vault-password-file ~/.vault_pass.txt
```

>Since an elastic IP address is being used, you might need to delete the entry in 
the `~/.ssh/known_hosts` file associated with the elastic IP address if this is 
not the first time you have performed this provisioning step.