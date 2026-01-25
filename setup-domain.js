// Cloudflare API script to add custom domain to Pages project
// Run with: node setup-domain.js

const ACCOUNT_ID = '848cf0b18d51e0170e0d1537aec3505a';
const PROJECT_NAME = 'lucidia-earth';
const CUSTOM_DOMAIN = 'lucidia.earth';
const CF_TOKEN = 'yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy';

async function addCustomDomain() {
  const url = `https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/domains`;

  console.log(`Adding custom domain ${CUSTOM_DOMAIN} to Pages project ${PROJECT_NAME}...`);

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${CF_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      name: CUSTOM_DOMAIN
    })
  });

  const data = await response.json();

  if (data.success) {
    console.log('✅ Custom domain added successfully!');
    console.log(`Domain: ${CUSTOM_DOMAIN}`);
    console.log(`Status: ${data.result.status}`);
    console.log(`\nYour site will be available at: https://${CUSTOM_DOMAIN}`);
  } else {
    console.log('❌ Failed to add custom domain');
    console.log('Errors:', JSON.stringify(data.errors, null, 2));

    // Try to list existing domains
    console.log('\nAttempting to list existing domains...');
    const listUrl = `https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/domains`;
    const listResponse = await fetch(listUrl, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${CF_TOKEN}`,
        'Content-Type': 'application/json',
      }
    });

    const listData = await listResponse.json();
    if (listData.success) {
      console.log('Current domains:', listData.result.map(d => d.name).join(', '));
    } else {
      console.log('Could not list domains:', JSON.stringify(listData.errors, null, 2));
    }
  }
}

addCustomDomain().catch(console.error);
