from app import db
from datetime import datetime

class Screenplay(db.Model):
    __tablename__ = 'screenplays'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    author = db.Column(db.String(100))
    content = db.Column(db.Text, nullable=False, default='')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    scenes = db.relationship('Scene', backref='screenplay', lazy=True, cascade='all, delete-orphan')
    characters = db.relationship('Character', backref='screenplay', lazy=True, cascade='all, delete-orphan')
    
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
