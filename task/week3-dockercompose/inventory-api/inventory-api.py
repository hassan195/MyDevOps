from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import re
import os
import psycopg2
import logging
from psycopg2 import pool


## ==========================================
## 0. 日志配置
## ==========================================

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger("InventoryAPI")

# ==========================================
# 1. 数据库配置（请修改为你真实的 PostgreSQL 信息）
# ==========================================
DB_CONFIG = {

    "dbname": os.environ.get("POSTGRES_DB", "inventory_db"),
    "user": os.environ.get("POSTGRES_USER", "inventory_user"),
    "password": os.environ.get("POSTGRES_PASSWORD"),
    "host": os.environ.get("POSTGRES_HOST", "localhost"),
    "port": 5432
}

# 初始化数据库连接池（推荐做法，避免每次 HTTP 请求都建立/销毁连接）
try:
    db_pool = psycopg2.pool.SimpleConnectionPool(1, 10, **DB_CONFIG)
    logger.info("Database connection pool created successfully")
except Exception as e:
    logger.error(f"Error creating connection pool: {e}")
    db_pool = None


# ==========================================
# 2. 从数据库动态查询库存的核心函数
# ==========================================
def query_inventory_from_db(item_id):
    """根据 item_id 动态查询 PostgreSQL 数据库"""
    if not db_pool:
        logger.error("Database connection pool is not initialized")
        raise Exception("Database connection pool is not initialized")
    conn = None
    try:
        # 从连接池中获取一个连接
        logger.info(f"Querying inventory for item_id: {item_id}")
        conn = db_pool.getconn()
        with conn.cursor() as cursor:
            # 强化安全的参数化 SQL 查询（%s 会自动安全转义，防止 SQL 注入）
            query = "SELECT sku, product_name, qty, warehouse FROM product_stock WHERE sku = %s;"
            cursor.execute(query, (item_id,))
            
            row = cursor.fetchone()
            
            if row:
                # 将数据库行数据映射为字典/JSON结构
                logger.info(f"Found inventory item: {row}")
                return {
                    "sku": row[0],
                    "product_name": row[1],
                    "qty": row[2],
                    "warehouse": row[3],
                    "source": "postgresql-db"
                }
            else:
                logger.warning(f"Inventory item not found for sku: {item_id}")
                return None
    except Exception as e:
        logger.error(f"Database query error: {e}")
        raise
    finally:
        # 使用完毕后将连接还给连接池
        if conn:
            db_pool.putconn(conn)


# ==========================================
# 3. HTTP 请求处理逻辑
# ==========================================
class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        """重写日志方法，使用自定义 logger"""
        logger.info("%s - - [%s] %s" %
                    (self.client_address[0],
                     self.log_date_time_string(),
                     format % args))

    def do_GET(self):
        try:
            logger.info(f"Received GET request for path: {self.path}")

            # 健康检查路由
            if self.path == "/health":
                self._send_json(200, {"status": "healthy"})
                return

            # 匹配路由 /inventory/<id> (例如 /inventory/42)
            inventory_match = re.match(r"^/inventory/(\d+)$", self.path)
            
            if inventory_match:
                item_id = int(inventory_match.group(1))
                
                try:
                    # 动态去数据库查询真实数据
                    data = query_inventory_from_db(item_id)
                    
                    if data:
                        self._send_json(200, data)
                    else:
                        self._send_json(404, {"error": f"Item with ID {item_id} not found in inventory"})
                        
                except Exception as e:
                    self._send_json(500, {"error": "Internal Server Error", "details": str(e)})

            # 保留底层的 /inventory-api（可选，做基础健康检查）
            elif self.path == "/inventory-api":
                self._send_json(200, {"message": "Inventory API service is running"})
                
            else:
                logger.warning(f"Route not found for path: {self.path}")
                self._send_json(404, {"error": "Route Not Found"})
        except (BrokenPipeError, ConnectionResetError) as e:
            pass
        except Exception as e:
            try:
                self._send_json(500, {"error": "Internal Server Error", "details": str(e)})
            except (BrokenPipeError, ConnectionResetError) as e:
                pass

    def _send_json(self, statusCode, data):
        """辅助方法：统一响应 JSON 格式"""
        response_bytes = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(statusCode)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(response_bytes)))
        self.end_headers()
        self.wfile.write(response_bytes)


# ==========================================
# 4. 启动 HTTP 服务器
# ==========================================
if __name__ == "__main__":
    server_address = ("0.0.0.0",3000 )
    httpd = HTTPServer(server_address, Handler)
    logging.info(f"Server running on http://localhost:{server_address[1]}")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        logging.info("\nShutting down server...")
        httpd.server_close()
        if db_pool:
            db_pool.closeall()
        logging.info("Server and DB connections stopped gracefully.")