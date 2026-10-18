import json
from http.server import HTTPServer, SimpleHTTPRequestHandler

HOST = "0.0.0.0"
PORT = 8080

class CustomHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        # 1. 拦截自定义的 API 路由
        if self.path == '/api/status':
            response_data = {
                "status": "healthy",
                "message": "Hello from Dockerized Python HTTPServer!"
            }
            
            # 发送 HTTP 状态码和响应头
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            
            # 写入 JSON 响应内容
            self.wfile.write(json.dumps(response_data).encode('utf-8'))
        
        # 2. 其他路径默认走静态文件处理器
        else:
            super().do_GET()

def run():
    server_address = (HOST, PORT)
    # 将 Handler 替换为我们自定义的 CustomHandler
    httpd = HTTPServer(server_address, CustomHandler)
    print(f"Serving HTTP on {HOST} port {PORT}...")
    httpd.serve_forever()

if __name__ == "__main__":
    run()
