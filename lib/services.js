// BlackRoad OS Service Registry
export const services = {
  core: [
    { name: 'Main Site', slug: 'blackroad', url: 'blackroad.io', railway: false },
    { name: 'App Console', slug: 'app', url: 'app.blackroad.io', railway: false },
    { name: 'API', slug: 'api', url: 'api.blackroad.io', railway: false },
  ],
  infrastructure: [
    { name: 'API Gateway', slug: 'api-gateway', url: 'gateway.blackroad.io', railway: true },
    { name: 'Core', slug: 'core', url: 'core.blackroad.io', railway: true },
    { name: 'Operator', slug: 'operator', url: 'operator.blackroad.io', railway: true },
  ],
  services: [
    { name: 'Agents', slug: 'agents', url: 'agents.blackroad.io', railway: true },
    { name: 'Beacon', slug: 'beacon', url: 'beacon.blackroad.io', railway: true },
    { name: 'Prism Console', slug: 'prism', url: 'prism.blackroad.io', railway: true },
    { name: 'Research', slug: 'research', url: 'research.blackroad.io', railway: true },
  ],
  web: [
    { name: 'Home', slug: 'home', url: 'home.blackroad.io', railway: true },
    { name: 'Demo', slug: 'demo', url: 'demo.blackroad.io', railway: true },
    { name: 'Docs', slug: 'docs', url: 'docs.blackroad.io', railway: false },
    { name: 'Brand', slug: 'brand', url: 'brand.blackroad.io', railway: false },
    { name: 'Status', slug: 'status', url: 'status.blackroad.io', railway: false },
  ]
};

export const getAllServices = () => {
  return [
    ...services.core,
    ...services.infrastructure,
    ...services.services,
    ...services.web
  ];
};

export const getServiceBySlug = (slug) => {
  return getAllServices().find(s => s.slug === slug);
};

export const getRailwayServices = () => {
  return getAllServices().filter(s => s.railway);
};

// Dashboard URLs
export const dashboards = {
  railway: 'https://railway.com/project/03ce1e43-5086-4255-b2bc-0146c8916f4c',
  cloudflare: 'https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a',
  github: 'https://github.com/BlackRoad-OS',
  status: 'https://status.blackroad.io',
  actions: 'https://github.com/BlackRoad-OS/blackroad-os-infra/actions',
};
