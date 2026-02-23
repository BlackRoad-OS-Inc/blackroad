// drive.blackroad.io → Pi rclone web serve on :8090
export default {
  async fetch(request) {
    const url = new URL(request.url);
    const target = `http://52915859-da18-4aa6-add5-7bd9fcac2e0b.cfargotunnel.com${url.pathname}${url.search}`;
    
    const headers = new Headers(request.headers);
    headers.set("Host", "drive.blackroad.io");
    
    return fetch(target, {
      method: request.method,
      headers,
      body: ["GET","HEAD"].includes(request.method) ? null : request.body,
      redirect: "follow",
    });
  }
};
