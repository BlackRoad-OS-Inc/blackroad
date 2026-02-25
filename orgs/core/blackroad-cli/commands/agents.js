import { spawn } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT_PATH = path.join(__dirname, '..', 'agents-zoom.sh');

export const agentsCommand = (options) => {
  const args = [];

  if (options.seed) {
    args.push('--seed', options.seed);
  }
  if (options.seedFile) {
    args.push('--seed-file', options.seedFile);
  }
  if (options.topicsFile) {
    args.push('--topics-file', options.topicsFile);
  }
  if (options.rounds) {
    args.push('--rounds', options.rounds);
  }
  if (options.mode) {
    args.push('--mode', options.mode);
  }
  if (options.agenda) {
    args.push('--agenda', options.agenda);
  }
  if (options.room) {
    args.push('--room', options.room);
  }
  if (options.prefix) {
    args.push('--prefix', options.prefix);
  }
  if (options.limit) {
    args.push('--limit', options.limit);
  }
  if (options.rosterFile) {
    args.push('--roster-file', options.rosterFile);
  }
  if (options.exclude) {
    args.push('--exclude', options.exclude);
  }
  if (options.remove) {
    const patterns = Array.isArray(options.remove) ? options.remove : [options.remove];
    patterns.filter(Boolean).forEach((pattern) => {
      args.push('--remove', pattern);
    });
  }
  if (options.mute) {
    const patterns = Array.isArray(options.mute) ? options.mute : [options.mute];
    patterns.filter(Boolean).forEach((pattern) => {
      args.push('--mute', pattern);
    });
  }
  if (options.pin) {
    const patterns = Array.isArray(options.pin) ? options.pin : [options.pin];
    patterns.filter(Boolean).forEach((pattern) => {
      args.push('--pin', pattern);
    });
  }
  if (options.queue) {
    const patterns = Array.isArray(options.queue) ? options.queue : [options.queue];
    patterns.filter(Boolean).forEach((pattern) => {
      args.push('--queue', pattern);
    });
  }
  if (options.spotlight) {
    args.push('--spotlight', options.spotlight);
  }
  if (options.shuffle) {
    args.push('--shuffle');
  }
  if (options.parallel) {
    args.push('--parallel');
  }
  if (options.roundRobin) {
    args.push('--round-robin');
  }
  if (options.speakerCount) {
    args.push('--speaker-count', options.speakerCount);
  }
  if (options.speakerDelay) {
    args.push('--speaker-delay', options.speakerDelay);
  }
  if (options.roundDelay) {
    args.push('--round-delay', options.roundDelay);
  }
  if (options.topicDelay) {
    args.push('--topic-delay', options.topicDelay);
  }
  if (options.rolesFile) {
    args.push('--roles-file', options.rolesFile);
  }
  if (options.roleDefault) {
    args.push('--role-default', options.roleDefault);
  }
  if (options.intro) {
    args.push('--intro');
  }
  if (options.rollcall) {
    args.push('--rollcall');
  }
  if (options.summary) {
    args.push('--summary');
  }
  if (options.summaryFinal) {
    args.push('--summary-final');
  }
  if (options.summaryFile) {
    args.push('--summary-file', options.summaryFile);
  }
  if (options.minutes) {
    args.push('--minutes');
  }
  if (options.minutesFile) {
    args.push('--minutes-file', options.minutesFile);
  }
  if (options.stats) {
    args.push('--stats');
  }
  if (options.statsFile) {
    args.push('--stats-file', options.statsFile);
  }
  if (options.scribe) {
    args.push('--scribe', options.scribe);
  }
  if (options.moderator) {
    args.push('--moderator', options.moderator);
  }
  if (options.transcript) {
    args.push('--transcript', options.transcript);
  }
  if (options.roster) {
    args.push('--roster');
  }
  if (options.maxChars) {
    args.push('--max-chars', options.maxChars);
  }
  if (options.contextLines) {
    args.push('--context-lines', options.contextLines);
  }
  if (options.muteVoice) {
    args.push('--mute-voice');
  }
  if (options.mic) {
    args.push('--mic');
  }

  const proc = spawn('bash', [SCRIPT_PATH, ...args], { stdio: 'inherit' });

  proc.on('close', (code) => {
    if (code && code !== 0) {
      process.exitCode = code;
    }
  });

  proc.on('error', (err) => {
    console.error(`Failed to start agent room: ${err.message}`);
    process.exitCode = 1;
  });
};
