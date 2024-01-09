variable "GOOGLE_PROJECT" {
  default     = "flux-kbot"
  type        = string
  description = "GCP project name"
}

variable "GOOGLE_REGION" {
  default     = "us-central1-c"
  type        = string
  description = "GCP region to use"
}

variable "GKE_CLUSTER_NAME" {
  type        = string
  default     = "flux"
  description = "GKE cluster name"
}

variable "GKE_POOL_NAME" {
  type        = string
  default     = "flux"
  description = "GKE pool name"
}

variable "GITHUB_OWNER" {
  type        = string
  description = "The GitHub owner"
}

variable "GITHUB_TOKEN" {
  type        = string
  description = "GitHub personal access token"
}

variable "FLUX_GITHUB_REPO" {
  type        = string
  default     = "flux-gke-gitops"
  description = "GitHub repository"
}

variable "repository_visibility" {
  type        = string
  default     = "private"
  description = "The visibility of the GitOps repository"
}

variable "target_path" {
  type        = string
  default     = "clusters"
  description = "Flux manifests subdirectory"
}

