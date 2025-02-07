resource "google_project" "tsb" {
  count           = var.gcp_project_id == null ? 1 : 0
  name            = "${var.name_prefix}-${var.gcp_k8s_region}"
  project_id      = "${var.name_prefix}-${var.gcp_k8s_region}"
  org_id          = var.gcp_org_id
  billing_account = var.gcp_billing_id
}

module "gcp_base" {
  source      = "../../modules/gcp/base"
  count       = var.gcp_k8s_region == null ? 0 : 1
  name_prefix = "${var.name_prefix}-${var.gcp_k8s_region}"
  project_id  = var.gcp_project_id == null ? google_project.tsb[0].project_id : var.gcp_project_id
  region      = var.gcp_k8s_region
  org_id      = var.gcp_org_id
  billing_id  = var.gcp_billing_id
  cidr        = cidrsubnet(var.cidr, 4, 8 + count.index)
}

module "gcp_jumpbox" {
  source                  = "../../modules/gcp/jumpbox"
  count                   = var.gcp_k8s_region == null ? 0 : 1
  name_prefix             = "${var.name_prefix}-${var.gcp_k8s_region}"
  region                  = var.gcp_k8s_region
  project_id              = var.gcp_project_id == null ? google_project.tsb[0].project_id : var.gcp_project_id
  vpc_id                  = module.gcp_base[0].vpc_id
  vpc_subnet              = module.gcp_base[0].vpc_subnets[0]
  tsb_version             = var.tsb_version
  jumpbox_username        = var.jumpbox_username
  tsb_image_sync_username = var.tsb_image_sync_username
  tsb_image_sync_apikey   = var.tsb_image_sync_apikey
  registry                = module.gcp_base[0].registry
  output_path             = var.output_path
}

module "gcp_k8s" {
  source       = "../../modules/gcp/k8s"
  count        = var.gcp_k8s_region == null ? 0 : 1
  name_prefix  = "${var.name_prefix}-${var.gcp_k8s_region}"
  cluster_name = var.cluster_name == null ? "gke-${var.gcp_k8s_region}-${var.name_prefix}" : var.cluster_name
  project_id   = var.gcp_project_id == null ? google_project.tsb[0].project_id : var.gcp_project_id
  region       = var.gcp_k8s_region
  k8s_version  = var.gcp_gke_k8s_version
  output_path  = var.output_path
  depends_on   = [module.gcp_jumpbox[0]]
}
