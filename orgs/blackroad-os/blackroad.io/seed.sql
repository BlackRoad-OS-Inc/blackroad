-- Seed data for BlackRoad.io

-- Stats
INSERT OR REPLACE INTO stats (id, key, value) VALUES
  ('stat_agents', 'agents', '1000'),
  ('stat_domains', 'domains', '21'),
  ('stat_orgs', 'github_orgs', '16'),
  ('stat_repos', 'repositories', '40');

-- Domains
INSERT OR REPLACE INTO domains (id, name, primary_domain, status) VALUES
  ('dom_001', 'blackroad.io', 1, 'active'),
  ('dom_002', 'blackroad.systems', 0, 'active'),
  ('dom_003', 'blackroadai.com', 0, 'active'),
  ('dom_004', 'blackroad.company', 0, 'active'),
  ('dom_005', 'blackroadinc.us', 0, 'active'),
  ('dom_006', 'blackroad.me', 0, 'active'),
  ('dom_007', 'blackroad.network', 0, 'active'),
  ('dom_008', 'blackroadqi.com', 0, 'active'),
  ('dom_009', 'blackroadquantum.com', 0, 'active'),
  ('dom_010', 'blackroadquantum.info', 0, 'active'),
  ('dom_011', 'blackroadquantum.net', 0, 'active'),
  ('dom_012', 'blackroadquantum.shop', 0, 'active'),
  ('dom_013', 'blackroadquantum.store', 0, 'active'),
  ('dom_014', 'blackboxprogramming.io', 0, 'active'),
  ('dom_015', 'aliceqi.com', 0, 'active'),
  ('dom_016', 'lucidiaqi.com', 0, 'active'),
  ('dom_017', 'lucidia.studio', 0, 'active'),
  ('dom_018', 'lucidia.earth', 0, 'active'),
  ('dom_019', 'roadchain.io', 0, 'active'),
  ('dom_020', 'roadcoin.io', 0, 'active');

-- GitHub orgs
INSERT OR REPLACE INTO github_orgs (id, name, display_name, description) VALUES
  ('org_001', 'BlackRoad-OS', 'BlackRoad OS', 'Core operating system'),
  ('org_002', 'blackboxprogramming', 'Blackbox Programming', 'Development tools'),
  ('org_003', 'Blackbox-Enterprises', 'Blackbox Enterprises', 'Enterprise solutions'),
  ('org_004', 'BlackRoad-AI', 'BlackRoad AI', 'AI/ML projects'),
  ('org_005', 'BlackRoad-Archive', 'BlackRoad Archive', 'Historical projects'),
  ('org_006', 'BlackRoad-Cloud', 'BlackRoad Cloud', 'Cloud infrastructure'),
  ('org_007', 'BlackRoad-Education', 'BlackRoad Education', 'Learning resources'),
  ('org_008', 'BlackRoad-Foundation', 'BlackRoad Foundation', 'Open source'),
  ('org_009', 'BlackRoad-Gov', 'BlackRoad Gov', 'Government solutions'),
  ('org_010', 'BlackRoad-Hardware', 'BlackRoad Hardware', 'Hardware projects'),
  ('org_011', 'BlackRoad-Interactive', 'BlackRoad Interactive', 'Games & interactive'),
  ('org_012', 'BlackRoad-Labs', 'BlackRoad Labs', 'R&D experiments'),
  ('org_013', 'BlackRoad-Media', 'BlackRoad Media', 'Content & media'),
  ('org_014', 'BlackRoad-Security', 'BlackRoad Security', 'Security tools'),
  ('org_015', 'BlackRoad-Studio', 'BlackRoad Studio', 'Creative studio'),
  ('org_016', 'BlackRoad-Ventures', 'BlackRoad Ventures', 'Investments');

-- Redirects
INSERT OR REPLACE INTO redirects (id, path, target, permanent) VALUES
  ('redir_ig', '/instagram', 'https://www.instagram.com/blackroad.io', 0),
  ('redir_stripe', '/stripe', 'https://dashboard.stripe.com/acct_1SUDM8ChUUSEbzyh/dashboard', 0),
  ('redir_cf', '/cloudflare', 'https://dash.cloudflare.com/848cf0b18d51e0170e0d1537aec3505a', 0),
  ('redir_vercel', '/vercel', 'https://vercel.com/alexa-amundsons-projects', 0),
  ('redir_notion', '/notion', 'https://www.notion.so/76cded82e3874f9db0d44dff11b8f2fd', 0),
  ('redir_sf', '/salesforce', 'https://www.salesforce.com/trailblazer/w0290jck2ebf0xos3p/', 0),
  ('redir_tb', '/trailblazer', 'https://www.salesforce.com/trailblazer/alexa-amundson', 0);
