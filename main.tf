module "gke_cluster" {
  source           = "github.com/Mardukay/tf-google-gke-cluster"
  GOOGLE_REGION    = var.GOOGLE_REGION
  GOOGLE_PROJECT   = var.GOOGLE_PROJECT
  GKE_NUM_NODES    = 2
  GKE_CLUSTER_NAME = var.GKE_CLUSTER_NAME
  GKE_POOL_NAME    = var.GKE_POOL_NAME
}

terraform {
  backend "gcs" {
    bucket = "mardukay_bucket"
    prefix = "terraform/state"
  }
}

resource "null_resource" "gke-get-credential" {
  depends_on = [module.gke_cluster]
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.GKE_CLUSTER_NAME} --zone ${var.GOOGLE_REGION} --project ${var.GOOGLE_PROJECT}"
  }
}

#create github repository for flux
module "git_repo" {
  source                   = "github.com/den-vasyliev/tf-github-repository"
  github_owner             = var.GITHUB_OWNER
  github_token             = var.GITHUB_TOKEN
  repository_name          = var.FLUX_GITHUB_REPO
  public_key_openssh       = module.tls_private_key.public_key_openssh
  repository_visibility    = var.repository_visibility
  public_key_openssh_title = "flux"
}

#create ssh key for repository
module "tls_private_key" {
  source = "github.com/den-vasyliev/tf-hashicorp-tls-keys"
}

#deploy flux to cluster and connect to github repository
provider "flux" {
  kubernetes = {
    config_path = module.gke_cluster.kubeconfig
  }
  git = {
    url = "https://github.com/${var.GITHUB_OWNER}/${var.FLUX_GITHUB_REPO}.git"
    http = {
      username = "git"
      password = var.GITHUB_TOKEN
    }
  }
}

resource "flux_bootstrap_git" "this" {
  path       = var.target_path
  depends_on = [module.git_repo, module.gke_cluster, module.tls_private_key, null_resource.gke-get-credential]
}

module "kubernetes-engine_workload-identity" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  use_existing_k8s_sa = true
  version = "29.0.0"
  name = "kustomize-controller"
  namespace = "flux-system"
  project_id = var.GOOGLE_PROJECT
  cluster_name = var.GKE_CLUSTER_NAME
  location = var.GOOGLE_REGION
  annotate_k8s_sa = true
  roles = ["roles/cloudkms.cryptoKeyEncrypterDecrypter"]
  depends_on = [null_resource.gke-get-credential, flux_bootstrap_git.this]
}

module "kms" {
  source             = "github.com/den-vasyliev/terraform-google-kms"
  project_id         = var.GOOGLE_PROJECT
  location           = "global"
  keyring            = "flux-kms-1"
  keys               = ["sops-key-flux"]
  prevent_destroy    =  false
}
