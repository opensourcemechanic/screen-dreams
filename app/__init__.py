from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_security import Security, SQLAlchemyUserDatastore
from flask_mail import Mail
import os
from datetime import datetime

db = SQLAlchemy()
mail = Mail()
security = Security()

def create_app():
    app = Flask(__name__, 
                template_folder='../templates',
                static_folder='../static')
    
    # Configuration
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///screenwriter.db'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SCREENPLAY_FOLDER'] = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'screenplays')
    app.config['AUTO_SAVE_INTERVAL'] = int(os.environ.get('AUTO_SAVE_INTERVAL', '15'))  # Default 15 seconds
    
    # Flask-Security-Too configuration
    app.config['SECURITY_REGISTERABLE'] = True
    app.config['SECURITY_SEND_REGISTER_EMAIL'] = False  # Disable email confirmation for now
    app.config['SECURITY_PASSWORD_SALT'] = os.environ.get('SECURITY_PASSWORD_SALT', 'super-secret-salt-change-in-production')
    app.config['SECURITY_PASSWORD_HASH'] = 'argon2'
    app.config['SECURITY_PASSWORD_LENGTH_MIN'] = int(os.environ.get('PASSWORD_MIN_LENGTH', '8'))
    
    # Password policy configuration
    app.config['SECURITY_PASSWORD_COMPLEXITY'] = {
        'lowercase': int(os.environ.get('PASSWORD_REQUIRE_LOWERCASE', 'true') == 'true'),
        'uppercase': int(os.environ.get('PASSWORD_REQUIRE_UPPERCASE', 'true') == 'true'),
        'numbers': int(os.environ.get('PASSWORD_REQUIRE_NUMBERS', 'true') == 'true'),
        'special': int(os.environ.get('PASSWORD_REQUIRE_SPECIAL', 'false') == 'true'),
        'email': 0,  # Don't require email in password
        'website': 0,  # Don't require website in password
        'username': 0,  # Don't require username in password
    }
    
    # Email configuration (for future password reset functionality)
    app.config['MAIL_SERVER'] = os.environ.get('MAIL_SERVER', 'localhost')
    app.config['MAIL_PORT'] = int(os.environ.get('MAIL_PORT', '587'))
    app.config['MAIL_USE_TLS'] = os.environ.get('MAIL_USE_TLS', 'false').lower() == 'true'
    app.config['MAIL_USERNAME'] = os.environ.get('MAIL_USERNAME', '')
    app.config['MAIL_PASSWORD'] = os.environ.get('MAIL_PASSWORD', '')
    
    # Initialize extensions
    db.init_app(app)
    mail.init_app(app)
    
    # Setup Flask-Security
    from app.models import User, Role
    user_datastore = SQLAlchemyUserDatastore(db, User, Role)
    security.init_app(app, user_datastore)
    
    # Register blueprints
    from app.routes import main
    app.register_blueprint(main)
    
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
    
    # Check if demo user exists
    demo_user = User.query.filter_by(email='demo@example.com').first()
    if not demo_user:
        # Get user_datastore from the current app
        from flask import current_app
        user_datastore = current_app.extensions['security'].datastore
        
        demo_user = user_datastore.create_user(
            email='demo@example.com',
            username='demo',
            password='demo123',
            active=True,
            confirmed_at=datetime.utcnow()
        )
        user_datastore.add_role_to_user(demo_user, user_role)
        db.session.commit()
        print("Demo user created: email='demo@example.com', username='demo', password='demo123'")
    else:
        # Ensure demo user has user role
        if user_role not in demo_user.roles:
            from flask import current_app
            user_datastore = current_app.extensions['security'].datastore
            user_datastore.add_role_to_user(demo_user, user_role)
            db.session.commit()
