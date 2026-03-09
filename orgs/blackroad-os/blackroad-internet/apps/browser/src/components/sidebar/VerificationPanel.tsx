import type { VerificationResult } from "../../types/verification";
import { AccuracyScore } from "./AccuracyScore";
import { SourceReputation } from "./SourceReputation";
import { ClaimsList } from "./ClaimsList";

interface VerificationPanelProps {
  verification: VerificationResult | null;
  isVerifying: boolean;
}

export function VerificationPanel({
  verification,
  isVerifying,
}: VerificationPanelProps) {
  return (
    <div className="w-72 bg-surface border-l border-gray-800 overflow-y-auto flex flex-col shrink-0">
      <div className="p-4 border-b border-gray-800">
        <h2 className="text-sm font-semibold text-white flex items-center gap-2">
          <svg
            className="w-4 h-4 text-hotpink"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
            />
          </svg>
          Verification
          {verification?.ai_available && (
            <span className="ml-auto text-[9px] px-1.5 py-0.5 rounded bg-hotpink/20 text-hotpink font-medium">
              AI
            </span>
          )}
        </h2>
        <p className="text-[10px] text-muted mt-1 tracking-wider uppercase">
          Accurate info. Period.
        </p>
      </div>

      {isVerifying ? (
        <div className="flex-1 flex items-center justify-center p-8">
          <div className="text-center">
            <div className="animate-spin w-8 h-8 border-2 border-hotpink border-t-transparent rounded-full mx-auto" />
            <p className="text-xs text-muted mt-4">Analyzing page...</p>
            <p className="text-[10px] text-gray-700 mt-1">
              Checking sources & claims
            </p>
          </div>
        </div>
      ) : verification ? (
        <>
          <AccuracyScore score={verification.overall_score} />
          <SourceReputation
            score={verification.source_reputation}
            url={verification.url}
            method={verification.method}
            category={verification.source_category}
            bias={verification.source_bias}
          />
          {verification.claims_checked > 0 && (
            <div className="px-4 py-2 border-b border-gray-800">
              <p className="text-[10px] text-muted">
                {verification.claims_checked} claims verified in{" "}
                {verification.verification_time_ms}ms
              </p>
            </div>
          )}
          <ClaimsList claims={verification.claims} />
        </>
      ) : (
        <div className="flex-1 flex items-center justify-center p-6">
          <div className="text-center">
            <svg
              className="w-10 h-10 text-gray-800 mx-auto mb-3"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={1}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
              />
            </svg>
            <p className="text-xs text-muted">
              Navigate to a page to see verification results
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
