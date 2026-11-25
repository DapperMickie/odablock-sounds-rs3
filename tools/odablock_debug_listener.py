"""Write RS3 developer traces received over the local loopback interface."""

import argparse
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=Path)
    args = parser.parse_args()

    class LogHandler(BaseHTTPRequestHandler):
        def log_message(self, *_args):
            pass

        def do_GET(self):
            self.send_response(204 if self.path == "/health" else 404)
            self.end_headers()

        def do_POST(self):
            if self.path != "/odablock-debug":
                self.send_error(404)
                return
            if self.headers.get("Origin") or self.headers.get("Sec-Fetch-Site"):
                self.send_error(403)
                return
            try:
                size = int(self.headers.get("Content-Length", "0"))
                if not 0 < size <= 65536:
                    raise ValueError("Invalid body size")
                body = self.rfile.read(size).decode("utf-8", errors="replace")
                if not body.splitlines() or any(
                    not line.startswith("[Odablock dev ") for line in body.splitlines()
                ):
                    raise ValueError("Invalid trace line")
            except ValueError:
                self.send_error(400)
                return
            with args.log.open("a", encoding="utf-8") as trace:
                trace.write(body.rstrip("\n") + "\n")
            self.send_response(204)
            self.end_headers()

    class LogServer(HTTPServer):
        def get_request(self):
            connection, address = super().get_request()
            connection.settimeout(3)
            return connection, address

    with LogServer(("127.0.0.1", 43867), LogHandler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
