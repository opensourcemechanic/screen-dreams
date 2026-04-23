# Documentation Images

This directory contains images for the Screen Dreams documentation.

## Image Guidelines

### File Naming
- Use descriptive names (e.g., `editor-interface.png`, `character-management.png`)
- Use lowercase with hyphens
- Include image type in filename

### Image Specifications
- **Size**: 1200x800px for desktop, 800x600px for mobile
- **Format**: PNG or WebP (WebP recommended for better compression)
- **Quality**: High quality but optimized for web
- **Content**: Show key features and UI elements

### Required Images

#### Screenshots to Create
1. **app-homepage.png** - Main application homepage
2. **editor-interface.png** - Screenplay editor with Fountain syntax
3. **character-management.png** - Character list and detail view
4. **ai-assistant.png** - AI panel with suggestions
5. **pdf-export.png** - PDF export preview
6. **mobile-horizontal.png** - Mobile in horizontal orientation
7. **mobile-vertical.png** - Mobile in vertical orientation

### Adding Images

1. Take screenshots of the application
2. Optimize for web (compress without losing quality)
3. Save to this directory
4. Update references in documentation files

### Image Optimization

Use tools like:
- ImageOptim (Mac)
- Squoosh (Web)
- TinyPNG (Web)

### Current Images

- *[Add your screenshots here]*

## Usage

Images are referenced in documentation like this:

```markdown
![Description]({{ '/assets/images/filename.png' | relative_url }})
```

## License

All images should be appropriate for open source documentation and not contain any sensitive information.
