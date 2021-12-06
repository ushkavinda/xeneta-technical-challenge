## Xeneta Technical Challenge

This documentation demonstrates how to configure and deploy the given application in a development environment.

## Install prerequisites

 1. **Control node** - The machine runs Ansible commands and playbooks. You can use any Linux based machine as your Control node. If you are using Windows, it is required to configure and install [WSL](https://docs.microsoft.com/en-us/windows/wsl/install). 
 
	 - Install ansible ([Official documentation](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html))
	 
 2. **Manage node** - The machine that runs the application workload as docker containers. You can use the same Control node as you Manage node to deploy the application locally as well as you can use a remote server. If you are running the workload in a remote server it is required to verify the SSH connectivity between two nodes (Control node should have the SSH access to the Manage node). 
	 
	 - Install Docker ([Instructions](https://docs.docker.com/engine/install/centos/)) 
	 - Add user permission to run docker commands ([Instruction](https://docs.docker.com/engine/install/linux-postinstall/))
	 - Install Postgres client ([Instructions](https://www.postgresql.org/download/linux/redhat/)) 
	 - Install Python client for docker ([Instructions](https://pypi.org/project/docker-py/))

To install the above mentioned tools, you can use the **control_node_setup.sh** and **host_setup.sh** scripts which are available in this repository. These two scripts are compatible only with **Ubuntu 18.04 LTS**.

 - **control_node_setup.sh** - To install ansible.
 - **host_setup.sh** - To install docker and other modules. If you are planning to run the workload locally, execute this script in the same machine or else execute this in your remote machine. 

Tip: If you planning to launch an AWS EC2 instance to run the application, you can simply add these scripts to the user data section, and during the instance booting stage all the required tools will be installed.



## Deploy and Run the application locally

1. Navigate to ansible directory.
	```
	cd xeneta-technical-challenge/ansible/
	```
2. Run the ansible palybook command to deploy the application components as containers. 
	```
	ansible-playbook site.yml -i inventories/dev/hosts --limit 127.0.0.1 --connection local
	```
	This is deploying the database and the application as docker containers. After the ansible deployment is completed, you can see output like the following.
	```
	PLAY RECAP ************************************************************************************
	localhost                  : ok=14   changed=10   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
	```
3. Validate the docker containers.
	```
	docker ps
	
	CONTAINER ID   IMAGE             COMMAND                  CREATED       STATUS       PORTS                    NAMES
	a460a2051155   ratesapi:latest   "gunicorn -b :3000 w…"   2 hours ago   Up 2 hours   0.0.0.0:3000->3000/tcp   dev-ratesapi
	fb43b1999ebe   postgres:13.5     "docker-entrypoint.s…"   2 hours ago   Up 2 hours   0.0.0.0:5432->5432/tcp   dev-db
	```
4. Validate application and the results. 
	```
	curl "http://127.0.0.1:3000/rates?date_from=2021-01-01&date_to=2021-01-31&orig_code=CNGGZ&dest_code=EETLL" 
	```


## Deploy and Run the application in a remote server

1. Navigate to ansible directory.
	```
	cd xeneta-technical-challenge/ansible/
	```
2. Edit the remote server IP in the **host file**. You can use any editor to edit this file. The following command will open the file in vi editor.
	```
	vi inventories/dev/hosts
	```
	In this file, you will see a section called **[DEV_REMOTE]**. Replace the IP address with your remote server IP and the **ansible_user** as per your environment.
	```
	localhost ansible_connection=local
  
	[DEV_REMOTE]
	3.145.129.149 ansible_user=ec2-user
	```
	Once the changes are been made, save the file and exit.

3. Run the ansible palybook command from the **Control node** to deploy the application components as containers. 
	```
	 ansible-playbook site.yml -i inventories/dev/hosts --limit DEV_REMOTE
	```
	After the ansible deployment completed, you can see output similar to following.
	```
	PLAY RECAP ************************************************************************************************
	3.145.129.149              : ok=14   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
	```

3. In this scenario to validate the docker containers, you need to ssh into your remote server and run the following command.
	```
	docker ps
	
	CONTAINER ID   IMAGE             COMMAND                  CREATED         STATUS         PORTS                    NAMES
	86a7fa4ef0dd   ratesapi:latest   "gunicorn -b :3000 w…"   2 minutes ago   Up 2 minutes   0.0.0.0:3000->3000/tcp   dev-ratesapi
	11dbe09abd15   postgres:13.5     "docker-entrypoint.s…"   4 minutes ago   Up 4 minutes   0.0.0.0:5432->5432/tcp   dev-db
	
	```
4. To validate results, either you can run the curl command inside from the remote server or run curl command from the **Control node** by replacing the IP as following. 
	```
	Inside remote server: 
	curl "http://127.0.0.1:3000/rates?date_from=2021-01-01&date_to=2021-01-31&orig_code=CNGGZ&dest_code=EETLL" 
	
	From control node: 
	curl "http://<your-remote-server-ip>:3000/rates?date_from=2021-01-01&date_to=2021-01-31&orig_code=CNGGZ&dest_code=EETLL"
	```

## Project Overview

### Directory structure 
```
xeneta-technical-challenge/
├─ ansible/
│  ├─ inventories/		# Contains ansible inventory details related to the development environment.
│  │  ├─ dev/							
│  │  │  ├─ grou_vars/		# Variables realated to development environment.
│  │  │  │  ├─ all.yml					
│  │  │  ├─ hosts		# Ansible inventory fie which consists of server IPs for the development environment (Remote deployment).
│  ├─ roles/
│  │  ├─ common/
│  │  │  ├─ tasks/
│  │  │  │  ├─ main.yml		# Ansible task which executes commands to Create directory, Clone application code from git, and Create docker network.
│  │  ├─ dbtier/
│  │  │  ├─ tasks/
│  │  │  │  ├─ main.yml		# Ansible task which executes DB docker container and DB backup restore.
│  │  ├─ webtier/
│  │  │  ├─ tasks/
│  │  │  │  ├─ main.yml		# Ansible task which executes commands to replace the rates/config.py values dynamically, build API docker image, and run rates API container.
│  │  │  ├─ templates/
│  │  │  │  ├─ Dockerfile	# Dockerfile with instructions to build the rates API image.
│  ├─ site.yml			# Ansible master playbook which executes the roles.
control_node_setup.sh		# Shell script to setup environment for Control node.
host_setup.sh			# Shell script to setup environemnt for Manged node. 
README.md
```
### Dynamically pass configuration values
In order to change the ```rates/config.py``` values based on the environment, you can use the ```inventories/dev/group_vars/all.yml``` file. This file consists of all the required variables which are related to the development environment.
```
docker_network_alias: "devsql"
doc_root: "/tmp/app"
name: "postgres"
username: "postgres"
hostname: "{{ docker_network_alias }}"
```

Once you deploy the environment, it will create two separate docker containers for API service and DB service. To enable the communication between API and DB these containers are attached to the same network and the DB container has a network alias (---network alias). Therefore, the API service can use the same network alias name as the database hostname.

Replacement of ```rates/config.py`` is done by ansible regex replacement as shown below. The reason is to do it in such a way, is because not required to do any changes in the application code. The automation will consume the API code as it is and values are dynamically changing before building the docker image.
```
...
- name: Replace database hostname
replace:
path: "{{ doc_root }}/rates/config.py"
regexp: '(?i)\"host\": \"localhost\"'
replace: '"host": "{{ hostname }}"'
...
```

### Tools & Technologies 
1. **Ansible** - It is very easy to deploy multitier apps quickly using ansible. Since ansible works over SSH no need to install additional daemons or services. Also, the scripts are written in YAML format and it is very easy to write and read. As per the requirement, this automation should be able to deploy locally, physical machines, or the VMs in the cloud, and it is very easy to address such requirements using ansible.
2. **Docker** - Docker has been used to run the DB service and API service. Docker enables to ship and run applications as lightweight containers. That helps to easily build & deploy applications towards different environments.
