# redisEnterpriseVault - Redis Enterprise integrated with Hashicorp Vault to migrate data from postgresql using redis connect

## Purpose

Redis Connect Demo integrating Redis Enterprise and Postgresql with Hashicorp Vault with all components running in kubernetes.
Optional path is included to deploy without Vault.

&nbsp;

## Outline

- [Overview](#overview)
- [Important Links](#important-links)
- [Technical Overview](#technical-overview)
- [Instructions](#instructions)
  - [GKE Automated Instructions](#gke-automated-instructions)
    - [Terraform Creation](#terraform-creation)
    - [Terraform Destroy](#terraform-destroy)
    - [Terraform Troubleshooting](#terraform-troubleshooting)
    - [General notes on terraform/ansible](#general-notes)
  - [OpenShift Automated Instructions](#openshift-automated-instructions)
    - [Run Ansible OpenShift](#run-ansible-openshift)
    - [Run Ansible K8s Jobs](#run-ansible-k8s)
    - [Destroy OpenShift Environment](#destroy-openshift-environment)
  - [Run Manually](#run-manually)
    - [Prepare repository working directories](#prepare-repository-working-directories)
    - [Choose GKE or OpenShift](#choose-gke-or-openshift)
      - [Create GKE cluster](#create-gke-cluster)
      - [Create OpenShift cluster](#create-openshift-cluster)
    - [Install Redis Enterprise k8s](#install-redis-enterprise-k8s)
    - [Create Redis Enterprise Databases](#create-redis-enterprise-databases)
    - [Add Redisinsights](#add-redisinsights)
    - [Install Kubegres](#install-kubegres)
    - [Vault](#vault)
    - [Redis Connect](#redis-connect-configuration)
      - [Redis Connect with Vault](#redis-connect-with-vault)
      - [Redis Connect without Vault](#redis-connect-without-vault)
  - [Validate Environment](#validate-environment)
    - [Validate Database Admin Access](#validate-database-admin-access)
    - [Validate Redisinsights](#validate-redisinsights)
    - [Validate Vault Redis Database access](#validate-vault-access)
    - [Test Redis Connect Replication](#test-redis-connect-replication) 
- [Debug Ideas](#debug-ideas)
  
&nbsp;

## Overview
Set up full set of tools to do redis connect or RDI between postgresql and redis enterprise using GKE cluster or Openshift cluster and vault.  All software pieces 
will run in separate namespaces in a GKE or Openshift cluster.   This github also supports setting up an active/active k8s cluster. 
![Solution Diagram](images/redis_connect_k8s_postgres.png)

## Important Links

* [Set up vault on GKE](https://learn.hashicorp.com/tutorials/vault/kubernetes-google-cloud-gke)
* [Redis Connect Tips](https://github.com/Redislabs-Solution-Architects/redis-connect-k8s-helpers)
* [Kubegres is a kubernetes operator for postgresql](https://www.kubegres.io/)
* [Postgres with k8s](https://groups.google.com/g/ansible-project/c/RGh5Q-ODz50)
* [Redis Enterprise k8s github](https://github.com/RedisLabs/redis-enterprise-k8s-docs)
* [Redis Enterprise k8s quickstart docs](https://docs.redis.com/latest/kubernetes/deployment/quick-start/)
* [Redis Enterprise k8s docs](https://docs.redis.com/latest/kubernetes/deployment/)
* [Hashicorp Vault plugin on Redis Enterprise k8s](https://github.com/RedisLabs/vault-plugin-database-redis-enterprise/blob/main/docs/guides/using-the-plugin-on-k8s.md)
* [Redis Connect Postgres Sample](https://github.com/redis-field-engineering/redis-connect-dist/tree/main/examples/postgres)
* [Kubernetes Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
* [Install RedisInsights on k8s](https://docs.redis.com/latest/ri/installing/install-k8s/)
* [Vault k8 injector](https://www.vaultproject.io/docs/platform/k8s/injector)
* [Using Jinja2 Template in Ansible](https://www.linuxtechi.com/configure-use-ansible-jinja2-templates/)
* [Installing OpenShift on GCP](https://docs.openshift.com/container-platform/4.11/installing/installing_gcp/installing-gcp-customizations.html)
* [Deploy Redis Enterprise with OpenShift CLI](https://docs.redis.com/latest/kubernetes/deployment/openshift/openshift-cli/)
* [Redis Enterprise k8s Clusters-REC](https://docs.redis.com/latest/kubernetes/re-clusters/)
* [Redis Enterprise k8s databases-REDB](https://docs.redis.com/latest/kubernetes/re-databases/)
* [Redis Enterprise k8s active-active](https://docs.redis.com/latest/kubernetes/active-active/)

## Technical Overview

* Can use terraform/ansible automation to do complete automated install and configuration of this environment
* Or, follow the instructions using link above to "Set up vault on GKE" or "Installing OpenShift on GCP".  
  * At this point, these manual steps are stale as emphasis has been on the automated steps.
* Install Redis Enterprise on k8s using "Redis Enterprise k8s" link
* Set up Postgresql using Kubegres
* If using Vault, Setup Vault and "Hashicorp Vault plugin on Redis Enterprise k8s"
* Work through Redis Connect or RDI using "With" or "Without" vault.  Note:  Have not tried RDI with vault

&nbsp;

---

&nbsp;

## Instructions
Choose to do GKE or do OpenShift as kickoff script is completely different
***IMPORTANT NOTE**: Creating this demo application in your GCP account will create and consume GCP resources, which **will cost money**.

### GKE Automated Instructions
This terraform ansible setup has been tested on an AMD64 and ARM64 mac.  It needs some additional pip installs

**NOTE** you must have posgtresql binaries installed before `pip3 install psycopg2`

* apply additional pip installs
```bash
pip3 install requests
pip3 install google-auth
pip3 install kubernetes
pip3 install psycopg2
```
* Troubleshooting on the psycopg2 install.  *this was not needed on arm64* , arm64 needed postresql 14 installed to prevent
error on pip3 install psycopg2. Used *brew install postgresql@14* on arm64.  
  * Use [this psycopg2 install debug](https://stackoverflow.com/questions/27264574/import-psycopg2-library-not-loaded-libssl-1-0-0-dylib)   
  * The suggestion that worked for me was this
```bash
pip3 install --global-option=build_ext \
            --global-option="-I/usr/local/opt/openssl/include" \
            --global-option="-L/usr/local/opt/openssl/lib" psycopg2
```
### Run GKE
* set the parameters in the main [terraform job file](terraform/test/main.tf)
  * do_vault, do-postgres, do_redis_connect, and do_rdi are main control switches for what pieces of the ansible run
  * main.tf file includes version information such as redis enterprise version, vault chart version
    * it is very important to get the desired redis-enterprise version or the initial install will fail
      * Go to the redis documentation [quick start operator bundle](https://docs.redis.com/latest/kubernetes/deployment/quick-start/#download-the-operator-bundle)
      * Click on the button [releases](https://github.com/RedisLabs/redis-enterprise-k8s-docs/releases)
      * enter the release with the tag (it starts with a v)
    * check the redis enterprise database version and ensure modules have the correct versions
      * click on the link above containing the v to get redis enterprise database version from the Images section
      * go to [redis enterprise release notes](https://docs.redis.com/latest/rs/release-notes/) for this database version
      * scroll down to the Redis Stack for this version and note the versions for timeseries module
      * update [redis-meta.yml](demo/redis-meta.yml) for the correct timeseries version found above
      * Gears is a separate download and installation into the redis nodes so need to adjust gears version in several places
        * *this is only needed if using RDI*
        * Can find [the latest gears version](https://docs.redis.com/latest/stack/release-notes/redisgears/)
        * update [redis-enterprise-database.yml](demo/redis-enterprise-database-gears.yml) for the correct gears version
        * update the parameter for the gears version in [main.yml](terraform/ansible-gke/gke-test/vars/main.yml)
    * to check the vault versions use [this hashicorp link](https://developer.hashicorp.com/vault/docs/platform/k8s/helm)
  * no need to set the variables in [main parameter file](terraform/ansible-gke/gke-test/vars/main.yml)
  * this parameter file is only needed for reruns to disable parts of the operation 
  
#### Terraform creation
kick off the terraform creation-the gke creation takes a very long time-over 10 minutes
```bash
cd terraform/test
terraform init
terraform apply --auto-approve
```
#### GKE console access
GKE console access is available through the GCP console kubernetes link.  The cluster name comes from the cluster_name_final terraform variable which is held in [](test/main.tf)

#### Terraform destroy
* to remove everything
  * can have issues with the deletion of GKE.  Run delete script first.
```bash
cd demo
./destroy.sh
cd ../terraform/test
terraform destroy --auto-approve
```

#### Terraform troubleshooting
* many errors are just terraform timing issues so can just repeat the apply or destroy and it will work
* output such as vault keys will be in ./terraform/ansible-gke/temp
* Can control which terraform pieces are built using the variable in this file
	terraform/ansible-gke/gke-test/vars/main.yml
* terraform destroy has issues.  Manual deletion of gke cluster is often needed as destroy fails
#### General notes
There are several locations for parameters.  
* The first is in *terraform/test/main.tf*  This is only for GKE
  * these four boolean parameters control whether vault, postgres, redis-connect, and redis data integration are created:  do_vault, do_postgres, do_redis_connect, do_rdi
* When running GKE or Openshift manually, these same parameters are important in ./terraform/ansible-gke 
  * see the files manual_run_gke.sh or manual_run_openshift.sh for the environment settings in these scripts 
  * NOTE:  parameters don't have the *do_* prefix so paraemeters are gke, vault, postgres, redis_connect, and rdi
* The second is in *terrafrom/ansible-gke/gke-test/vars/main.yml*  This is for both GKE and OpenShift
  * The parameters in vars/main.yml control which tasks run
  * By manipulating these parameters certain parts of the ansible can be run leaving other parts intact
  * Combine the use of parameters with the deletion of a namespace can selectively rebuild part a namespace
  * `kubectl delete namespace vault`  and `kubectl delete namespace redis-connect` work very well
  * after deleting the namespace, set all the variables in vars/main.yml to False except for the task rebuilding the deleted namespace
* terraform parameters are copied to the ansible environment in *terraform/provisioning.tf*
* Even if no changes are needed to the GKE cluster, the ansible deployment is kicked off by the terraform script.

### OpenShift Automated Instructions
OpenShift automation does not use terraform at all.  Openshift automation only uses ansible because the actual installation of the OpenShift cluster is automated by Openshift (using terraform internally) by installing client software and using 
this client to automate the install on GCP.   For simplicity, this GitHub automates this installation using ansible.  Following the use of ansible to install OpenShift, 
the same ansible that is used in the GKE automation of the Redis Enterprise, PostgreSQL, Hashicorp Vault, and Redis Connect is also used with OpenShift.
There are a few minor differences but parametrization takes care of the differences.

#### Run ansible OpenShift 
* Prepare to run openshift ansible
  * [This script follows these OpenShift on GCP steps](https://docs.openshift.com/container-platform/4.11/installing/installing_gcp/installing-gcp-customizations.html)
  * Use the latest openshift version [supported by redis enterprise operator](https://github.com/RedisLabs/redis-enterprise-k8s-docs/releases)
  * Update the variables for your environment. Set your own cluster, etc. name. Get your own service account key and reference that.
```bash
cp ansible-openshift/gcp/vars/main.yml.template ansible-openshift/gcp/vars/main.yml
```
Edit `main.yml` to set your environment. There are many `REPLACEME` entries you must replace with your environment.

You'll also need to export the GOOGLE_APPLICATION_CREDENTIALS environment variable to point to your service account key, e.g.,
```bash
export GOOGLE_APPLICATION_CREDENTIALS=/Users/<your home dir>/.gcp/central-beach-194106-abcdefg.json
```

```bash
cd ansible-openshift
./manual.sh
```
When the above script finishes it will output an *export KUBECONFIG* command.  Use this command to allow the *oc* and/or *kubectl* commands to work.  These binaries (oc and kubectl) are in the ./ansible-openshift/binaries directory
* Can find all of these values in *ansible-openshift/install-files/.openshift_install.log*.   Can find the full openshift console address, password for kubeadmin, and KUBECONFIG environment variable.
* Openshift console access is available using *https://console-openshift-console.apps.<ocp-cluster_name>.<openshift_cluster_base_domain>*
  * find these values in the [vars main yaml file](ansible-openshift/gcp/vars/main.yml)
* Username is kubeadmin and the password is in the file [](ansible-openshift/install-files/auth/kubeadmin-password)
#### Run ansible k8s
Run ansible k8s steps to configure postgres, redis enterprise, etc
* Verify the parameters in [main parameter file](terraform/ansible-gke/gke-test/vars/main.yml).  These should only need to be changed on rerun/error conditions
* Check the [ansible script environment variables](terraform/ansible-gke/manual_run_openshift.sh)
* it is very important to know the desired redis-enterprise version to have the correct module versions as RDI needs redis gears and redis connect needs timeseries
* This openshift install doesn't really allow the choice of the redis operator and redis database versions.  Install relies on cloning the redis-enterprise k8s repository and using the version in this repository.  If you want an older version, need to set your branch that earlier version. 
  * NOTE:  redis operator install steps changed after 6.2.18-41.  This ansible script will no longer work with 6.2.18-41 and earlier versions.
  * to clone use *git clone https://github.com/RedisLabs/redis-enterprise-k8s-docs.git*
  * Set the branch to the Redis operator version you want, e.g., `6.4.2-8` or `7.2.4-2`, etc. Choosing the `master` branch will give you the latest.
  * update the redis operator version in [manual_run_openshift](terraform/ansible-gke/manual_run_openshift.sh)
* To see the redis operator version in the github, check this file *openshift.bundle.yaml* and search for this string in the file */redis-enterprise-operator:*
* check the redis enterprise database version and ensure modules have the correct versions
  *Click on the button [releases](https://github.com/RedisLabs/redis-enterprise-k8s-docs/releases)
  * enter the release with the tag (it starts with a v)
  * click on the link above containing the v to get redis enterprise database version from the Images section
  * go to [redis enterprise release notes](https://docs.redis.com/latest/rs/release-notes/) for this database version
  * scroll down to the Redis Stack for this version and note the versions for timeseries module
  * update [redis-meta.yml](demo/redis-meta.yml) for the correct timeseries version found above
  * Gears is a separate download and installation into the redis nodes so need to adjust gears version in several places
    * *this is only needed if using RDI*
    * Can find [the latest gears version](https://docs.redis.com/latest/stack/release-notes/redisgears/)
    * update [redis-enterprise-database.yml](demo/redis-enterprise-database-gears.yml) for the correct gears version
    * update the parameter for the gears version in [main.yml](terraform/ansible-gke/gke-test/vars/main.yml)
* to check the vault versions use [this hashicorp link](https://developer.hashicorp.com/vault/docs/platform/k8s/helm)
  * verify you have the vault, postgres, redis_connect and rdi variable set appropriately
  * verify the redis_enterprise version
* Kick off the ansible script

```bash
# better to use the full path here from KUBECONFIG returned above
export KUBECONFIG=./ansible-openshift/install-files/auth/kubeconfig
cd  terraform/ansible-gke
./manual_run_openshift.sh
```
At the end of the ansible execution, the current files are copied over to *./terraform/ansible-gke/temprun-<rec_name>*

#### Destroy openshift environment
```bash
cd ./ansible-openshift
./binaries/openshift-install destroy cluster --dir install-files
```

### Active-Active
Many of the pieces are in place for active/active in this github.  The steps are taken from this [redis k8s active/active link](https://docs.redis.com/latest/kubernetes/active-active/)
* the [prepare clusters steps are completed](https://docs.redis.com/latest/kubernetes/active-active/prepare-clusters/)
  * Admission controller is configured
  * If openshift, route is created.  If GKE, haproxy is created
  * Necessary DNS entry is created in Cloud DNS to access the cluster from the route or haproxy
  * The new secret for the cluster is created as *redis-enterprise-rerc-test-rec-1* where *test-rec-1* is the redis enterprise rec name
    * *./terraform/ansible-gke/temprun-<rec_name>/demo/rerc-secrets-<rec_name>.yaml* contains the secret contents.  This has been applied to the current cluster but will be needed for the other cluster(s) 
  * The rerc record yaml is also created for this cluster but has not been applied because the rerc files only need to be applied to one of the participating clusters
    * *./terraform/ansible-gke/temprun-<rec_name>/demo/rerc-<rec_name>.yaml* contains the rerc definition
  * To switch between environments using openshift is just setting the KUBECONFIG environment variable
    * (first cluster) export KUBECONFIG=/Users/jason.haugland/gits/redisEnterpriseVault/ansible-openshift/install-files/auth/kubeconfig
    * (second cluster) export KUBECONFIG=/Users/jason.haugland/gits/redisEnterpriseVault/ansible-openshift/install-files-2/auth/kubeconfig
  * Verify can connect to both clusters
    * edit demo/testroute one cluster
    * test that cluster
```bash
cd demo
./testroute.sh
```
* repeat for second cluster

#### Set environment to first cluster
```bash
export KUBECONFIG=/Users/jason.haugland/gits/redisEnterpriseVault/ansible-openshift/install-files/auth/kubeconfig
```
#### Create remote cluster secret
```bash
kubectl -n demo apply -f temprun-test-rec-2/demo/test-rec-2-rerc-secrets.yaml
```
#### Create remote clusters
```bash
cd terraform/ansible-gke/
kubectl -n demo create -f temprun-test-rec-1/demo/rerc-test-rec-1.yaml
kubectl -n demo create -f temprun-test-rec-2/demo/rerc-test-rec-2.yaml
# verify rerc is good
kubectl -n demo get rerc
```
Output should match ![](images/get_rerc_valid.png)

#### Create AA DB
```bash
kubectl -n demo create -f temprun-test-rec-1/demo/reaadb.yaml
```

The route should be created, but I think a CNAME for the route needs to be created as well.




### Run manually
These manual steps have not been actively maintained and are stale at this point.

&nbsp;

There are a large number of directories to keep track of files.  A provided script will set up the following environment variables to make the task less arduous.  
Another tip would be to have a window opened to each of the directories instead of relying on one terminal session.  
Additionally, label each terminal session for the directory path in use.

### Prepare repository working directories
To get all of these moving parts working, multiple repositories are needed.  Then, a large number of directory changes are needed as different pieces are deployed.  
To facilitate this, first set up the environment with a provided scripts and then pull all the necessary repositories.  Decide on one home git directory that will hold all the subdirectories needed.  The default in the environment script is ```$HOME/gits```
* Move to chosen git directory home and pull down the repositories
```bash
git clone https://github.com/jphaugla/redisEnterpriseVault.git
git clone https://github.com/RedisLabs/redis-enterprise-k8s-docs.git
git clone https://github.com/redis-field-engineering/redis-connect-dist.git
```
* edit and then source the environment files for subsequent steps
```bash
cd redisEnterpriseVault
source setEnvironment.sh

```
### Choose GKE or OpenShift
#### Create GKE cluster 

Tips on installing GKE
* Easier to use GCP console to get the desired node size.
* Make sure compute nodes are decent size *e2-standard-8*.  
* Start with 3 nodes in the default node pool-can always increase as needed.
* Once the GKE cluster is created, connect to the cluster.  To do this:
    * Click on newly created cluster
![Select GKE Cluster](images/SelectGKEcluster.png)
    * Click to connect to the cluster
![Connect to Cluster](images/ConnectToCluster.png)
    * Follow the command-line access instructions to prepare for the subsequent steps

#### Create OpenShift cluster
* [Installing OpenShift on GCP](https://docs.openshift.com/container-platform/4.11/installing/installing_gcp/installing-gcp-customizations.html)

### Install Redis Enterprise k8s
* Get to redis enterprise k8s docs directory
```bash
cd $GIT_RE_K8S
```
* For GKE, follow [Redis Enterprise k8s installation instructions](https://docs.redis.com/latest/kubernetes/deployment/quick-start/) using *demo* as the namespace.  Stop before the step to *Enable the Admission Controller".  This step is not needed
* For OpenShift, follow [Redis Enterprise deployment with OpensShift)(https://docs.redis.com/latest/kubernetes/deployment/openshift/openshift-cli/)
### Create redis enterprise databases
* A separate role is created for each database.  This is *VERY IMPORTANT* for effectively using the plugin.  Each database needs a separate role only for that database.  If a common role is used across all databases in a large cluster, the performance aspect can be very significant, 
* Create two redis enterprise databases.  The first database is the Target database for redis connect and the second stores meta-data for redis-connect
  * If, the redis-meta database doesn't create, it may be the version of the timeseries module as it must fit with the deployed version.  Verify the module version for this redis enterprise version using [the release notes](https://docs.redis.com/latest/rs/release-notes/)
```
* get the cluster password for use in the curl command substituting out the 5IcX7yYD with the correct password to create a role 
* the ports are hardcoded in the yaml files for each database, redis-enterprise-database is 12000 and redis-meta is 120001
```bash
./getClusterUnPw.sh
```
```bash
cd $DEMO
curl -v -k -u demo@redislabs.com:5IcX7yYD -X POST https://localhost:9443/v1/roles -H Content-type:application/json  -d '{"name":"db1","management":"admin"}'
curl -v -k -u demo@redislabs.com:5IcX7yYD -X POST https://localhost:9443/v1/roles -H Content-type:application/json  -d '{"name":"db2","management":"admin"}'
kubectl apply -f redis-enterprise-database.yml
kubectl apply -f redis-meta.yml
```
* get the database password
```bash
./getDatabasePw.sh
```
#### Add Redisinsights 
These instructions are based on [Install RedisInsights on k8s](https://docs.redis.com/latest/ri/installing/install-k8s/)
&nbsp;
The above instructions have two options for installing redisinights, this uses the second option to install 
[without a service](https://docs.redis.com/latest/ri/installing/install-k8s/#create-the-redisinsight-deployment-without-a-service) (avoids creating a load balancer)
* The yaml file apply below, creates redisinsights
* Since no load balancer is deployed, must do a port-forward to be able to access redisinsights from the local machine's browser
* Easiest, to open a new terminal window and label the terminal window *redisinsights port forward*
```bash
kubectl apply -f redisinsight.yml
kubectl port-forward deployment/redisinsight 8001
```
* Can validate redisinsights using - [Validate Redisinsights](#validate-redisinsights)

### Install Kubegres
Based on the instructions so also read these as steps are performed for deeper explanation [Kubegres getting started](https://www.kubegres.io/doc/getting-started.html)
This creates kubegres, creates a postgres.conf configmap to enable postgres replication, adds postgres database and password, and creates the one node database
The replication technique with the configmap uses this link  [Override default configs](https://www.kubegres.io/doc/override-default-configs.html).  
```bash
cd $POSTGRES
kubectl apply -f https://raw.githubusercontent.com/reactive-tech/kubegres/v1.16/kubegres.yaml
kubectl create namespace postgres
kubectl config set-context --current --namespace=postgres
kubectl apply -f postgres-conf-override.yaml
kubectl apply -f my-postgres-secret.yaml
kubectl apply -f my-postgres.yaml
```
* create database and tables needed for redis-connect
  * find the pod name for postgres 
  * copy database and table creation to pod 
  * use the password in the my-postgres-secret.yaml file when prompted with psql
```bash
cd $SAMPLES
kubectl get pods
kubectl -n postgres cp postgres_cdc.sql mypostgres-1-0:/
kubectl -n postgres exec --stdin --tty  mypostgres-1-0 -- /bin/sh
psql -Upostgres -W
\i postgres_cdc.sql
```

### Vault

#### Install helm and vault on GKE
* Reference both of these links
  * [Set up vault on GKE](https://learn.hashicorp.com/tutorials/vault/kubernetes-google-cloud-gke)
  * [Hashicorp Vault plugin on Redis Enterprise k8s](https://github.com/RedisLabs/vault-plugin-database-redis-enterprise/blob/main/docs/guides/using-the-plugin-on-k8s.md)
NOTE: The override values being used turns on trace level debug which is great in a test/github setting but should be reduced for production environments.
```bash
cd $VAULT
kubectl create namespace vault
kubectl config set-context --current --namespace=vault
brew install helm
brew install jq
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
# this one is for gke
helm install vault hashicorp/vault --namespace vault -f override-values.yaml
# this one is for openshift
helm install vault hashicorp/vault --namespace vault -f override-values-openshift.yaml
```  
#### unseal the vault
* This follows the technique from within this link [Set up vault on GKE](https://learn.hashicorp.com/tutorials/vault/kubernetes-google-cloud-gke).  Read this section for explanation of these commands.
* The operator init writes pertinent keys to the cluster-keys.json file for safe keeping, obtain unseal key, unseal the vault and display status
```bash
kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
export VAULT_UNSEAL_KEY=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[]")
kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec vault-0 -- vault status
```
* To use the vault, a token is needed.  For this exercise, use the root token to login

```bash
cat cluster-keys.json | jq -r ".root_token"
export CLUSTER_ROOT_TOKEN=$(cat cluster-keys.json | jq -r ".root_token")
kubectl exec vault-0 -- vault login $CLUSTER_ROOT_TOKEN
```
#### Download the plugin file
Make sure you grab the correct file-many similarly named files
* download vault-plugin-database-redis-enterprise_0.1.3_linux_amd64
https://github.com/RedisLabs/vault-plugin-database-redis-enterprise/releases
* need to change the permissions, copy the file to the vault container, and pull the shasum for used later
```bash
mv ~/Downloads/vault-plugin-database-redis-enterprise_0.1.3_linux_amd64 $VAULT
kubectl cp -n vault $VAULT/vault-plugin-database-redis-enterprise_0.1.3_linux_amd64 vault-0:/usr/local/libexec/vault
shasum -a 256 $VAULT/vault-plugin-database-redis-enterprise_0.1.3_linux_amd64| awk '{print $1}'
```
* get the cluster and database password information for use while logged into vault
```bash
$DEMO/getDatabasePw.sh
$DEMO/getClusterUnPw.sh
```
####  log to vault container and enable vault plugin
Use the shasum value pulled from above and not the current value set equal to sha256
```bash
kubectl -n vault exec --stdin=true --tty=true vault-0 -- /bin/sh
vault write sys/plugins/catalog/database/redisenterprise-database-plugin command=vault-plugin-database-redis-enterprise_0.1.3_linux_amd64 sha256=739421599adfe3cdc53c8d6431a3066bfc0062121ba8c9c68e49119ab62a5759
```
#### Create database configurations in vault
Using the information from the getClusterUnPw.sh script from above and using the username and password valued for redis enterprise cluster authentication.   
For additional explanations peruse [Hashicorp Vault plugin on Redis Enterprise k8s](https://github.com/RedisLabs/vault-plugin-database-redis-enterprise/blob/main/docs/guides/using-the-plugin-on-k8s.md)
```bash
chmod 755 /usr/local/libexec/vault/vault-plugin-database-redis-enterprise_0.1.3_linux_amd64
vault secrets enable database
vault write database/config/demo-test-rec-redis-enterprise-database plugin_name="redisenterprise-database-plugin" url="https://test-rec.demo.svc:9443" allowed_roles="*" database=redis-enterprise-database username=demo@redislabs.com password=vubYurxK
vault write database/config/demo-test-rec-redis-meta plugin_name="redisenterprise-database-plugin" url="https://test-rec.demo.svc:9443" allowed_roles="*" database=redis-meta username=demo@redislabs.com password=vubYurxK
```
#### Create database roles
* as mentioned above, is important each database uses its own role here for creating the dynamic usernames.  Sharing one role in the cluster across databases can cause performance problems.
```bash
vault write database/roles/redis-enterprise-database db_name=demo-test-rec-redis-enterprise-database creation_statements="{\"role\":\"db1\"}" default_ttl=90m max_ttl=100m
vault write database/roles/redis-meta db_name=demo-test-rec-redis-meta creation_statements="{\"role\":\"db2\"}" default_ttl=90m max_ttl=100m
```

* Can validate the redis database at this point using  - [Validate Redis Databases](#validate-redis-databases)

#### Authorize kubernetes
* using vault terminal connection...   
```bash
vault auth enable kubernetes
vault secrets enable kubernetes
vault write auth/kubernetes/config \
token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```
* don't log out of vault, keep vault connection in a separate terminal and use the vault terminal as directed

### Redis Connect Configuration
* create service account and namespace
  * service account is only needed if using vault integration
```bash
cd $REDIS_CONNECT
kubectl create namespace redis-connect
kubectl config set-context --current --namespace=redis-connect
kubectl create sa redis-connect
```
#### Redis Connect With Vault
not needed if not doing vault (skip to [Redis Connect Without Vault](#redis-connect-without-vault))
* go to vault terminal
```bash
vault write database/config/kube-postgres \
    plugin_name=postgresql-database-plugin \
    allowed_roles="redis-connect" \
    username="postgres" \
    password="jasonrocks" \
    connection_url="postgresql://{{username}}:{{password}}@mypostgres.postgres.svc:5432/RedisConnect?sslmode=disable"
vault write database/roles/redis-connect \
    db_name=kube-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH REPLICATION LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
         GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; \
         ALTER USER \"{{name}}\" WITH SUPERUSER;" \
    default_ttl="60m" \
    max_ttl="60m"
```
* create redis-connect policy and role
```bash
vault policy write redis-connect-policy - <<EOF
 path "database/creds/redis-enterprise-database" {
   capabilities = ["read"]
 }
 path "database/creds/redis-meta" {
   capabilities = ["read"]
 }
path "database/creds/redis-connect" {
  capabilities = ["read"]
}
EOF

vault write auth/kubernetes/role/redis-connect \
    bound_service_account_names=redis-connect \
    bound_service_account_namespaces=redis-connect \
    policies=redis-connect-policy \
    ttl=24h
```
* create configmap with jobmanager.properties
  * this configmap is used in the redis-connect-start.yaml to mount files appropriately
* start the redis-connect server
```bash
$DEMO/getDatabasePw.sh
vi jobmanager.properties
kubectl create configmap redis-connect-config \
  --from-file=jobmanager.properties=jobmanager.properties 
  --from-file=logback.xml=logback.xml 
kubectl apply -f vault/redis-connect-start.yaml
```
#### Redis Connect Without Vault
* Edit the jobmanager.properties file for the correct connection parameters in redis.connection.url
  * these parameters can be retrieved using ```$DEMO/getDatabasePw.sh```
* Edit each credentials file for the appropriate connection information
  * For redisconnect_credentials_jobmanager.properties (redis-meta) and redisconnect_credentials_redis_postgres-job.properties (redis-enterprise-db) can use a null username and the password from getDatabasePw.sh
* create configmap with jobmanager.properties and the credentials files
  * this configmap is used in the redis-connect-start.yaml to mount files appropriately
* start the redis-connect server
```bash
$DEMO/getDatabasePw.sh
vi jobmanager.properties
kubectl create configmap redis-connect-config \
  --from-file=jobmanager.properties=jobmanager.properties \
  --from-file=logback.xml=logback.xml 
  --from-file=redisconnect_credentials_jobmanager.properties=redisconnect_credentials_jobmanager.properties \
  --from-file=redisconnect_credentials_redis_postgres-job.properties=redisconnect_credentials_redis_postgres-job.properties \
  --from-file=redisconnect_credentials_postgresql_postgres-job.properties=redisconnect_credentials_postgresql_postgres-job.properties 
kubectl apply -f non-vault/redis-connect-start.yaml
```

## Validate Environment
### Validate database admin access
* port forward from kubernetes service to local port
```bash
kubectl port-forward -n demo service/redis-enterprise-database 12000
kubectl port-forward -n demo service/redis-meta 12001
```
* access the redis-enterprise-database (port 12000) and redis-meta (port 12001) using the passwords from demo/getDatabasepw.sh
```
demo/getDatabasepw.sh
redis-cli -p 12000 -a 0BPpoREJ
>set jason cool
redis-cli -p 12001 -a 0XyzJPH1
>set jason uncool
```

### Validate redisinsights

* port forward to access redisinsights and each database to connect to
```bash
kubectl port-forward -n demo deployment/redisinsight 8001

```
* from chrome or firefox, open the browser using http://localhost:8001
* Click "I already have a database"
* Click "Connect to Redis Database"
* Create Connection to target redis database with following parameter entries

| Key      | Value                                                       |
|----------|-------------------------------------------------------------|
| host     | redis-enterprise-database.demo                              |
| port     | 12000 (can get from demo/getDatabasepw.sh but is hardcoded) |
| name     | TargetDB                                                    |
| Username | (leave blank)                                               |
| Password | DrCh7J31 (from demo/getDatabasepw.sh above)                 |
* click ok
*repeat steps above for metadata database using following parameters

| Key      | Value                                                       |
|----------|-------------------------------------------------------------|
| host     | redis-meta.demo                                             |
| port     | 12001 (can get from demo/getDatabasepw.sh but is hardcoded) |
| name     | metaDB                                                      |
| Username | (leave blank)                                               |
| Password | FW2mFXEH (from demo/getDatabasepw.sh above)                 |

### Validate vault access
Only execute these steps if running with vault 
* port forward to access the databases from local machine port
* port forward from kubernetes service to local port
```bash
kubectl port-forward -n demo service/redis-enterprise-database 12000
kubectl port-forward -n demo service/redis-meta 12001
```

NOTES:  
* the redis-cli command is using the username and password from the output of the vault read database command
* the vault read command must be done from the vault terminal 
  * can log in to the vault container using  ```kubectl exec -n vault --stdin=true --tty=true vault-0 -- /bin/sh```
* From vault for redis-enterprise-database

```bash
vault read database/creds/redis-enterprise-database
      Key                Value
      ---                -----
      lease_id           database/creds/redis-enterprise-database/JVsEvOrtZfK46dMO7GWRxjTW
      lease_duration     90m
      lease_renewable    true
      password           blZxlE10AS-zy-UBbjdh
      username           v_root_redis-enterprise-database_sruv9v0fewy2rv4m1oxq_1646252982
```
* From vault for redis-meta 
```bash
vault read database/creds/redis-meta
      Key                Value
      ---                -----
      lease_id           database/creds/redis-meta/iahGKJ9XNkisGsyLgW89Ohpt
      lease_duration     90m
      lease_renewable    true
      password           Vfo2ajqBvWAVKFyI-ojR
      username           v_root_redis-meta_n2dkafecjttws9mzj9eg_1646411445
```
Open a new terminal window  and test each database using the username and password values from the vault read database output
* redis-enterprise-database
```bash
redis-cli -p 12000
>AUTH v_root_redis-enterprise-database_sruv9v0fewy2rv4m1oxq_1646252982 blZxlE10AS-zy-UBbjdh
```
* redis-meta
```bash
redis-cli -p 12001
>AUTH v_root_redis-meta_n2dkafecjttws9mzj9eg_1646411445 Vfo2ajqBvWAVKFyI-ojR
```

### Test redis connect replication
This section will define the redis-connect job using an API approach.  For more detail on the redis-connect swagger interface, see this
[demo section](https://github.com/redis-field-engineering/redis-connect-dist/examples/postgres/demo) in redis connection github
In another terminal, need to port-forward the rest API interface to set up the actual job
* first get the redis-connect pod name with kubectl get all
* use the pod name to port-forward the port
```bash
kubectl -n redis-connect get all
kubectl -n redis-connect port-forward pod/redis-connect-59475bcdd4-nwv5v 8282
```
Use the [swagger interface]( http://localhost:8282/swagger-ui/index.html) to define the job and control the job execution
* Save the job configuration using swagger interface ![swagger](images/swagger1.png)
  * click on *QUICK START* 
  * click on *POST* *SAVE Job Configuration* to bring up the API interface ![API](images/swagger-save-job.png)
  * click on *Try It Out*
  * Enter the jobname of *postgres-job*
  * Click on *Choose File* and select *redis-connect/postgres-job.json* 
  * Click on *Execute*
* Insert rows using postgres container
```bash
kubectl -n postgres exec --stdin --tty  mypostgres-1-0 -- /bin/sh
psql -Upostgres -W
\c "RedisConnect"
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (1, 'Allen', 'Terleto', 'FieldCTO', 1, '2018-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (2, 'Brad', 'Barnes', 'SA Manager', 1, '2019-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (3, 'Virag', 'Tripathi', 'Troublemaker', 1, '2020-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (4, 'Jason', 'Haugland', 'SA', 1, '2021-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (5, 'Ryan', 'Bee', 'Field Sales', 1, '2005-08-06', 20000, 10, 1);
```
* Run the initial bulk load of the job ![swagger start](images/swaggerStartjob.png)
  * Click on *POST* START Job to biring up the API interface ![API start](images/swagger-run-load.png)
  * click on *Try It Out*
  * Enter the jobname of *postgres-job*
  * Enter the jobtype of *load*
* Test the results
  * Use the [redisinsights](#add-redisinsights) to verify the data is loaded to redis
* Run the stream load ![swagger start](images/swaggerStartjob.png)
  * Click on *POST* START Job to bring up the API interface ![API start](images/swagger-run-load.png)
```bash
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (111, 'Simon', 'Prickett', 'Tech Advocate', 1, '2016-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (112, 'Doug', 'Snyder','Territory Manager', 1, '2021-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (113, 'Jason', 'Plotch', 'Territory Manager', 1, '2021-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (114, 'Nail', 'Sirazitdinov', 'TAM', 1, '2010-08-06', 20000, 10, 1);
INSERT INTO public.emp (empno, fname, lname, job, mgr, hiredate, sal, comm, dept) VALUES (115, 'Manish', 'Arora', 'SA', 1, '2021-08-06', 20000, 10, 1);
```
* Test the results
  * Use the [redisinsights](#add-redisinsights) to verify the data is loaded to redis
  
### Debug Ideas
* Redis-connect job [documentation link](https://github.com/redis-field-engineering/redis-connect-dist/tree/main/examples/postgres/demo#start-redis-connect)
* look for resulting rows in redis enterprise using redisinsight (see directions above)
* There are multiple methods to debug the running job.  Here are a few:
  * Find the pod name(s) for redis connect
  * get the logs for init and main container

```bash
kubectl -n redis-connect get pods
kubectl -n redis-connect logs pod/redis-connect-5cd54fcddd-8s5pj -c vault-agent-init
kubectl -n redis-connect logs pod/redis-connect-5cd54fcddd-8s5pj -c vault-agent
kubectl -n redis-connect logs pod/redis-connect-5cd54fcddd-8s5pj -c redis-connect
kubectl -n redis-connect exec --stdin --tty  pod/redis-connect-5cd54fcddd-8s5pj -- /bin/sh
```
  * log in to the pod and look at log files 
  * there is a debug line in redis-connect-start.yaml that keeps the pod running even if there are connection errors-this is great for debug
  * NOTE: check the swagger UI for API commands that are easier to use than redisconnect.sh
  * Check the file systems mounted correctly
```bash
cd logs
# investigate the log files 
vi *
# login to cli
cd ../bin
./redisconnect.sh cli
> validate connection -t JDBCConnectionProvider -i RDBConnection
exit
df -h
```
this should be output from the df -h
![df ouput](images/redis-connect-mounts.png)
  * Ensure each credential file is named correctly
  * Test the username/password from the credential file to ensure the connection works from the respective database
#### Troubleshooting k8s DNS
The install process automatically creates a dns utils pod to debug any networking issues
To debug use [these notes:](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)
