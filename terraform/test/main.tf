provider "google"{
}

module "mymodule" {
   source 		= "../"
   gcp_project          = "central-beach-194106"
   gcp_credentials_file = "/Users/eric.preston/.gcp/central-beach-194106-43b416572da2.json"
   cidr 		=  "10.3.0.0/16"
   region 		= "us-central1"
   cluster_name_final   = "epreston-gke"
   rec_name             = "test-rec-1"
   zone 		= "us-central1-a"
   redis_enterprise_version = "v6.4.2-8"
   vault_chart_version  = "0.24.0"
   gears_version        = "1.2.6"
   gke_release_channel  = "STABLE"
   postgres_pw          = "tomato"
   python_path          = "/opt/homebrew/bin/python3"
   do_vault             = false
   do_postgres          = false
   do_redis_connect     = false
   do_rdi               = false
   dns_domain           = "demo.redislabs.com"
   dns_name             = "demo-clusters"
}
