# BlackRoad Terraform Modules

Reusable Terraform modules for BlackRoad multi-cloud infrastructure.

## Modules

| Module | Description |
|--------|-------------|
| cloudflare-worker | Deploy Cloudflare Workers |
| railway-service | Deploy Railway services |
| digitalocean-droplet | Deploy DigitalOcean droplets |

## Usage

```hcl
module "api_worker" {
  source = "github.com/BlackRoad-OS/terraform-modules//modules/cloudflare-worker"
  
  account_id     = var.cloudflare_account_id
  name           = "blackroad-api"
  script_content = file("worker.js")
}
```

## License

Proprietary - BlackRoad OS, Inc.
