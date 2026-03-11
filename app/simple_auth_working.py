from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_security import login_required, current_user
from app import db
from app.models import User, Role
from werkzeug.security import generate_password_hash
from datetime import datetime

simple_auth = Blueprint('simple_auth', __name__)

@simple_auth.route('/register-test')
def register_test():
    return "Registration route is working!"

@simple_auth.route('/minimal-test')
def minimal_test():
    return render_template('minimal_test.html')

@simple_auth.route('/check-users')
def check_users():
    users = User.query.all()
    user_list = []
    for user in users:
        user_list.append({
            'email': user.email,
            'username': user.username,
            'active': user.active,
            'confirmed_at': str(user.confirmed_at) if user.confirmed_at else None
        })
    return f"Users in database: {len(user_list)}<br>" + "<br>".join([f"Email: {u['email']}, Username: {u['username']}, Active: {u['active']}" for u in user_list])

@simple_auth.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        # Check if this is the registration submit
        if not request.form.get('register_submit'):
            flash('Please use the "Register New User" button to submit the form', 'error')
            return render_template('isolated_register.html')
        
        email = request.form.get('email')
        password = request.form.get('password')
        
        flash(f"Debug: Registration attempt - Email: {email}, Password length: {len(password) if password else 0}", 'info')
        flash(f"Debug: Form data: {dict(request.form)}", 'info')
        
        if not email or not password:
            flash('Please fill in all fields', 'error')
            return render_template('isolated_register.html')
        
        if len(password) < 8:
            flash(f'Password must be at least 8 characters long (got {len(password)})', 'error')
            return render_template('isolated_register.html')
        
        # Check if user exists
        existing_user = User.query.filter_by(email=email).first()
        if existing_user:
            flash(f'Email already exists: {existing_user.email}', 'error')
            return render_template('isolated_register.html')
        
        try:
            flash("Debug: Attempting to create user manually...", 'info')
            
            # Create user manually without Flask-Security
            user = User(
                email=email,
                username=email.split('@')[0],
                password=generate_password_hash(password),  # Hash manually
                active=True,
                confirmed_at=datetime.utcnow()
            )
            
            flash("Debug: User object created", 'info')
            
            # Add user role
            user_role = Role.query.filter_by(name='user').first()
            if not user_role:
                user_role = Role(name='user', description='Regular user')
                db.session.add(user_role)
                db.session.commit()
                flash("Debug: User role created", 'info')
            
            user.roles.append(user_role)
            db.session.add(user)
            db.session.commit()
            flash("Debug: User saved to database", 'info')
            
            flash('Account created successfully! Please log in.', 'success')
            return redirect(url_for('security.login'))
            
        except Exception as e:
            flash(f'Debug: Error creating user: {str(e)}', 'error')
            import traceback
            flash(f'Debug: Full error: {traceback.format_exc()}', 'error')
            db.session.rollback()
            flash(f'Error creating account: {str(e)}', 'error')
            return render_template('isolated_register.html')
    
    return render_template('isolated_register.html')
