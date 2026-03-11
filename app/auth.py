from flask import Blueprint, render_template, request, redirect, url_for, flash, current_app
from flask_login import login_user, logout_user, login_required, current_user
from flask_principal import Identity, identity_changed
from app import db
from app.models import User, Role
from datetime import datetime

auth = Blueprint('auth', __name__)

@auth.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        remember = bool(request.form.get('remember'))
        
        # Validation
        if not email or not password:
            flash('Email and password are required', 'error')
            return render_template('auth/login.html')
        
        # Find user
        user = User.query.filter_by(email=email).first()
        
        # Check credentials
        if user and user.check_password(password) and user.active:
            # Log in user
            login_user(user, remember=remember)
            user.last_login = datetime.utcnow()
            db.session.commit()
            
            # Signal identity change for Flask-Principal
            identity_changed.send(current_app._get_current_object(), identity=Identity(user.id))
            
            # Get next page or redirect to home
            next_page = request.args.get('next')
            if next_page and next_page.startswith('/'):
                return redirect(next_page)
            return redirect(url_for('main.index'))
        else:
            flash('Invalid email or password', 'error')
    
    return render_template('auth/login.html')

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
        
        # Check if username already exists (if provided)
        username = email.split('@')[0]  # Auto-generate from email
        if User.query.filter_by(username=username).first():
            username = f"{username}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        try:
            # Create user
            user = User(
                email=email,
                username=username,
                active=True,
                confirmed_at=datetime.utcnow()
            )
            user.set_password(password)
            
            # Add user role
            user_role = Role.query.filter_by(name='user').first()
            if not user_role:
                user_role = Role(name='user', description='Regular user')
                db.session.add(user_role)
                db.session.commit()
            
            user.roles.append(user_role)
            db.session.add(user)
            db.session.commit()
            
            flash('Account created successfully! Please log in.', 'success')
            return redirect(url_for('auth.login'))
            
        except Exception as e:
            db.session.rollback()
            flash(f'Error creating account: {str(e)}', 'error')
            return render_template('auth/register.html')
    
    return render_template('auth/register.html')

@auth.route('/logout')
@login_required
def logout():
    # Signal identity change for Flask-Principal
    identity_changed.send(current_app._get_current_object(), identity=Identity(None))
    logout_user()
    flash('You have been logged out.', 'info')
    return redirect(url_for('main.index'))

@auth.route('/profile')
@login_required
def profile():
    return render_template('auth/profile.html')
