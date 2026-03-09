# Domain Setup Guide

## Step 1: Add Domains to Cloudflare

Go to https://dash.cloudflare.com and click "Add a Site" for each domain:

### Domains to Add:
1. blackroadinc.us
2. blackroadai.com
3. blackroad.me
4. blackroad.network
5. blackroadqi.com
6. blackroadquantum.com
7. blackroadquantum.info
8. blackroadquantum.net
9. blackroadquantum.shop
10. blackroadquantum.store
11. blackroad.systems
12. lucidia.earth
13. lucidiaqi.com
14. lucidia.studio
15. aliceqi.com

For each domain:
1. Click "Add a Site"
2. Enter the domain name
3. Select the Free plan
4. Cloudflare will scan for existing DNS records
5. Update your domain registrar's nameservers to Cloudflare's

## Step 2: Update Nameservers at Registrar

After adding each domain, Cloudflare will provide nameservers like:
- `chad.ns.cloudflare.com`
- `vita.ns.cloudflare.com`

Update these at your domain registrar (GoDaddy, Namecheap, etc.)

## Step 3: Configure DNS Records

Once the domain is active in Cloudflare, add a CNAME record:

| Domain | Type | Name | Content |
|--------|------|------|---------|
| blackroadinc.us | CNAME | @ | blackroadinc-us.pages.dev |
| blackroadai.com | CNAME | @ | blackroadai-com.pages.dev |
| blackroad.me | CNAME | @ | blackroad-me.pages.dev |
| blackroad.network | CNAME | @ | blackroad-network.pages.dev |
| blackroadqi.com | CNAME | @ | blackroadqi-com.pages.dev |
| blackroadquantum.com | CNAME | @ | blackroadquantum-com.pages.dev |
| blackroadquantum.info | CNAME | @ | blackroadquantum-info.pages.dev |
| blackroadquantum.net | CNAME | @ | blackroadquantum-net.pages.dev |
| blackroadquantum.shop | CNAME | @ | blackroadquantum-shop.pages.dev |
| blackroadquantum.store | CNAME | @ | blackroadquantum-store.pages.dev |
| blackroad.systems | CNAME | @ | blackroad-systems.pages.dev |
| lucidia.earth | CNAME | @ | lucidia-earth.pages.dev |
| lucidiaqi.com | CNAME | @ | lucidiaqi-com.pages.dev |
| lucidia.studio | CNAME | @ | lucidia-studio.pages.dev |
| aliceqi.com | CNAME | @ | aliceqi-com.pages.dev |

Also add www subdomain:
| Domain | Type | Name | Content |
|--------|------|------|---------|
| (each domain) | CNAME | www | (same as root) |

## Step 4: Add Custom Domains in Pages

For each Pages project:
1. Go to Pages → Select project → Custom domains
2. Click "Set up a custom domain"
3. Enter the domain (e.g., blackroadinc.us)
4. Cloudflare will automatically configure SSL

## Already Configured

✅ blackroad.io → blackroad-io.pages.dev (CNAME added)
✅ www.blackroad.io → blackroad-io.pages.dev
✅ app.blackroad.io → blackroad-console.pages.dev
✅ docs.blackroad.io → blackroad-os-docs.pages.dev
✅ demo.blackroad.io → blackroad-os-demo.pages.dev
✅ home.blackroad.io → blackroad-os-home.pages.dev
✅ brand.blackroad.io → blackroad-os-brand.pages.dev

## Pages Projects Created

All landing pages are deployed and live at:

| Project | Pages URL |
|---------|-----------|
| blackroad-io | https://blackroad-io.pages.dev |
| blackroadinc-us | https://blackroadinc-us.pages.dev |
| blackroadai-com | https://blackroadai-com.pages.dev |
| blackroad-me | https://blackroad-me.pages.dev |
| blackroad-network | https://blackroad-network.pages.dev |
| blackroadqi-com | https://blackroadqi-com.pages.dev |
| blackroadquantum-com | https://blackroadquantum-com.pages.dev |
| blackroadquantum-info | https://blackroadquantum-info.pages.dev |
| blackroadquantum-net | https://blackroadquantum-net.pages.dev |
| blackroadquantum-shop | https://blackroadquantum-shop.pages.dev |
| blackroadquantum-store | https://blackroadquantum-store.pages.dev |
| blackroad-systems | https://blackroad-systems.pages.dev |
| lucidia-earth | https://lucidia-earth.pages.dev |
| lucidiaqi-com | https://lucidiaqi-com.pages.dev |
| lucidia-studio | https://lucidia-studio.pages.dev |
| aliceqi-com | https://aliceqi-com.pages.dev |
