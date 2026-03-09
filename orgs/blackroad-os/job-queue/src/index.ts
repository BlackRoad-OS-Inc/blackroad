export interface JobOptions {
  priority?: number;
  delay?: number;
  attempts?: number;
  backoff?: { type: 'fixed' | 'exponential'; delay: number };
}

export interface Job<T = unknown> {
  id: string;
  name: string;
  data: T;
  opts: JobOptions;
  progress: number;
  attemptsMade: number;
}

export class Queue {
  constructor(private name: string) {}

  async add<T>(name: string, data: T, opts: JobOptions = {}): Promise<Job<T>> {
    const job: Job<T> = {
      id: crypto.randomUUID(),
      name,
      data,
      opts,
      progress: 0,
      attemptsMade: 0
    };
    console.log(`[Queue:${this.name}] Added job: ${job.id}`);
    return job;
  }

  async getJobs(status: 'waiting' | 'active' | 'completed' | 'failed'): Promise<Job[]> {
    return [];
  }
}

export class Worker {
  constructor(
    private queueName: string,
    private processor: (job: Job) => Promise<unknown>
  ) {
    console.log(`[Worker:${queueName}] Started`);
  }
}

export default { Queue, Worker };
