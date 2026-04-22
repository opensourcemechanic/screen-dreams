# Screen Dreams - UVX Quick Start

## **Easiest Local Deployment Method**

Deploy Screen Dreams on your local machine with a single command using UVX - no installation, no configuration, just run and go!

---

## **What is UVX?**

UVX is a modern Python application runner that:
- Downloads applications directly from GitHub
- Creates isolated virtual environments automatically
- Installs all dependencies
- Runs the application locally
- **Result**: Screen Dreams running on your computer in seconds

---

## **Prerequisites**

### **System Requirements**
- **Python 3.8+** (recommended 3.9+)
- **2GB+ RAM** minimum
- **1GB+ disk space**
- **Windows, macOS, or Linux**

### **Install UV (one-time setup)**
```bash
# Install UV (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or with pip (if curl doesn't work)
pip install uv

# Restart your terminal after installation
```

---

## **Quick Start - One Command Deployment**

### **Method 1: Direct from GitHub (Recommended)**
```bash
# Deploy Screen Dreams instantly
uvx git+https://github.com/opensourcemechanic/screen-dreams.git

# The application will automatically:
# 1. Download from GitHub
# 2. Create virtual environment
# 3. Install dependencies  
# 4. Start the application
# 5. Open in your browser
```

### **Method 2: With AI Features**
```bash
# Deploy with AI capabilities enabled
uvx git+https://github.com/opensourcemechanic/screen-dreams.git[ai]
```

### **Method 3: Custom Configuration**
```bash
# Deploy with custom settings
uvx git+https://github.com/opensourcemechanic/screen-dreams.git -- --host=0.0.0.0 --port=8080
```

---

## **Access Your Local Instance**

### **Web Interface**
Once deployed, access Screen Dreams at:
- **Primary**: http://localhost:5000
- **Alternative**: http://127.0.0.1:5000

### **What You Get**
- **Complete web interface** - Full-featured screenwriting application
- **Local data storage** - All files saved on your computer
- **AI assistance** - If configured (see AI setup below)
- **Privacy** - No data leaves your machine
- **Offline capability** - Works without internet (except AI features)

---

## **AI Features Setup (Optional)**

### **Option 1: Use Ollama (Recommended for Privacy)**
```bash
# Install Ollama first (one-time)
curl -fsSL https://ollama.ai/install.sh | sh

# Pull a model
ollama pull tinyllama

# Deploy Screen Dreams with Ollama
uvx --env AI_PROVIDER=ollama git+https://github.com/opensourcemechanic/screen-dreams.git
```

### **Option 2: Use OpenAI**
```bash
# Set your OpenAI API key
export OPENAI_API_KEY="your-openai-api-key-here"

# Deploy with OpenAI
uvx --env AI_PROVIDER=openai --env OPENAI_API_KEY=$OPENAI_API_KEY git+https://github.com/opensourcemechanic/screen-dreams.git
```

### **Option 3: Use Anthropic Claude**
```bash
# Set your Anthropic API key
export ANTHROPIC_API_KEY="your-anthropic-api-key-here"

# Deploy with Claude
uvx --env AI_PROVIDER=anthropic --env ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY git+https://github.com/opensourcemechanic/screen-dreams.git
```

---

## **Configuration Options**

### **Environment Variables**
```bash
# Set AI provider
uvx --env AI_PROVIDER=ollama git+https://github.com/opensourcemechanic/screen-dreams.git

# Set custom port
uvx --env PORT=8080 git+https://github.com/opensourcemechanic/screen-dreams.git

# Set database location
uvx --env DATABASE_URL=sqlite:///my-screenplays.db git+https://github.com/opensourcemechanic/screen-dreams.git

# Multiple settings
uvx --env AI_PROVIDER=ollama --env PORT=8080 --env FLASK_ENV=production git+https://github.com/opensourcemechanic/screen-dreams.git
```

### **Command Line Arguments**
```bash
# Custom host and port
uvx git+https://github.com/opensourcemechanic/screen-dreams.git -- --host=0.0.0.0 --port=8080

# Debug mode
uvx git+https://github.com/opensourcemechanic/screen-dreams.git -- --debug

# Production mode
uvx git+https://github.com/opensourcemechanic/screen-dreams.git -- --no-debug
```

---

## **Data and Storage**

### **Where Your Data is Stored**
All data is stored locally in the current directory:
```
screen-dreams/
  uploads/           # User uploaded files
  screenplays/       # Generated screenplays
  logs/             # Application logs
  screenwriter.db   # SQLite database (user accounts, projects)
```

### **Backup Your Data**
```bash
# Create a backup of all your work
tar -czf screen-dreams-backup-$(date +%Y%m%d).tar.gz uploads/ screenplays/ screenwriter.db

# Restore from backup
tar -xzf screen-dreams-backup-YYYYMMDD.tar.gz
```

---

## **Troubleshooting**

### **Common Issues**

#### **"command not found: uvx"**
```bash
# Install UV first
curl -LsSf https://astral.sh/uv/install.sh | sh
# Restart terminal and try again
```

#### **"Python version not supported"**
```bash
# Check your Python version
python --version

# Install newer Python or specify version
uvx --python 3.11 git+https://github.com/opensourcemechanic/screen-dreams.git
```

#### **"Port already in use"**
```bash
# Use a different port
uvx git+https://github.com/opensourcemechanic/screen-dreams.git -- --port=8080
```

#### **"Permission denied"**
```bash
# On Linux/macOS, ensure proper permissions
chmod +x ~/.local/bin/uvx

# Or use with sudo (not recommended)
sudo uvx git+https://github.com/opensourcemechanic/screen-dreams.git
```

#### **"AI features not working"**
```bash
# Check AI provider configuration
uvx --env AI_PROVIDER=ollama git+https://github.com/opensourcemechanic/screen-dreams.git

# Ensure Ollama is running (if using Ollama)
ollama serve
```

### **Get Help**
```bash
# Check UVX logs
uvx --verbose git+https://github.com/opensourcemechanic/screen-dreams.git

# Check application logs
# Look for logs in the terminal output
```

---

## **Advanced Usage**

### **Run in Background**
```bash
# Run in background (Linux/macOS)
nohup uvx git+https://github.com/opensourcemechanic/screen-dreams.git > screen-dreams.log 2>&1 &

# Run in background (Windows PowerShell)
Start-Process -WindowStyle Hidden uvx -ArgumentList "git+https://github.com/opensourcemechanic/screen-dreams.git"
```

### **Auto-start on Boot**
```bash
# Create systemd service (Linux)
cat > ~/.config/systemd/user/screen-dreams.service << 'EOF'
[Unit]
Description=Screen Dreams Screenwriting App
After=network.target

[Service]
Type=simple
ExecStart=uvx git+https://github.com/opensourcemechanic/screen-dreams.git
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

# Enable auto-start
systemctl --user enable screen-dreams.service
systemctl --user start screen-dreams.service
```

### **Network Access**
```bash
# Allow access from other devices on your network
uvx git+https://github.com/opensourcemechanic/screen-dreams.git -- --host=0.0.0.0

# Then access from other devices:
# http://[your-computer-ip]:5000
```

---

## **Updates and Maintenance**

### **Update to Latest Version**
```bash
# Get the latest version from GitHub
uvx --refresh git+https://github.com/opensourcemechanic/screen-dreams.git
```

### **Clear Cache (if needed)**
```bash
# Clear UVX cache and reinstall
uvx --clear git+https://github.com/opensourcemechanic/screen-dreams.git
```

### **Uninstall**
```bash
# Remove the UVX installation (doesn't delete your data)
uvx uninstall git+https://github.com/opensourcemechanic/screen-dreams.git

# Your data in uploads/, screenplays/, and screenwriter.db remains
```

---

## **Why Choose UVX?**

### **Advantages**
- **Zero installation** - No git clone, no virtual environment setup
- **Isolated** - Won't conflict with other Python projects
- **Automatic** - Handles all dependencies and configuration
- **Cross-platform** - Works the same on Windows, Mac, Linux
- **Private** - All data stays on your machine
- **Fast** - Starts in seconds, not minutes
- **Up-to-date** - Always gets the latest version

### **Perfect For**
- **Writers** who want a simple, private screenwriting tool
- **Developers** testing the application
- **Users** who want to try before committing to a full installation
- **Offline work** when you need screenwriting tools without internet
- **Privacy-conscious** users who want local data storage

---

## **Next Steps**

1. **Install UV** (one-time setup)
2. **Run the command** to deploy
3. **Open your browser** to http://localhost:5000
4. **Start writing** your screenplay!

---

**That's it! You now have Screen Dreams running locally on your machine with full AI capabilities and complete privacy.** 

For more advanced configuration, see the [main documentation](DEPLOYMENT.md) or visit the [GitHub repository](https://github.com/opensourcemechanic/screen-dreams).
