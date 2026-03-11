from flask import Blueprint, render_template, request, redirect, url_for, flash
from app import db
from app.models import User, Role
from datetime import datetime

auth = Blueprint('auth', __name__)

@auth.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        password_confirm = request.form.get('password_confirm')
        
        # Validation
        if not email or not password or not password_confirm:
            flash('All fields are required', 'error')
            return render_template('auth/register.html')
        
        if password != password_confirm:
            flash('Passwords do not match', 'error')
            return render_template('auth/register.html')
        
        if len(password) < 8:
            flash('Password must be at least 8 characters long', 'error')
            return render_template('auth/register.html')
        
        # Check if user already exists
        if User.query.filter_by(email=email).first():
            flash('Email already registered', 'error')
            return render_template('auth/register.html')
        
        try:
            # Get Flask-Security datastore
            from flask import current_app
            user_datastore = current_app.extensions['security'].datastore
            
            # Create user
            user = user_datastore.create_user(
                email=email,
                username=email.split('@')[0],
                password=password,
                active=True,
                confirmed_at=datetime.utcnow()
            )
            
            # Add user role
            user_role = Role.query.filter_by(name='user').first()
            if not user_role:
                user_role = Role(name='user', description='Regular user')
                db.session.add(user_role)
                db.session.commit()
            
            user_datastore.add_role_to_user(user, user_role)
            db.session.commit()
            
            flash('Account created successfully! Please log in.', 'success')
            return redirect(url_for('security.login'))
            
        except Exception as e:
            db.session.rollback()
            flash(f'Error creating account: {str(e)}', 'error')
            return render_template('auth/register.html')
    
    return render_template('auth/register.html')
