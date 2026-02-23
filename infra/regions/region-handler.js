// Region sharding handler — add to blackroad-subdomain-router
function handleRegion(request) {
  const url = new URL(request.url);
  const region = url.hostname.split('.')[0]; // na1, eu1, ap1
  
  const REGIONS = {
    'na1': 'https://blackroad.io',  // Primary
    'eu1': 'https://blackroad.io',  // TODO: EU endpoint
    'ap1': 'https://blackroad.io',  // TODO: AP endpoint
  };
  
  const target = REGIONS[region] || 'https://blackroad.io';
  
  // For now: redirect to primary with region header
  return new Response(null, {
    status: 302,
    headers: {
      'Location': target + url.pathname,
      'X-BlackRoad-Region': region,
      'X-BlackRoad-Routed-To': target
    }
  });
}
