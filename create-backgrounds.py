#!/usr/bin/env python3
"""
Create placeholder background images for all themes
Run this script to generate basic gradient backgrounds
"""

from PIL import Image, ImageDraw
import os

# Create directories
themes = ['light', 'dark', 'high-contrast', 'evening', 'night']
for theme in themes:
    os.makedirs(f'static/images/themes/{theme}', exist_ok=True)

# Theme colors (RGB)
theme_colors = {
    'light': {
        'body': ((245, 245, 245), (255, 255, 255)),  # Light gray to white
        'navbar': ((44, 62, 80), (52, 73, 94))  # Dark blue gradient
    },
    'dark': {
        'body': ((26, 26, 26), (45, 45, 45)),  # Dark gray gradient
        'navbar': ((13, 17, 23), (20, 25, 35))  # Darker blue
    },
    'high-contrast': {
        'body': ((0, 0, 0), (32, 32, 32)),  # Black to dark gray
        'navbar': ((0, 0, 0), (64, 64, 64))  # Black to gray
    },
    'evening': {
        'body': ((44, 24, 16), (61, 36, 26)),  # Warm brown gradient
        'navbar': ((26, 14, 8), (40, 20, 12))  # Darker brown
    },
    'night': {
        'body': ((10, 10, 10), (26, 26, 46)),  # Dark blue-black
        'navbar': ((15, 15, 35), (25, 25, 55))  # Darker blue
    }
}

def create_gradient_image(width, height, color1, color2, direction='vertical'):
    """Create a gradient image"""
    image = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(image)
    
    if direction == 'vertical':
        for y in range(height):
            # Calculate gradient
            ratio = y / height
            r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
            g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
            b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
            draw.line([(0, y), (width, y)], fill=(r, g, b))
    else:  # horizontal
        for x in range(width):
            ratio = x / width
            r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
            g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
            b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
            draw.line([(x, 0), (x, height)], fill=(r, g, b))
    
    return image

def create_theme_images():
    """Create background images for all themes"""
    for theme, colors in theme_colors.items():
        # Body background (1920x1080)
        body_img = create_gradient_image(1920, 1080, colors['body'][0], colors['body'][1])
        body_img.save(f'static/images/themes/{theme}/body-bg.webp', 'WEBP', quality=95)
        body_img.save(f'static/images/themes/{theme}/body-bg.jpg', 'JPEG', quality=90)
        
        # Navbar background (1920x200)
        navbar_img = create_gradient_image(1920, 200, colors['navbar'][0], colors['navbar'][1])
        navbar_img.save(f'static/images/themes/{theme}/navbar-bg.webp', 'WEBP', quality=95)
        navbar_img.save(f'static/images/themes/{theme}/navbar-bg.jpg', 'JPEG', quality=90)
        
        print(f"Created {theme} theme backgrounds (WebP + JPG)")

if __name__ == "__main__":
    create_theme_images()
    print("\nAll theme backgrounds created!")
    print("You can replace these with your own images:")
    print("- Body backgrounds: 1920x1080px")
    print("- Navbar backgrounds: 1920x200px")
    print("- Format: WebP (recommended) or JPG")
    print("- Keep file sizes under 500KB each")
