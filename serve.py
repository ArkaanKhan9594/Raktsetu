import os
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler

class NoCacheHTTPRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

if __name__ == '__main__':
    web_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'web')
    if not os.path.exists(web_dir):
        print(f"Error: {web_dir} does not exist.")
        sys.exit(1)
    os.chdir(web_dir)
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    server = HTTPServer(('0.0.0.0', port), NoCacheHTTPRequestHandler)
    print(f"Serving {web_dir} on port {port} with strict NO-CACHE headers...")
    server.serve_forever()
