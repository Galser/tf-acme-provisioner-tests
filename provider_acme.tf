provider "acme" {
  # PRODUCTION
  version    = "~> 1.0"
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
  # STAGING
  # "https://acme-staging-v02.api.letsencrypt.org/directory"
}