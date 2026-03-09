# Java Hello World on Raspberry Pi

**Live at:** https://java.blackroad.io

A Java 17 HTTP server running on Raspberry Pi 5, exposed to the internet via Cloudflare Tunnel.

## Architecture

```
Internet → java.blackroad.io 
         → Cloudflare Edge 
         → Cloudflared Tunnel 
         → Pi 192.168.4.38:80 (nginx) 
         → localhost:8888 (Java HttpServer)
```

## Features

- Dynamic timestamps (updates every request)
- BlackRoad Design System colors
- Auto-start via systemd
- Zero-config deployment

## Files

- `HelloWorld.java` - Java HTTP server with embedded HTML
- `java-hello.service` - systemd service unit
- `nginx.conf` - nginx reverse proxy configuration
- `index.html` - Static preview page

## Deploy

```bash
# SSH to Pi
ssh pi@192.168.4.38

# Edit code
vi ~/java-hello/HelloWorld.java

# Recompile
javac HelloWorld.java

# Restart
sudo systemctl restart java-hello

# Done! Takes ~2 seconds
```

## Stack

- **Runtime:** Java 17 (OpenJDK)
- **Server:** com.sun.net.httpserver.HttpServer
- **Proxy:** nginx
- **Tunnel:** cloudflared
- **Host:** Raspberry Pi 5

---

🖤 Part of [BlackRoad OS](https://github.com/BlackRoad-OS)
