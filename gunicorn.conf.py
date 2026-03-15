# Gunicorn configuration file for Screen Dreams Screenwriter
import multiprocessing
import os

# Server socket
bind = "127.0.0.1:8000"
backlog = 2048

# Worker processes (optimized for production)
workers = min(multiprocessing.cpu_count() * 2 + 1, 9)
worker_class = "sync"
worker_connections = 1000
timeout = 30
keepalive = 2

# Logging
accesslog = "/var/log/screen-dreams/access.log"
errorlog = "/var/log/screen-dreams/error.log"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "screen-dreams"

# Server mechanics
daemon = False
pidfile = "/var/run/screen-dreams/gunicorn.pid"
user = "www-data"
group = "www-data"
tmp_upload_dir = None

# Graceful shutdown and restarts
max_requests = 1000
max_requests_jitter = 100
preload_app = True

# Security
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190
