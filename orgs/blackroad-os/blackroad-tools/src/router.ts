export class Router {
  private routes: Map<string, (req: Request, env: any) => Promise<Response>> = new Map();

  get(path: string, handler: (req: Request, env: any) => Promise<Response>) {
    this.routes.set(`GET:${path}`, handler);
  }

  post(path: string, handler: (req: Request, env: any) => Promise<Response>) {
    this.routes.set(`POST:${path}`, handler);
  }

  async handle(request: Request, env: any): Promise<Response | null> {
    const url = new URL(request.url);
    const key = `${request.method}:${url.pathname}`;
    const handler = this.routes.get(key);
    if (handler) {
      return handler(request, env);
    }
    return null;
  }
}
