import { useState } from "react";

interface PrivacyDashboardProps {
  onNavigate: (url: string) => void;
}

// Known tracker domains (subset - real implementation would use EasyList/EasyPrivacy)
const KNOWN_TRACKERS = [
  "google-analytics.com",
  "googletagmanager.com",
  "doubleclick.net",
  "facebook.net",
  "fbcdn.net",
  "analytics.twitter.com",
  "ads.linkedin.com",
  "pixel.quantserve.com",
  "scorecardresearch.com",
  "hotjar.com",
  "mixpanel.com",
  "segment.io",
  "amplitude.com",
  "newrelic.com",
  "sentry.io",
  "clarity.ms",
  "criteo.com",
  "taboola.com",
  "outbrain.com",
  "amazon-adsystem.com",
];

const AD_DOMAINS = [
  "googlesyndication.com",
  "googleadservices.com",
  "doubleclick.net",
  "adnxs.com",
  "adsrvr.org",
  "rubiconproject.com",
  "pubmatic.com",
  "openx.net",
  "casalemedia.com",
  "indexexchange.com",
];

export function PrivacyDashboard(_props: PrivacyDashboardProps) {
  const [privacyLevel, setPrivacyLevel] = useState<"standard" | "strict" | "aggressive">("strict");

  return (
    <div className="min-h-full bg-black p-6">
      <div className="max-w-3xl mx-auto">
        <h1 className="text-xl font-bold text-white mb-2">Privacy Dashboard</h1>
        <p className="text-xs text-muted mb-8">
          BlackRoad Internet blocks trackers and protects your privacy by default.
        </p>

        {/* Privacy level selector */}
        <div className="mb-8">
          <h2 className="text-xs font-semibold text-muted mb-3 uppercase tracking-wider">
            Protection Level
          </h2>
          <div className="grid grid-cols-3 gap-3">
            {[
              {
                level: "standard" as const,
                label: "Standard",
                desc: "Block known trackers and ads",
                blocked: "~70%",
              },
              {
                level: "strict" as const,
                label: "Strict",
                desc: "Block trackers, ads, fingerprinting, and third-party cookies",
                blocked: "~90%",
              },
              {
                level: "aggressive" as const,
                label: "Aggressive",
                desc: "Block all third-party requests, scripts, and cookies",
                blocked: "~99%",
              },
            ].map((opt) => (
              <button
                key={opt.level}
                onClick={() => setPrivacyLevel(opt.level)}
                className={`p-4 rounded-lg border text-left transition-colors ${
                  privacyLevel === opt.level
                    ? "border-hotpink bg-hotpink/10"
                    : "border-gray-800 bg-surface hover:border-gray-700"
                }`}
              >
                <p className="text-sm font-semibold text-white">{opt.label}</p>
                <p className="text-[10px] text-gray-500 mt-1">{opt.desc}</p>
                <p className="text-[10px] text-hotpink mt-2">{opt.blocked} blocked</p>
              </button>
            ))}
          </div>
        </div>

        {/* What's protected */}
        <div className="mb-8">
          <h2 className="text-xs font-semibold text-muted mb-3 uppercase tracking-wider">
            Active Protections
          </h2>
          <div className="space-y-2">
            {[
              {
                name: "Tracker Blocking",
                desc: `${KNOWN_TRACKERS.length} known tracker domains blocked`,
                active: true,
                icon: "shield",
              },
              {
                name: "Ad Filtering",
                desc: `${AD_DOMAINS.length} ad network domains blocked`,
                active: true,
                icon: "ban",
              },
              {
                name: "Fingerprint Protection",
                desc: "Canvas, WebGL, and audio fingerprinting randomized",
                active: privacyLevel !== "standard",
                icon: "fingerprint",
              },
              {
                name: "HTTPS Upgrade",
                desc: "Automatically upgrade HTTP to HTTPS when possible",
                active: true,
                icon: "lock",
              },
              {
                name: "Third-Party Cookie Blocking",
                desc: "Block cookies from domains you haven't visited",
                active: privacyLevel !== "standard",
                icon: "cookie",
              },
              {
                name: "Referrer Stripping",
                desc: "Remove identifying info from referrer headers",
                active: true,
                icon: "eye-off",
              },
              {
                name: "Script Blocking",
                desc: "Block all third-party JavaScript execution",
                active: privacyLevel === "aggressive",
                icon: "code",
              },
            ].map((protection) => (
              <div
                key={protection.name}
                className="flex items-center gap-3 p-3 rounded-lg bg-surface border border-gray-800"
              >
                <div
                  className={`w-2 h-2 rounded-full shrink-0 ${
                    protection.active ? "bg-emerald-400" : "bg-gray-700"
                  }`}
                />
                <div className="flex-1">
                  <p className="text-sm text-white">{protection.name}</p>
                  <p className="text-[10px] text-gray-600">{protection.desc}</p>
                </div>
                <span
                  className={`text-[9px] px-2 py-0.5 rounded ${
                    protection.active
                      ? "text-emerald-400 bg-emerald-400/10"
                      : "text-gray-600 bg-gray-800"
                  }`}
                >
                  {protection.active ? "Active" : "Off"}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Known trackers list */}
        <div>
          <h2 className="text-xs font-semibold text-muted mb-3 uppercase tracking-wider">
            Blocked Domains ({KNOWN_TRACKERS.length + AD_DOMAINS.length})
          </h2>
          <div className="grid grid-cols-2 gap-1">
            {[...KNOWN_TRACKERS, ...AD_DOMAINS].sort().map((domain) => (
              <span key={domain} className="text-[10px] text-gray-600 font-mono py-0.5">
                {domain}
              </span>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
