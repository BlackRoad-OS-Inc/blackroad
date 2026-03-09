import com.sun.net.httpserver.HttpServer;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class HelloWorld {
    public static void main(String[] args) throws Exception {
        int port = 8888;
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        server.createContext("/", exchange -> {
            String now = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            String response = "<!DOCTYPE html>\n" +
"<html><head><title>Hello World - Java on Pi | BlackRoad.io</title>\n" +
"<style>\n" +
"body{background:#000;color:#fff;font-family:'JetBrains Mono',monospace;display:flex;justify-content:center;align-items:center;min-height:100vh;margin:0}\n" +
".container{text-align:center}\n" +
"h1{font-size:3rem;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent}\n" +
".java{color:#F5A623}\n" +
".pi{color:#FF1D6C}\n" +
".time{color:#2979FF;font-size:1.5rem;margin:1rem 0}\n" +
"pre{background:#111;padding:20px;border-radius:8px;text-align:left;display:inline-block;border:1px solid #333}\n" +
".live{color:#2979FF;animation:pulse 2s infinite}\n" +
"@keyframes pulse{0%,100%{opacity:1}50%{opacity:.5}}\n" +
".footer{margin-top:2rem;color:#666;font-size:0.9rem}\n" +
".update{color:#9C27B0;font-size:0.8rem;margin-top:1rem}\n" +
"</style></head>\n" +
"<body><div class=\"container\">\n" +
"<h1>Hello, World!</h1>\n" +
"<p class=\"time\">" + now + "</p>\n" +
"<p>Running <span class=\"java\">Java 17</span> on <span class=\"pi\">Raspberry Pi 5</span></p>\n" +
"<p class=\"live\">● Live from Pi @ 192.168.4.38</p>\n" +
"<pre>public class HelloWorld {\n" +
"    public static void main(String[] args) {\n" +
"        System.out.println(\"Hello, World!\");\n" +
"    }\n" +
"}</pre>\n" +
"<p class=\"update\">Hot-deployed in seconds!</p>\n" +
"<p class=\"footer\">nginx → Java 17 → cloudflared tunnel → blackroad.io</p>\n" +
"</div></body></html>";
            byte[] bytes = response.getBytes("UTF-8");
            exchange.getResponseHeaders().set("Content-Type", "text/html; charset=utf-8");
            exchange.sendResponseHeaders(200, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        });
        server.setExecutor(null);
        server.start();
        System.out.println("Java Hello World running on port " + port);
    }
}
