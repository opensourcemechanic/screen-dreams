# Flask Debugging Guide

## Current Debug Configuration

The application currently runs with `debug=True` in `run.py`:

```python
app.run(debug=True, host='0.0.0.0', port=5000)
```

## What Flask Debug Mode Does

### **Enabled Features (debug=True):**
1. **Auto-reloading** - Server restarts when code changes
2. **Detailed error pages** - Stack traces and interactive debugger
3. **Console logging** - Detailed request/response information
4. **Werkzeug debugger** - Interactive error debugging
5. **Security warnings** - Development-specific alerts

### **Performance Impact of Debug Mode:**

| Feature | Performance Impact | Description |
|---------|-------------------|-------------|
| **Auto-reloading** | **High** | Monitors file changes, restarts server |
| **Error handling** | **Medium** | Generates detailed error pages |
| **Logging** | **Low-Medium** | Extra console output |
| **Debugger** | **Medium** | Interactive debugging tools |

## How to Use the Debugger

### **1. Interactive Error Pages**
When an error occurs with debug=True:
- **Browser shows detailed error page**
- **Stack trace** with file paths and line numbers
- **Local variables** inspection
- **Interactive console** at the bottom

### **2. Using the Interactive Console**
```python
# In the browser debugger console, you can:
>>> request.method
'GET'
>>> current_user.email
'demo@example.com'
>>> app.config['SECRET_KEY']
'dev-secret-key-change-in-production'
```

### **3. Breakpoint Debugging**
Add breakpoints in your code:
```python
from werkzeug.debug import DebuggedApplication

# In your views
@main.route('/test')
def test_route():
    # Breakpoint - execution stops here in browser
    assert False, "Debug breakpoint"
    return "Hello"
```

## Performance Comparison

### **With Debug Mode (Current):**
- **Startup time**: ~2-3 seconds
- **Memory usage**: ~50-80MB higher
- **Response time**: ~10-50ms slower per request
- **CPU usage**: Higher due to file monitoring

### **Without Debug Mode (Production):**
- **Startup time**: ~1 second
- **Memory usage**: Lower baseline
- **Response time**: Faster
- **CPU usage**: Lower

## When to Use Debug Mode

### **✅ Use Debug Mode For:**
- **Development** - Active coding and testing
- **Bug hunting** - Investigating issues
- **Learning** - Understanding request flow
- **API testing** - Checking responses

### **❌ Turn Off Debug Mode For:**
- **Production deployment** - Security risk
- **Performance testing** - Accurate measurements
- **Long-running processes** - Memory efficiency
- **User acceptance testing** - Realistic behavior

## How to Disable Debug Mode

### **Option 1: Quick Toggle**
```python
# In run.py
app.run(debug=False, host='0.0.0.0', port=5000)
```

### **Option 2: Environment Variable**
```python
# In run.py
import os
debug_mode = os.environ.get('FLASK_DEBUG', 'True').lower() == 'true'
app.run(debug=debug_mode, host='0.0.0.0', port=5000)

# Set via environment:
# export FLASK_DEBUG=False
# python run.py
```

### **Option 3: Production Configuration**
Create `run_production.py`:
```python
from app import create_app
import os

app = create_app()

if __name__ == '__main__':
    os.makedirs('screenplays', exist_ok=True)
    
    # Production settings
    app.run(
        debug=False,
        host='0.0.0.0', 
        port=5000,
        threaded=True
    )
```

## Debug Mode Alternatives

### **1. Logging Instead of Debug**
```python
import logging

# In app/__init__.py
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@main.route('/test')
def test_route():
    logger.info(f"Request to /test from {request.remote_addr}")
    return "Hello"
```

### **2. Flask-DebugToolbar**
```bash
pip install flask-debugtoolbar
```

```python
# In app/__init__.py
from flask_debugtoolbar import DebugToolbarExtension

if app.debug:
    toolbar = DebugToolbarExtension(app)
```

### **3. Print Debugging**
```python
@main.route('/test')
def test_route():
    print(f"DEBUG: User {current_user.id} accessing /test")
    print(f"DEBUG: Form data: {request.form}")
    return "Hello"
```

## Performance Testing

### **Benchmark with Debug On:**
```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Test with debug=True
ab -n 100 -c 10 http://127.0.0.1:5000/
```

### **Benchmark with Debug Off:**
```bash
# Stop server, restart with debug=False
# Then test again
ab -n 100 -c 10 http://127.0.0.1:5000/
```

## Security Considerations

### **Debug Mode Security Risks:**
- **Interactive console** - Execute arbitrary code
- **Stack traces** - Expose file paths and code
- **Configuration details** - Show secrets and settings
- **Request inspection** - Access to sensitive data

### **Never Use Debug Mode In Production Because:**
- Attackers can execute code through the debugger
- Sensitive information is exposed
- Performance is degraded
- It's a major security vulnerability

## Recommended Workflow

### **Development (Debug On):**
```bash
# Use debug mode for active development
python run.py  # debug=True
```

### **Testing (Debug Off):**
```bash
# Disable debug for realistic testing
export FLASK_DEBUG=False
python run.py
```

### **Production (Never Debug):**
```bash
# Use production server
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

## Current Application Status

Your application currently runs with debug mode enabled, which is perfect for development but would be slow and insecure for production.

**For development**: Keep debug=True
**For performance testing**: Set debug=False  
**For production**: Never use debug=True

## Quick Commands

```bash
# Check current debug status
curl http://127.0.0.1:5000/  # Look for debug toolbar

# Run without debug
python -c "
from app import create_app
app = create_app()
app.run(debug=False, host='0.0.0.0', port=5000)
"

# Check performance difference
time curl http://127.0.0.1:5000/  # With debug
# vs
time curl http://127.0.0.1:5000/  # Without debug
```
