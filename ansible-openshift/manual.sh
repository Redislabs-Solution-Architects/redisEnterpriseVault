ansible-playbook  -vv --extra-vars cluster_state=present playbook.yml -e 'cluster_name=jph-openshift'  -e 'gcp_region=us-central1' -e 'gcp_project=central-beach-194106' -e 'ansible_python_interpreter=/usr/local/bin/python3' -e 'openshift_installer_url=https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp' -e 'openshift_version=latest-4.12' -e 'arm_prefix=amd64'
