# Gunicorn configuration file for Screen Dreams Screenwriter
import multiprocessing
import os

# Server socket
bind = "0.0.0.0:5000"
backlog = 2048

# Worker processes (optimized for production)
workers = min(multiprocessing.cpu_count() * 2 + 1, 9)
worker_class = "sync"
worker_connections = 1000
timeout = 30
keepalive = 2

# Logging
accesslog = "-"
errorlog = "-"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "screen-dreams"

# Server mechanics
daemon = False
pidfile = "/tmp/gunicorn.pid"
user = None
group = None
tmp_upload_dir = None

# Graceful shutdown and restarts
max_requests = 1000
max_requests_jitter = 100
preload_app = False

# Security
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190

# HTTPS Support (when behind reverse proxy)
forwarded_allow_ips = "*"
secure_scheme_headers = {
    'X-FORWARDED-PROTOCOL': 'ssl',
    'X-FORWARDED-PROTO': 'https',
    'X-FORWARDED-SSL': 'on'
}

# Trust proxy headers for HTTPS
proxy_protocol = False
proxy_allow_ips = "127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"

# Environment variables for Flask
raw_env = [
    'FORCE_HTTPS=True',
    'PREFERRED_URL_SCHEME=https'
]
