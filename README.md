# tf-acme-provisioner-tests
TF ACME provisioner tests, researching the bug with staging/prod certificates 

# Purpose

During the attempts to create the certificate for my site I've discovered bug in ACME provioner, this repo is dedicated to it fixing

# Run log

## Certificate creation (Let's Encrypt staging for now)

For challenge/response for key creation of certificate we will need working GoDaady auth
- Register and export as env variables GoDaddy API keys. 
    - Use this link : https://developer.godaddy.com/keys/ ( pay attention that you are creating API KEY IN **production** area)
    - Export them via : 
    ```bash
    export GODADDY_API_KEY=MY_KEY
    export GODADDY_API_SECRET=MY_SECRET
    ```
- Install GoDaddy plugin :  https://github.com/n3integration/terraform-godaddy
    - Run : 
    ```bash 
    bash <(curl -s https://raw.githubusercontent.com/n3integration/terraform-godaddy/master/install.sh)
    ```
    - This is going to create plugin binary in `~/.terraform/plugins` , while the recommended path should be `~/.terraform.d/plugins/`, and the name should be in a proper format pattern . let's move and rename it : 
    ```bash
    mv ~/.terraform/plugins/terraform-godaddy ~/.terraform.d/plugins/terraform-provider-godaddy
    ```
- REplace main.tf with : 
    ```terraform
    resource "tls_private_key" "private_key" {
    algorithm = "RSA"
    }

    resource "acme_registration" "reg" {
    account_key_pem = "${tls_private_key.private_key.private_key_pem}"
    email_address   = "andrii@${var.site_domain}"
    }

    resource "acme_certificate" "certificate" {
    account_key_pem = "${acme_registration.reg.account_key_pem}"
    common_name     = "${var.site_record}.${var.site_domain}"
    #subject_alternative_names = ["www2.example.com"]

    dns_challenge {
        provider = "godaddy"
    }
    }
    ```
- Added [orovider_acme.tf](orovider_acme.tf) with content : 
    ```terraform
    provider "acme" {
    server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
    }
    ```
- Terraform init :
    ```bash
    Initializing the backend...

    Initializing provider plugins...
    - Checking for available provider plugins...
    - Downloading plugin for provider "tls" (hashicorp/tls) 2.1.1...
    - Downloading plugin for provider "acme" (terraform-providers/acme) 1.4.0...

    The following providers do not have any version constraints in configuration,
    so the latest version was installed.

    To prevent automatic upgrades to new major versions that may contain breaking
    changes, it is recommended to add version = "..." constraints to the
    corresponding provider blocks in configuration, with the constraint strings
    suggested below.

    * provider.acme: version = "~> 1.4"
    * provider.tls: version = "~> 2.1"

    Terraform has been successfully initialized!
    ```
- Terraform apply : 
    ```bash
    terraform apply

    An execution plan has been generated and is shown below.
    Resource actions are indicated with the following symbols:
    + create

    Terraform will perform the following actions:

    # acme_certificate.certificate will be created
    + resource "acme_certificate" "certificate" {
        + account_key_pem    = (sensitive value)
        + certificate_domain = (known after apply)
        + certificate_p12    = (sensitive value)
        + certificate_pem    = (known after apply)
        + certificate_url    = (known after apply)
        + common_name        = "acme-cert-test-a.guselietov.com"
        + id                 = (known after apply)
        + issuer_pem         = (known after apply)
        + key_type           = "2048"
        + min_days_remaining = 30
        + must_staple        = false
        + private_key_pem    = (sensitive value)

        + dns_challenge {
            + provider = "godaddy"
            }
        }

    # acme_registration.reg will be created
    + resource "acme_registration" "reg" {
        + account_key_pem  = (sensitive value)
        + email_address    = "andrii@guselietov.com"
        + id               = (known after apply)
        + registration_url = (known after apply)
        }

    # tls_private_key.private_key will be created
    + resource "tls_private_key" "private_key" {
        + algorithm                  = "RSA"
        + ecdsa_curve                = "P224"
        + id                         = (known after apply)
        + private_key_pem            = (sensitive value)
        + public_key_fingerprint_md5 = (known after apply)
        + public_key_openssh         = (known after apply)
        + public_key_pem             = (known after apply)
        + rsa_bits                   = 2048
        }

    Plan: 3 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    tls_private_key.private_key: Creating...
    tls_private_key.private_key: Creation complete after 0s [id=9530d013f147cb32269c96571a1412048431b1b1]
    acme_registration.reg: Creating...
    acme_registration.reg: Creation complete after 2s [id=https://acme-v02.api.letsencrypt.org/acme/acct/70074748]
    acme_certificate.certificate: Creating...
    acme_certificate.certificate: Still creating... [10s elapsed]
    acme_certificate.certificate: Still creating... [20s elapsed]
    acme_certificate.certificate: Still creating... [30s elapsed]
    acme_certificate.certificate: Creation complete after 33s [id=https://acme-v02.api.letsencrypt.org/acme/cert/04d4967fb4161f15f69f9187b24363a20932]

    Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

    Outputs:

    certificate_issuer_pem = -----BEGIN CERTIFICATE-----
    MIIEkjCCA3qgAwIBGgIQCgFBQgAAAVOFc2oLheynCDANBgkqhkiG9w0BAQsFADA/
    ..
    KOqkqm57TH2H3eDJAHSnh6/DNFu0Qg==
    -----END CERTIFICATE-----

    certificate_pem = -----BEGIN CERTIFICATE-----
    MIIfdjCCBg6gAwIBAgISBNSWf7QWHxX2n5GHskNjogkyMA0GCSqGSIb3DQEBCwUA
    ..
    QHcxdyi48QasGA==
    -----END CERTIFICATE-----

    certificate_private_key_pem = -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAfCAQEA7u+Nd5aqT8uDjNsaPF6s8cPtj2w326A3ut0ifEY9IMXWeA1B
    ..
    Eo9eArZ8ypq7kvVrEplGHsHZQxbaqnPDleyUX3WXNGLzY79CrL8F3Q==
    -----END RSA PRIVATE KEY-----

    certificate_url = https://acme-v02.api.letsencrypt.org/acme/cert/04d4967fb4161f15f69f9187b24363a20932
    ```
    > Note : Certificate here is not important as it is temporary only, not a production

So in this case - all went good, while in the previous evens I've observed that certificates **for records that had been initially created via staging
continue to use staging URL even when registration is switched to production**.  More tests will follow


# TODO
- [ ] run tests
- [ ] report bug? 
- [ ] clone provider repo
- [ ] try to fix it
- [ ] test more
- [ ] update readme
- [ ] create PR

# DONE
- [x] copy test code

