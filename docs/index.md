---
layout: docs
title: Screen Dreams Documentation
description: AI-powered screenwriting application with professional tools
show_downloads: true
---

![Screen Dreams screenwriting editor]({{ '/assets/images/hero.jpg' | relative_url }})

Welcome to the complete documentation for Screen Dreams, the AI-powered screenwriting application.


## Quick Start

Deploy Screen Dreams instantly on your computer with UVX:

```bash
# Install UV (one-time setup)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Deploy Screen Dreams instantly
uvx git+https://github.com/opensourcemechanic/screen-dreams.git

# Open your browser to http://localhost:5000
```

That's it! Screen Dreams is now running locally on your machine with:
- Complete web interface
- Local data storage (all files saved on your computer)
- AI features (if configured)
- Privacy (no data leaves your machine)

## Why Choose Screen Dreams?

### Professional Screenwriting Tools
- **Fountain Format Support** - Industry-standard screenplay markup
- **Character Management** - Track characters and their development
![Character Management example]({{ '/assets/images/characters.jpg' | relative_url }})

- **Scene Organization** - Automatic scene parsing and organization
![Scene organization example]({{ '/assets/images/scenes.jpg' | relative_url }})

- **PDF Export** - Professional PDFs with proper formatting
![PDF Export example]({{ '/assets/images/pdf_export.jpg' | relative_url }})

### AI-Powered Assistance
- **Multiple AI Providers** - Choose from Ollama, OpenAI, or Anthropic
- **Character Development** - Generate character backstories and motivations
- **Plot Ideas** - Get suggestions for story structure and plot points
- **Dialogue Enhancement** - Improve dialogue flow and character voice

### Mobile-Friendly Design
- **Responsive Interface** - Works perfectly on tablets and mobile devices
- **Touch Controls** - Optimized for touch screen interaction
- **Horizontal Orientation** - Best experience for mobile writing
- **Auto-Save** - Never lose your work with automatic saving

### Beautiful Themes
- **5 Professional Themes** - Light, Dark, High-Contrast, Evening, Night
- **Accessibility** - WCAG compliant with proper contrast ratios
- **Customizable** - Personalize your writing environment

## Installation Options

| Method | Best For | Setup Time | Requirements |
|--------|-----------|------------|-------------|
| **UVX** | Quick start, beginners | 2 minutes | Python 3.8+ |
| **Traditional** | Developers, customization | 10 minutes | Python, Git, Virtual env |
| **Docker/Podman** | Production, isolation | 5 minutes | Docker/Podman |

## Documentation Sections

### [Getting Started]({{ '/docs/getting-started/' | relative_url }})
- UVX installation and deployment
- Traditional installation methods
- First project setup
- AI assistant configuration
- Mobile setup guide

### [Features]({{ '/docs/features/' | relative_url }})
- Screenplay editor features
- Character management
- Export options
- Mobile support
- Themes and customization

### [AI Assistant]({{ '/docs/ai-assistant/' | relative_url }})
- AI provider setup (Ollama, OpenAI, Anthropic)
- Using AI assistance
- Best practices
- Troubleshooting

### [Mobile Guide]({{ '/docs/mobile/' | relative_url }})
- Mobile compatibility
- Recommended setup
- Touch-friendly features
- Performance tips

## Quick Links

- **[GitHub Repository](https://github.com/opensourcemechanic/screen-dreams)** - Source code and issues
- **[UVX Quick Start]({{ '/docs/getting-started/' | relative_url }})** - One-command deployment
- **[AI Setup Guide]({{ '/docs/ai-assistant/' | relative_url }})** - Configure AI assistance
- **[Mobile Guide]({{ '/docs/mobile/' | relative_url }})** - Mobile usage tips

## Community & Support

### Get Help
- **GitHub Issues** - Report bugs and request features
- **Documentation** - Comprehensive guides and tutorials
- **Community** - Connect with other screenwriters

### Contribute
- **Pull Requests** - Contribute code and documentation
- **Issues** - Help solve problems and improve features
- **Discussions** - Share ideas and get feedback

## Technical Details

### Architecture
- **Backend**: Flask with SQLAlchemy
- **Frontend**: Bootstrap 5 with custom CSS
- **Database**: SQLite (default), PostgreSQL (production)
- **AI Integration**: Multiple provider support
- **Deployment**: UVX, Docker, Podman, traditional

### Requirements
- **Python**: 3.8+
- **Memory**: 2GB+ recommended
- **Storage**: 1GB+ for projects and data
- **Network**: Internet connection for AI features

### Security
- **Local Data**: All data stored locally by default
- **Encrypted Sessions**: Secure user authentication
- **Privacy First**: No data sharing without consent
- **Open Source**: MIT License

## License

Screen Dreams is open source under the [MIT License](https://github.com/opensourcemechanic/screen-dreams/blob/main/LICENSE).

---

Ready to start writing? [Get Started Now]({{ '/docs/getting-started/' | relative_url }})
