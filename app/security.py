"""
Security enhancements for Screen Dreams Screenwriter
Handles HTTPS enforcement, security headers, and secure configuration
"""

import os
from flask import Flask, request, redirect, url_for
from werkzeug.middleware.proxy_fix import ProxyFix

def configure_security(app: Flask):
    """Configure security settings for the Flask app"""
    
    # Trust proxy headers for HTTPS
    app.wsgi_app = ProxyFix(
        app.wsgi_app,
        x_for=1,
        x_proto=1,
        x_host=1,
        x_prefix=1
    )
    
    # HTTPS enforcement
    @app.before_request
    def force_https():
        """Force HTTPS in production"""
        if os.environ.get('FORCE_HTTPS', 'False').lower() == 'true':
            if not request.is_secure and request.headers.get('X-Forwarded-Proto') != 'https':
                if request.url.startswith('http://'):
                    url = request.url.replace('http://', 'https://', 1)
                    return redirect(url, code=301)
    
    # Security headers
    @app.after_request
    def add_security_headers(response):
        """Add security headers to all responses"""
        
        # HTTPS enforcement
        if request.is_secure or request.headers.get('X-Forwarded-Proto') == 'https':
            response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
        
        # XSS Protection
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'DENY'
        response.headers['X-XSS-Protection'] = '1; mode=block'
        
        # Referrer Policy
        response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
        
        # Content Security Policy
        csp_directives = [
            f"default-src {os.environ.get('CSP_DEFAULT_SRC', \"'self'\")}",
            f"script-src {os.environ.get('CSP_SCRIPT_SRC', \"'self' 'unsafe-inline'\")}",
            f"style-src {os.environ.get('CSP_STYLE_SRC', \"'self' 'unsafe-inline'\")}",
            f"img-src {os.environ.get('CSP_IMG_SRC', \"'self' data:\")}",
            f"font-src {os.environ.get('CSP_FONT_SRC', \"'self'\")}",
            "object-src 'none'",
            "base-uri 'self'"
        ]
        response.headers['Content-Security-Policy'] = '; '.join(csp_directives)
        
        # Permissions Policy (Feature Policy)
        permissions_policy = [
            "geolocation=()",
            "microphone=()",
            "camera=()",
            "payment=()",
            "usb=()",
            "magnetometer=()",
            "gyroscope=()",
            "speaker=()"
        ]
        response.headers['Permissions-Policy'] = ', '.join(permissions_policy)
        
        return response

def configure_session_security(app: Flask):
    """Configure secure session settings"""
    
    # Session security
    app.config['SESSION_COOKIE_SECURE'] = os.environ.get('SESSION_COOKIE_SECURE', 'True').lower() == 'true'
    app.config['SESSION_COOKIE_HTTPONLY'] = os.environ.get('SESSION_COOKIE_HTTPONLY', 'True').lower() == 'true'
    app.config['SESSION_COOKIE_SAMESITE'] = os.environ.get('SESSION_COOKIE_SAMESITE', 'Lax')
    
    # Remember me cookie security
    app.config['REMEMBER_COOKIE_SECURE'] = os.environ.get('REMEMBER_COOKIE_SECURE', 'True').lower() == 'true'
    app.config['REMEMBER_COOKIE_HTTPONLY'] = os.environ.get('REMEMBER_COOKIE_HTTPONLY', 'True').lower() == 'true'
    app.config['REMEMBER_COOKIE_DURATION'] = int(os.environ.get('REMEMBER_COOKIE_DURATION', '2592000'))  # 30 days
    
    # CSRF protection
    app.config['WTF_CSRF_ENABLED'] = True
    app.config['WTF_CSRF_TIME_LIMIT'] = int(os.environ.get('WTF_CSRF_TIME_LIMIT', '3600'))  # 1 hour

def configure_file_upload_security(app: Flask):
    """Configure secure file upload settings"""
    
    # File upload limits
    app.config['MAX_CONTENT_LENGTH'] = int(os.environ.get('MAX_CONTENT_LENGTH', '104857600'))  # 100MB
    
    # Allowed file extensions
    app.config['ALLOWED_EXTENSIONS'] = {
        'fountain', 'txt', 'pdf', 'json', 'zip'
    }
    
    # Upload folder
    upload_folder = os.environ.get('UPLOAD_FOLDER', '/opt/screen-dreams/uploads')
    app.config['UPLOAD_FOLDER'] = upload_folder
    
    # Create upload folder if it doesn't exist
    os.makedirs(upload_folder, exist_ok=True)

def allowed_file(filename: str, app: Flask) -> bool:
    """Check if file extension is allowed"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_EXTENSIONS']

def secure_filename_enhanced(filename: str) -> str:
    """Enhanced secure filename function"""
    import re
    from werkzeug.utils import secure_filename
    
    # Use werkzeug's secure_filename as base
    filename = secure_filename(filename)
    
    # Additional sanitization
    filename = re.sub(r'[^\w\-_\.]', '', filename)
    
    # Ensure filename is not empty and has reasonable length
    if not filename or len(filename) > 255:
        filename = 'upload.txt'
    
    return filename

class SecurityConfig:
    """Security configuration constants"""
    
    # Password requirements
    PASSWORD_MIN_LENGTH = int(os.environ.get('PASSWORD_MIN_LENGTH', '8'))
    PASSWORD_REQUIRE_UPPERCASE = os.environ.get('PASSWORD_REQUIRE_UPPERCASE', 'true').lower() == 'true'
    PASSWORD_REQUIRE_LOWERCASE = os.environ.get('PASSWORD_REQUIRE_LOWERCASE', 'true').lower() == 'true'
    PASSWORD_REQUIRE_NUMBERS = os.environ.get('PASSWORD_REQUIRE_NUMBERS', 'true').lower() == 'true'
    PASSWORD_REQUIRE_SPECIAL = os.environ.get('PASSWORD_REQUIRE_SPECIAL', 'false').lower() == 'true'
    
    # Rate limiting
    RATE_LIMIT_STORAGE_URL = os.environ.get('RATELIMIT_STORAGE_URL', 'memory://')
    
    # Session timeout
    PERMANENT_SESSION_LIFETIME = int(os.environ.get('PERMANENT_SESSION_LIFETIME', '3600'))  # 1 hour
    
    # API security
    API_RATE_LIMIT = os.environ.get('API_RATE_LIMIT', '100/hour')
    LOGIN_RATE_LIMIT = os.environ.get('LOGIN_RATE_LIMIT', '5/minute')
