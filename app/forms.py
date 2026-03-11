from flask_security.forms import RegisterForm
from wtforms import StringField, validators
from app.models import User

class ExtendedRegisterForm(RegisterForm):
    username = StringField('Username', [
        validators.DataRequired(),
        validators.Length(min=3, max=80)
    ])
    
    def validate_username(self, field):
        if User.query.filter_by(username=field.data).first():
            raise validators.ValidationError('Username already exists')
