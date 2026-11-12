import json
import subprocess
import threading
from pathlib import Path
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = Path(__file__).resolve().parent
PAGE = (HERE / "index.html").read_bytes()
lock = threading.Lock()


class Handler(BaseHTTPRequestHandler):
    def reply(self, status, mime, data):
        self.send_response(status)
        self.send_header("Content-Type", mime)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/":
            self.reply(200, "text/html; charset=utf-8", PAGE)
        else:
            self.send_error(404)

    def do_POST(self):
        if self.path != "/predict":
            return self.send_error(404)
        if self.headers.get("Content-Type") != "application/octet-stream":
            return self.send_error(415)
        if self.headers.get("Content-Length") != "784":
            return self.send_error(400)
        pixels = self.rfile.read(784)
        if len(pixels) != 784 or not any(pixels):
            return self.send_error(400)
        try:
            with lock:
                worker.stdin.write(pixels)
                worker.stdin.flush()
                values = worker.stdout.readline().split()
                if len(values) != 15:
                    raise ValueError("Missing FPGA response")
            data = json.dumps(dict(digit=int(values[0]), logits=list(map(int, values[1:11])), timing_us=list(map(float, values[11:])))).encode()
            self.reply(200, "application/json", data)
        except (ValueError, BrokenPipeError):
            self.send_error(503, "FPGA worker unavailable; check board terminal")


if __name__ == "__main__":
    with ThreadingHTTPServer(("127.0.0.1", 8080), Handler) as server:
        worker = subprocess.Popen(["sudo", str(HERE / "worker")], cwd=HERE.parent,
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        try:
            if worker.stdout.readline().strip() != b"READY":
                raise SystemExit("FPGA initialization failed")
            print("KR260 ready at 127.0.0.1:8080", flush=True)
            server.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            worker.stdin.close()
            worker.wait()
