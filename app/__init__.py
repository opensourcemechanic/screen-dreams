from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from flask_principal import Principal, identity_loaded, UserNeed, RoleNeed
from flask_mail import Mail
import os
from datetime import datetime

db = SQLAlchemy()
mail = Mail()
login_manager = LoginManager()
principal = Principal()

def _data_dir() -> str:
    """
    Resolve the persistent data directory.

    Priority:
      1. DATA_DIR environment variable (explicit override)
      2. ~/.local/share/screen-dreams  (XDG default — survives uvx re-runs)

    Never use os.getcwd() so that uvx's ephemeral working directory
    does not cause a fresh database on every invocation.
    """
    path = os.environ.get(
        'DATA_DIR',
        os.path.join(os.path.expanduser('~'), '.local', 'share', 'screen-dreams')
    )
    os.makedirs(path, exist_ok=True)
    os.makedirs(os.path.join(path, 'screenplays'), exist_ok=True)
    os.makedirs(os.path.join(path, 'uploads'), exist_ok=True)
    return path


def create_app():
    _pkg_dir = os.path.dirname(__file__)
    _tmpl = os.path.join(_pkg_dir, 'templates')
    _static = os.path.join(_pkg_dir, 'static')
    app = Flask(__name__,
                template_folder=_tmpl,
                static_folder=_static)

    data_dir = _data_dir()

    # Configuration
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(data_dir, 'screen_dreams.db')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SCREENPLAY_FOLDER'] = os.path.join(data_dir, 'screenplays')
    app.config['UPLOAD_FOLDER'] = os.path.join(data_dir, 'uploads')
    app.config['DATA_DIR'] = data_dir
    app.config['AUTO_SAVE_INTERVAL'] = int(os.environ.get('AUTO_SAVE_INTERVAL', '15'))  # Default 15 seconds
    
    # Flask-Login configuration
    login_manager.init_app(app)
    login_manager.login_view = 'auth.login'
    login_manager.login_message = 'Please log in to access this page.'
    login_manager.login_message_category = 'info'
    
    # Flask-Principal configuration
    principal.init_app(app)
    
    # Identity loading
    @identity_loaded.connect_via(app)
    def on_identity_loaded(sender, identity):
        from flask_login import current_user
        if current_user.is_authenticated:
            identity.provides.add(UserNeed(current_user.id))
            # Add role needs
            for role in current_user.roles:
                identity.provides.add(RoleNeed(role.name))
    
    # Email configuration (for future password reset functionality)
    app.config['MAIL_SERVER'] = os.environ.get('MAIL_SERVER', 'localhost')
    app.config['MAIL_PORT'] = int(os.environ.get('MAIL_PORT', '587'))
    app.config['MAIL_USE_TLS'] = os.environ.get('MAIL_USE_TLS', 'false').lower() == 'true'
    app.config['MAIL_USERNAME'] = os.environ.get('MAIL_USERNAME', '')
    app.config['MAIL_PASSWORD'] = os.environ.get('MAIL_PASSWORD', '')
    
    # Register health check route
    @app.route('/health')
    def health_check():
        return jsonify({"status": "healthy"})
    
    # Initialize extensions
    db.init_app(app)
    mail.init_app(app)
    
    # Setup Flask-Login user loader
    @login_manager.user_loader
    def load_user(user_id):
        from app.models import User
        return User.query.get(int(user_id))
    
    # Register blueprints
    from app.routes import main
    from app.auth import auth
    
    # Register import/export routes first
    from app.import_export import register_import_export_routes
    main = register_import_export_routes(main)
    
    app.register_blueprint(main)
    app.register_blueprint(auth, url_prefix='/auth')
    
    # Create database tables and demo user/role
    with app.app_context():
        db.create_all()
        create_demo_user()
    
    return app

def create_demo_user():
    """Create a demo user for testing"""
    from app.models import User, Role
    
    # Create user role if it doesn't exist
    user_role = Role.query.filter_by(name='user').first()
    if not user_role:
        user_role = Role(name='user', description='Regular user')
        db.session.add(user_role)
        db.session.commit()
    
    # Check if demo user exists
    demo_user = User.query.filter_by(email='demo@example.com').first()
    if not demo_user:
        demo_user = User(
            email='demo@example.com',
            username='demo',
            active=True,
            confirmed_at=datetime.utcnow()
        )
        demo_user.set_password('demo123')
        demo_user.roles.append(user_role)
        db.session.add(demo_user)
        db.session.commit()
        print("Demo user created: email='demo@example.com', username='demo', password='demo123'")
    else:
        # Ensure demo user has user role
        if user_role not in demo_user.roles:
            demo_user.roles.append(user_role)
            db.session.commit()
