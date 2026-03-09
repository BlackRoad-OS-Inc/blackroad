export interface Event<T = unknown> {
  id: string;
  type: string;
  source: string;
  time: string;
  data: T;
}

export class EventBus {
  private handlers = new Map<string, ((event: Event) => Promise<void>)[]>();

  async publish<T>(type: string, data: T): Promise<void> {
    const event: Event<T> = {
      id: crypto.randomUUID(),
      type,
      source: 'blackroad',
      time: new Date().toISOString(),
      data
    };

    const handlers = this.getHandlers(type);
    await Promise.all(handlers.map(h => h(event)));
  }

  subscribe(pattern: string, handler: (event: Event) => Promise<void>): void {
    const existing = this.handlers.get(pattern) || [];
    this.handlers.set(pattern, [...existing, handler]);
  }

  private getHandlers(type: string): ((event: Event) => Promise<void>)[] {
    const handlers: ((event: Event) => Promise<void>)[] = [];
    for (const [pattern, fns] of this.handlers) {
      if (this.matches(type, pattern)) handlers.push(...fns);
    }
    return handlers;
  }

  private matches(type: string, pattern: string): boolean {
    const regex = new RegExp('^' + pattern.replace(/\*/g, '.*') + '$');
    return regex.test(type);
  }
}

export default { EventBus };
