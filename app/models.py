from app import db
from datetime import datetime
from flask_login import UserMixin

class Role(db.Model):
    __tablename__ = 'roles'
    
    id = db.Column(db.Integer(), primary_key=True)
    name = db.Column(db.String(80), unique=True)
    description = db.Column(db.String(255))
    
    def __str__(self):
        return self.name

class User(db.Model, UserMixin):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    username = db.Column(db.String(80), unique=True, nullable=True)
    password_hash = db.Column(db.String(255), nullable=False)
    active = db.Column(db.Boolean(), default=True)
    confirmed_at = db.Column(db.DateTime())
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime())
    
    # Relationships
    roles = db.relationship('Role', secondary='user_roles', backref=db.backref('users', lazy='dynamic'))
    screenplays = db.relationship('Screenplay', backref='author', lazy=True, cascade='all, delete-orphan')
    
    def __str__(self):
        return self.username or self.email.split('@')[0]
    
    def set_password(self, password):
        """Set password hash"""
        from werkzeug.security import generate_password_hash
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        """Check password against hash"""
        from werkzeug.security import check_password_hash
        return check_password_hash(self.password_hash, password)

# Association table for user-role many-to-many relationship
user_roles = db.Table('user_roles',
    db.Column('user_id', db.Integer(), db.ForeignKey('users.id'), primary_key=True),
    db.Column('role_id', db.Integer(), db.ForeignKey('roles.id'), primary_key=True)
)

class Screenplay(db.Model):
    __tablename__ = 'screenplays'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    content = db.Column(db.Text, nullable=False, default='')
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    scenes = db.relationship('Scene', backref='screenplay', lazy=True, cascade='all, delete-orphan')
    characters = db.relationship('Character', backref='screenplay', lazy=True, cascade='all, delete-orphan')
    changes = db.relationship('ScreenplayChange', backref='screenplay', lazy=True, cascade='all, delete-orphan')
    
    def __repr__(self):
        return f'<Screenplay {self.title}>'

class Scene(db.Model):
    __tablename__ = 'scenes'
    
    id = db.Column(db.Integer, primary_key=True)
    screenplay_id = db.Column(db.Integer, db.ForeignKey('screenplays.id'), nullable=False)
    scene_number = db.Column(db.Integer)
    heading = db.Column(db.String(200))
    location = db.Column(db.String(100))
    time_of_day = db.Column(db.String(50))
    content = db.Column(db.Text)
    order = db.Column(db.Integer, default=0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<Scene {self.scene_number}: {self.heading}>'

class Character(db.Model):
    __tablename__ = 'characters'
    
    id = db.Column(db.Integer, primary_key=True)
    screenplay_id = db.Column(db.Integer, db.ForeignKey('screenplays.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    arc_notes = db.Column(db.Text)
    ai_arc_suggestion = db.Column(db.Text)  # Store AI suggestion for character arc
    ai_suggestion_updated = db.Column(db.DateTime)  # When AI suggestion was last updated
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<Character {self.name}>'

class PromptConfig(db.Model):
    __tablename__ = 'prompt_config'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    max_characters = db.Column(db.Integer, default=2000)
    character_arc_prompt = db.Column(db.Text)
    plot_development_prompt = db.Column(db.Text)
    dialogue_enhancement_prompt = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship
    user = db.relationship('User', backref=db.backref('prompt_config', lazy=True, uselist=False))
    
    def __repr__(self):
        return f'<PromptConfig for User {self.user_id}>'

class ScreenplayChange(db.Model):
    """Track changes for undo/redo functionality"""
    __tablename__ = 'screenplay_changes'
    
    id = db.Column(db.Integer, primary_key=True)
    screenplay_id = db.Column(db.Integer, db.ForeignKey('screenplays.id'), nullable=False)
    content = db.Column(db.Text, nullable=False)
    change_type = db.Column(db.String(20), default='auto_save')  # auto_save, manual_save, undo, redo
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<ScreenplayChange {self.change_type} at {self.created_at}>'
