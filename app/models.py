from app import db
from datetime import datetime
from flask_security import UserMixin, RoleMixin

class Role(db.Model, RoleMixin):
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
    username = db.Column(db.String(80), unique=True, nullable=True)  # Make optional for now
    password = db.Column(db.String(255), nullable=False)
    active = db.Column(db.Boolean())
    fs_uniquifier = db.Column(db.String(255), unique=True, nullable=False)
    confirmed_at = db.Column(db.DateTime())
    last_login = db.Column(db.DateTime())
    current_login_at = db.Column(db.DateTime())
    last_login_ip = db.Column(db.String(100))
    current_login_ip = db.Column(db.String(100))
    login_count = db.Column(db.Integer)
    
    # Relationships
    roles = db.relationship('Role', secondary='user_roles', backref=db.backref('users', lazy='dynamic'))
    screenplays = db.relationship('Screenplay', backref='author', lazy=True, cascade='all, delete-orphan')
    
    def __str__(self):
        return self.username or self.email.split('@')[0]
    
    def __init__(self, **kwargs):
        super(User, self).__init__(**kwargs)
        if self.email and not self.username:
            # Auto-generate username from email
            self.username = self.email.split('@')[0]

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
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<Character {self.name}>'

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
