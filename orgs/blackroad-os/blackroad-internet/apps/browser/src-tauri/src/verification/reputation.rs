use std::collections::HashMap;

/// Domain reputation database with categories and factual ratings.
/// Phase 2: Static in-memory database. Phase 4: Cloudflare D1 + community data.
#[allow(dead_code)]
pub struct ReputationDb {
    domains: HashMap<String, DomainReputation>,
}

#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct DomainReputation {
    pub score: f64,
    pub category: &'static str,
    pub bias: &'static str,
    pub factual: &'static str,
}

impl ReputationDb {
    pub fn new() -> Self {
        let mut domains = HashMap::new();

        // Academic & Research (highest trust)
        for domain in &[
            "arxiv.org",
            "scholar.google.com",
            "pubmed.ncbi.nlm.nih.gov",
            "ncbi.nlm.nih.gov",
            "jstor.org",
            "sciencedirect.com",
            "springer.com",
            "wiley.com",
            "ieee.org",
            "acm.org",
            "researchgate.net",
        ] {
            domains.insert(
                domain.to_string(),
                DomainReputation {
                    score: 0.95,
                    category: "academic",
                    bias: "none",
                    factual: "very-high",
                },
            );
        }

        // Scientific journals
        for domain in &[
            "nature.com",
            "science.org",
            "cell.com",
            "thelancet.com",
            "nejm.org",
            "bmj.com",
            "pnas.org",
            "plos.org",
        ] {
            domains.insert(
                domain.to_string(),
                DomainReputation {
                    score: 0.96,
                    category: "journal",
                    bias: "none",
                    factual: "very-high",
                },
            );
        }

        // Government sources
        for domain in &[
            "nasa.gov",
            "nih.gov",
            "cdc.gov",
            "fda.gov",
            "epa.gov",
            "noaa.gov",
            "usgs.gov",
            "bls.gov",
            "census.gov",
            "sec.gov",
            "federalreserve.gov",
            "whitehouse.gov",
            "congress.gov",
            "supremecourt.gov",
            "data.gov",
            "gao.gov",
        ] {
            domains.insert(
                domain.to_string(),
                DomainReputation {
                    score: 0.92,
                    category: "government",
                    bias: "none",
                    factual: "very-high",
                },
            );
        }

        // Wire services (highest journalistic trust)
        for (domain, score) in &[
            ("apnews.com", 0.93),
            ("reuters.com", 0.93),
            ("afp.com", 0.91),
        ] {
            domains.insert(
                domain.to_string(),
                DomainReputation {
                    score: *score,
                    category: "wire-service",
                    bias: "center",
                    factual: "very-high",
                },
            );
        }

        // Reference
        for domain in &[
            "wikipedia.org",
            "en.wikipedia.org",
            "britannica.com",
            "merriam-webster.com",
            "dictionary.com",
            "worldbank.org",
            "imf.org",
            "un.org",
            "who.int",
        ] {
            domains.insert(
                domain.to_string(),
                DomainReputation {
                    score: 0.88,
                    category: "reference",
                    bias: "none",
                    factual: "high",
                },
            );
        }

        // Quality journalism (center/high factual)
        for (domain, score, bias) in &[
            ("bbc.com", 0.85, "center"),
            ("bbc.co.uk", 0.85, "center"),
            ("npr.org", 0.84, "center"),
            ("pbs.org", 0.84, "center"),
            ("economist.com", 0.83, "center"),
            ("ft.com", 0.83, "center"),
            ("wsj.com", 0.82, "center-right"),
            ("nytimes.com", 0.82, "center-left"),
            ("washingtonpost.com", 0.81, "center-left"),
            ("theguardian.com", 0.80, "center-left"),
            ("bloomberg.com", 0.83, "center"),
            ("propublica.org", 0.86, "center-left"),
            ("theintercept.com", 0.75, "left"),
            ("jacobin.com", 0.70, "left"),
            ("nationalreview.com", 0.72, "right"),
            ("reason.com", 0.73, "right"),
        ] {
            domains.insert(
                domain.to_string(),
                DomainReputation {
                    score: *score,
                    category: "news",
                    bias,
                    factual: if *score > 0.80 { "high" } else { "mixed" },
                },
            );
        }

        // Fact-checking sites
        for domain in &[
            "snopes.com",
            "factcheck.org",
            "politifact.com",
            "fullfact.org",
        ] {
            domains.insert(
                domain.to_string(),
                DomainReputation {
                    score: 0.90,
                    category: "fact-check",
                    bias: "center",
                    factual: "very-high",
                },
            );
        }

        // Tech documentation
        for domain in &[
            "docs.github.com",
            "developer.mozilla.org",
            "docs.python.org",
            "docs.rust-lang.org",
            "docs.microsoft.com",
            "developer.apple.com",
            "cloud.google.com",
            "docs.aws.amazon.com",
            "stackoverflow.com",
        ] {
            domains.insert(
                domain.to_string(),
                DomainReputation {
                    score: 0.85,
                    category: "tech-docs",
                    bias: "none",
                    factual: "high",
                },
            );
        }

        // Social media (low factual, high bias potential)
        for domain in &[
            "twitter.com",
            "x.com",
            "facebook.com",
            "instagram.com",
            "tiktok.com",
            "reddit.com",
            "threads.net",
        ] {
            domains.insert(
                domain.to_string(),
                DomainReputation {
                    score: 0.30,
                    category: "social",
                    bias: "mixed",
                    factual: "low",
                },
            );
        }

        // Known misinformation/low trust
        for domain in &[
            "infowars.com",
            "naturalnews.com",
            "thegatewaypundit.com",
            "zerohedge.com",
            "breitbart.com",
            "dailymail.co.uk",
        ] {
            domains.insert(
                domain.to_string(),
                DomainReputation {
                    score: 0.15,
                    category: "low-credibility",
                    bias: "extreme",
                    factual: "very-low",
                },
            );
        }

        Self { domains }
    }

    /// Look up reputation for a domain, checking parent domains too
    pub fn lookup(&self, url: &str) -> Option<DomainReputation> {
        let domain = extract_domain(url)?;

        // Direct match
        if let Some(rep) = self.domains.get(&domain) {
            return Some(rep.clone());
        }

        // Try parent domain (e.g., "en.wikipedia.org" -> "wikipedia.org")
        let parts: Vec<&str> = domain.split('.').collect();
        if parts.len() > 2 {
            let parent = parts[parts.len() - 2..].join(".");
            if let Some(rep) = self.domains.get(&parent) {
                return Some(rep.clone());
            }
        }

        // TLD-based defaults
        if domain.ends_with(".gov") {
            return Some(DomainReputation {
                score: 0.88,
                category: "government",
                bias: "none",
                factual: "high",
            });
        }
        if domain.ends_with(".edu") {
            return Some(DomainReputation {
                score: 0.85,
                category: "education",
                bias: "none",
                factual: "high",
            });
        }
        if domain.ends_with(".org") {
            return Some(DomainReputation {
                score: 0.60,
                category: "organization",
                bias: "unknown",
                factual: "mixed",
            });
        }

        None
    }
}

fn extract_domain(url: &str) -> Option<String> {
    url::Url::parse(url)
        .ok()
        .and_then(|u| u.host_str().map(|h| h.to_lowercase()))
}
