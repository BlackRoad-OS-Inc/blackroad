import fs from 'fs';
import path from 'path';
import { parse as jsonToCsv } from 'json2csv';
import dayjs from 'dayjs';

export type ActionTaken =
  | 'Deleted'
  | 'SkippedUnsafe'
  | 'SkippedTooRecent'
  | 'SkippedProtected'
  | 'SkippedExcluded'
  | 'ProtectedRuleBlocked'
  | 'TokenInsufficient'
  | 'AlreadyDeleted'
  | 'Error';

export interface CleanupRecord {
  org: string;
  repo: string;
  branch: string;
  headSha: string;
  mergedPr: number | null;
  mergedAt: string | null;
  defaultBranch: string;
  protected: boolean;
  actionTaken: ActionTaken;
  backupTag: string;
  error: string;
}

export interface ReportSummary {
  totalBranches: number;
  deleted: number;
  skipped: number;
  errors: number;
  byStatus: Record<ActionTaken, number>;
  byRepo: Record<string, number>;
}

export interface ReportConfig {
  out_dir: string;
  write_json: boolean;
  write_csv: boolean;
}

export class Reporter {
  private records: CleanupRecord[] = [];
  private config: ReportConfig;
  private startTime: Date;

  constructor(config: ReportConfig) {
    this.config = config;
    this.startTime = new Date();
  }

  addRecord(record: CleanupRecord): void {
    this.records.push(record);
  }

  getSummary(): ReportSummary {
    const summary: ReportSummary = {
      totalBranches: this.records.length,
      deleted: 0,
      skipped: 0,
      errors: 0,
      byStatus: {} as Record<ActionTaken, number>,
      byRepo: {},
    };

    for (const record of this.records) {
      // Count by status
      if (!summary.byStatus[record.actionTaken]) {
        summary.byStatus[record.actionTaken] = 0;
      }
      summary.byStatus[record.actionTaken]++;

      // Count by repo
      const repoKey = `${record.org}/${record.repo}`;
      if (!summary.byRepo[repoKey]) {
        summary.byRepo[repoKey] = 0;
      }
      summary.byRepo[repoKey]++;

      // Overall counts
      if (record.actionTaken === 'Deleted') {
        summary.deleted++;
      } else if (record.actionTaken === 'Error') {
        summary.errors++;
      } else {
        summary.skipped++;
      }
    }

    return summary;
  }

  async writeReports(dryRun: boolean = false): Promise<void> {
    const dateStr = dayjs().format('YYYY-MM-DD-HHmmss');
    const reportDir = path.join(this.config.out_dir, dateStr);

    if (!dryRun) {
      fs.mkdirSync(reportDir, { recursive: true });
    }

    const summary = this.getSummary();
    const duration = Date.now() - this.startTime.getTime();

    // Write JSON
    if (this.config.write_json) {
      const jsonPath = path.join(reportDir, 'report.json');
      const jsonData = {
        metadata: {
          timestamp: dayjs().toISOString(),
          duration_ms: duration,
          dry_run: dryRun,
        },
        summary,
        records: this.records,
      };

      if (dryRun) {
        console.log(`[DRY-RUN] Would write JSON to: ${jsonPath}`);
        console.log(JSON.stringify(jsonData, null, 2).substring(0, 500) + '...');
      } else {
        fs.writeFileSync(jsonPath, JSON.stringify(jsonData, null, 2));
        console.log(`✓ Wrote JSON report: ${jsonPath}`);
      }
    }

    // Write CSV
    if (this.config.write_csv) {
      const csvPath = path.join(reportDir, 'report.csv');

      try {
        const csv = jsonToCsv(this.records, {
          fields: [
            'org',
            'repo',
            'branch',
            'headSha',
            'mergedPr',
            'mergedAt',
            'defaultBranch',
            'protected',
            'actionTaken',
            'backupTag',
            'error',
          ],
        });

        if (dryRun) {
          console.log(`[DRY-RUN] Would write CSV to: ${csvPath}`);
          console.log(csv.split('\n').slice(0, 5).join('\n') + '...');
        } else {
          fs.writeFileSync(csvPath, csv);
          console.log(`✓ Wrote CSV report: ${csvPath}`);
        }
      } catch (error) {
        console.error('Failed to write CSV:', error);
      }
    }

    // Write summary
    const summaryPath = path.join(reportDir, 'summary.txt');
    const summaryText = this.generateSummaryText(summary, duration, dryRun);

    if (dryRun) {
      console.log(`[DRY-RUN] Would write summary to: ${summaryPath}`);
    } else {
      fs.writeFileSync(summaryPath, summaryText);
      console.log(`✓ Wrote summary: ${summaryPath}`);
    }

    // Always print summary to console
    console.log('\n' + summaryText);
  }

  private generateSummaryText(summary: ReportSummary, duration: number, dryRun: boolean): string {
    const lines: string[] = [];

    lines.push('='.repeat(80));
    lines.push(`BRANCH CLEANUP REPORT${dryRun ? ' (DRY-RUN)' : ''}`);
    lines.push('='.repeat(80));
    lines.push('');
    lines.push(`Timestamp: ${dayjs().format('YYYY-MM-DD HH:mm:ss')}`);
    lines.push(`Duration: ${(duration / 1000).toFixed(2)}s`);
    lines.push('');

    lines.push('Overall Summary:');
    lines.push(`  Total branches processed: ${summary.totalBranches}`);
    lines.push(`  Deleted: ${summary.deleted}`);
    lines.push(`  Skipped: ${summary.skipped}`);
    lines.push(`  Errors: ${summary.errors}`);
    lines.push('');

    lines.push('By Status:');
    for (const [status, count] of Object.entries(summary.byStatus)) {
      lines.push(`  ${status}: ${count}`);
    }
    lines.push('');

    lines.push('By Repository:');
    for (const [repo, count] of Object.entries(summary.byRepo)) {
      lines.push(`  ${repo}: ${count}`);
    }
    lines.push('');

    if (summary.errors > 0) {
      lines.push('⚠ ERRORS DETECTED - Review report.json for details');
      lines.push('');
    }

    lines.push('='.repeat(80));

    return lines.join('\n');
  }

  hasErrors(): boolean {
    return this.records.some((r) => r.actionTaken === 'Error');
  }
}
