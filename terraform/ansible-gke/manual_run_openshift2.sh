ansible-playbook  -vvv --extra-vars cluster_state=present playbook.yml -e 'cluster_name=epreston-openshift-2'  -e 'rec_name=test-rec-2' -e 'gcp_region=us-central1' -e 'gcp_project=central-beach-194106' -e 'ansible_python_interpreter=/opt/homebrew/bin/python3' -e 'gke=false' -e 'vault=false' -e 'postgres=false' -e 'rdi=false' -e 'redis_connect=false'  -e 'vault_chart_version=0.24.0' -e 'postgres_pw=jasonrocks'  -e 'redis_enterprise_version=v6.4.2-8' -e 'gears_version=1.2.6' -e 'gke_release_channel=STABLE' -e 'oc_path=../../ansible-openshift/binaries/oc' -e 'redis_enterprise_github=/Users/eric.preston/work/redis-enterprise-k8s-docs' -e 'KUBECONFIG=../../ansible-openshift/install-files-2/auth/kubeconfig' -e 'dns_domain=openshift.demo.redislabs.com' -e 'dns_name=openshift'
