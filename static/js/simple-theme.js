// Simple theme switching - guaranteed to work
console.log('🎨 Simple Theme Switcher Loaded');

document.addEventListener('DOMContentLoaded', function() {
    console.log('📄 DOM Ready - Setting up theme switcher');
    
    // Get all theme buttons
    const themeButtons = document.querySelectorAll('.theme-btn');
    console.log('🎯 Found theme buttons:', themeButtons.length);
    
    // Apply saved theme on load
    const savedTheme = localStorage.getItem('theme') || 'light';
    console.log('💾 Saved theme:', savedTheme);
    applyTheme(savedTheme);
    
    // Add click listeners to theme buttons
    themeButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            const theme = this.getAttribute('data-theme');
            console.log('🖱️ Theme button clicked:', theme);
            
            // Apply theme
            applyTheme(theme);
            
            // Save to localStorage
            localStorage.setItem('theme', theme);
            
            console.log('✅ Theme applied and saved:', theme);
        });
    });
    
    function applyTheme(theme) {
        // Set data-theme attribute
        document.documentElement.setAttribute('data-theme', theme);
        
        // Update active button
        themeButtons.forEach(btn => {
            btn.classList.remove('active');
            if (btn.getAttribute('data-theme') === theme) {
                btn.classList.add('active');
            }
        });
        
        console.log('🎨 Theme applied:', theme);
        console.log('HTML attribute:', document.documentElement.getAttribute('data-theme'));
        
        // Force a repaint to ensure theme applies
        document.body.style.display = 'none';
        document.body.offsetHeight; // Force reflow
        document.body.style.display = '';
    }
    
    // Keyboard shortcut: Ctrl+T
    document.addEventListener('keydown', function(e) {
        if ((e.ctrlKey || e.metaKey) && e.key === 't') {
            e.preventDefault();
            const themes = ['light', 'dark', 'high-contrast'];
            const currentTheme = document.documentElement.getAttribute('data-theme') || 'light';
            const currentIndex = themes.indexOf(currentTheme);
            const nextTheme = themes[(currentIndex + 1) % themes.length];
            
            console.log('⌨️ Keyboard shortcut - Next theme:', nextTheme);
            applyTheme(nextTheme);
            localStorage.setItem('theme', nextTheme);
        }
    });
    
    console.log('🎉 Theme switcher ready!');
    console.log('💡 Try clicking theme buttons or press Ctrl+T');
});
