import { useState, useEffect, useCallback } from "react";
import { invoke } from "@tauri-apps/api/core";
import type { VerificationResult } from "../types/verification";

export function useVerification(url?: string) {
  const [verification, setVerification] =
    useState<VerificationResult | null>(null);
  const [isVerifying, setIsVerifying] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [pageContent, setPageContent] = useState("");

  // Called by BrowserFrame when page content is available
  const onContentReady = useCallback((content: string) => {
    setPageContent(content);
  }, []);

  useEffect(() => {
    if (!url || url.startsWith("blackroad://")) {
      setVerification(null);
      return;
    }

    let cancelled = false;

    const verify = async () => {
      setIsVerifying(true);
      try {
        // Check cache first
        const cached = await invoke<VerificationResult | null>(
          "get_verification_status",
          { url },
        );
        if (!cancelled && cached) {
          setVerification(cached);
          setIsVerifying(false);
          return;
        }

        // Run verification with whatever content we have
        const result = await invoke<VerificationResult>("verify_page", {
          url,
          content: pageContent,
        });
        if (!cancelled) {
          setVerification(result);
        }
      } catch (err) {
        console.error("Verification failed:", err);
      } finally {
        if (!cancelled) {
          setIsVerifying(false);
        }
      }
    };

    verify();
    return () => {
      cancelled = true;
    };
  }, [url, pageContent]);

  return {
    verification,
    isVerifying,
    sidebarOpen,
    toggleSidebar: () => setSidebarOpen((v) => !v),
    onContentReady,
  };
}
