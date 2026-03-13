// Enhanced UI with theme switching and keyboard shortcuts

class EnhancedUI {
    constructor() {
        this.currentTheme = localStorage.getItem('theme') || 'light';
        this.shortcutsPanel = document.getElementById('shortcuts-panel');
        this.shortcutsVisible = false;
        
        this.init();
    }
    
    init() {
        this.setupThemeSwitcher();
        this.setupKeyboardShortcuts();
        this.applyTheme(this.currentTheme);
        this.setupAccessibility();
    }
    
    setupThemeSwitcher() {
        const themeButtons = document.querySelectorAll('.theme-btn');
        
        themeButtons.forEach(button => {
            button.addEventListener('click', () => {
                const theme = button.dataset.theme;
                this.switchTheme(theme);
            });
        });
    }
    
    switchTheme(theme) {
        this.currentTheme = theme;
        this.applyTheme(theme);
        localStorage.setItem('theme', theme);
        
        // Update active button
        document.querySelectorAll('.theme-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.theme === theme);
        });
        
        // Announce theme change for screen readers
        this.announceToScreenReader(`Theme changed to ${theme}`);
    }
    
    applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
    }
    
    setupKeyboardShortcuts() {
        document.addEventListener('keydown', (e) => {
            // Only trigger shortcuts when not typing in input fields
            if (this.isInputElement(e.target)) return;
            
            const ctrlKey = e.ctrlKey || e.metaKey;
            
            // Ctrl + T: Toggle theme
            if (ctrlKey && e.key === 't') {
                e.preventDefault();
                this.toggleTheme();
            }
            
            // Ctrl + ?: Show/hide shortcuts
            if (ctrlKey && e.key === '?') {
                e.preventDefault();
                this.toggleShortcutsPanel();
            }
            
            // Ctrl + N: New screenplay
            if (ctrlKey && e.key === 'n') {
                e.preventDefault();
                this.createNewScreenplay();
            }
            
            // Ctrl + S: Save
            if (ctrlKey && e.key === 's') {
                e.preventDefault();
                this.saveCurrentWork();
            }
            
            // Ctrl + E: Focus editor
            if (ctrlKey && e.key === 'e') {
                e.preventDefault();
                this.focusEditor();
            }
            
            // Ctrl + G: AI suggestion
            if (ctrlKey && e.key === 'g') {
                e.preventDefault();
                this.triggerAISuggestion();
            }
            
            // Escape: Hide shortcuts panel
            if (e.key === 'Escape' && this.shortcutsVisible) {
                this.hideShortcutsPanel();
            }
        });
    }
    
    toggleTheme() {
        const themes = ['light', 'dark', 'high-contrast', 'evening', 'night'];
        const currentIndex = themes.indexOf(this.currentTheme);
        const nextIndex = (currentIndex + 1) % themes.length;
        this.switchTheme(themes[nextIndex]);
    }
    
    toggleShortcutsPanel() {
        this.shortcutsVisible = !this.shortcutsVisible;
        this.shortcutsPanel.classList.toggle('visible', this.shortcutsVisible);
        
        if (this.shortcutsVisible) {
            // Focus first shortcut item for accessibility
            const firstItem = this.shortcutsPanel.querySelector('.shortcut-item');
            if (firstItem) {
                firstItem.focus();
            }
        }
    }
    
    hideShortcutsPanel() {
        this.shortcutsVisible = false;
        this.shortcutsPanel.classList.remove('visible');
    }
    
    createNewScreenplay() {
        // Try to find and click new screenplay button
        const newButton = document.querySelector('[onclick*="newScreenplay"], .btn-primary[href*="new"]');
        if (newButton) {
            newButton.click();
        } else {
            this.announceToScreenReader('New screenplay function not available on this page');
        }
    }
    
    saveCurrentWork() {
        // Try to find and click save button
        const saveButton = document.querySelector('[onclick*="save"], .btn-success[onclick*="save"]');
        if (saveButton) {
            saveButton.click();
        } else {
            // Trigger auto-save if available
            if (window.autoSave) {
                window.autoSave();
                this.announceToScreenReader('Work saved automatically');
            } else {
                this.announceToScreenReader('Save function not available on this page');
            }
        }
    }
    
    focusEditor() {
        // Try to find main editor textarea
        const editor = document.querySelector('#editor, textarea[name="content"], .editor textarea');
        if (editor) {
            editor.focus();
            this.announceToScreenReader('Editor focused');
        } else {
            this.announceToScreenReader('Editor not found on this page');
        }
    }
    
    triggerAISuggestion() {
        // Try to find AI suggestion button
        const aiButton = document.querySelector('[onclick*="getArcSuggestion"], .btn-secondary[onclick*="AI"]');
        if (aiButton) {
            aiButton.click();
        } else {
            this.announceToScreenReader('AI suggestion not available on this page');
        }
    }
    
    setupAccessibility() {
        // Add ARIA live region for announcements
        const liveRegion = document.createElement('div');
        liveRegion.setAttribute('aria-live', 'polite');
        liveRegion.setAttribute('aria-atomic', 'true');
        liveRegion.className = 'sr-only';
        liveRegion.id = 'ui-announcements';
        document.body.appendChild(liveRegion);
        
        // Add focus indicators for better keyboard navigation
        this.addFocusIndicators();
    }
    
    addFocusIndicators() {
        // Ensure all interactive elements are focusable
        const interactiveElements = document.querySelectorAll('button, a, input, textarea, select');
        interactiveElements.forEach(element => {
            if (!element.hasAttribute('tabindex')) {
                element.setAttribute('tabindex', element.tabIndex >= 0 ? element.tabIndex : '0');
            }
        });
    }
    
    announceToScreenReader(message) {
        const liveRegion = document.getElementById('ui-announcements');
        if (liveRegion) {
            liveRegion.textContent = message;
            // Clear after announcement
            setTimeout(() => {
                liveRegion.textContent = '';
            }, 1000);
        }
    }
    
    isInputElement(element) {
        const inputTypes = ['input', 'textarea', 'select'];
        return inputTypes.includes(element.tagName.toLowerCase()) || 
               element.contentEditable === 'true';
    }
}

// AI Suggestions History Manager
class AISuggestionsHistory {
    constructor() {
        this.maxSuggestions = 10;
        this.init();
    }
    
    init() {
        // Override the AI suggestion display to show history
        this.overrideAISuggestionDisplay();
    }
    
    overrideAISuggestionDisplay() {
        // This will be called from character page to show suggestion history
        window.showAISuggestionHistory = (characterId) => {
            this.displaySuggestionHistory(characterId);
        };
    }
    
    displaySuggestionHistory(characterId) {
        const modal = document.getElementById('characterModal');
        if (!modal) return;
        
        // Find or create suggestions history container
        let historyContainer = modal.querySelector('.ai-suggestions-history');
        if (!historyContainer) {
            historyContainer = this.createHistoryContainer();
            
            // Insert after the arc notes textarea
            const arcTextarea = modal.querySelector('#character-arc');
            if (arcTextarea) {
                arcTextarea.parentNode.insertBefore(historyContainer, arcTextarea.nextSibling);
            }
        }
        
        // Load suggestions from localStorage
        const suggestions = this.getSuggestions(characterId);
        this.renderSuggestions(historyContainer, suggestions);
    }
    
    createHistoryContainer() {
        const container = document.createElement('div');
        container.className = 'ai-suggestions-history';
        container.innerHTML = `
            <h4>AI Suggestions History</h4>
            <div class="suggestions-list"></div>
        `;
        return container;
    }
    
    getSuggestions(characterId) {
        const key = `ai_suggestions_${characterId}`;
        const stored = localStorage.getItem(key);
        return stored ? JSON.parse(stored) : [];
    }
    
    saveSuggestion(characterId, suggestion) {
        const key = `ai_suggestions_${characterId}`;
        const suggestions = this.getSuggestions(characterId);
        
        // Add new suggestion at the beginning
        suggestions.unshift({
            text: suggestion,
            timestamp: new Date().toISOString()
        });
        
        // Keep only the most recent suggestions
        if (suggestions.length > this.maxSuggestions) {
            suggestions.splice(this.maxSuggestions);
        }
        
        localStorage.setItem(key, JSON.stringify(suggestions));
    }
    
    renderSuggestions(container, suggestions) {
        const list = container.querySelector('.suggestions-list');
        
        if (suggestions.length === 0) {
            list.innerHTML = '<p>No AI suggestions yet.</p>';
            return;
        }
        
        list.innerHTML = suggestions.map((suggestion, index) => `
            <div class="ai-suggestion-entry">
                <div class="ai-suggestion-timestamp">
                    ${this.formatTimestamp(suggestion.timestamp)}
                </div>
                <div class="ai-suggestion-text">${suggestion.text}</div>
                <div class="ai-actions">
                    <button type="button" onclick="this.acceptSuggestion(${index})" class="btn btn-success btn-sm">Accept</button>
                </div>
            </div>
        `).join('');
        
        // Add accept method to container
        container.acceptSuggestion = (index) => {
            const suggestion = suggestions[index];
            const arcTextarea = document.querySelector('#character-arc');
            if (arcTextarea) {
                arcTextarea.value = suggestion.text;
            }
        };
    }
    
    formatTimestamp(timestamp) {
        const date = new Date(timestamp);
        return date.toLocaleString();
    }
}

// Initialize everything when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    // Initialize enhanced UI
    window.enhancedUI = new EnhancedUI();
    
    // Initialize AI suggestions history
    window.aiHistory = new AISuggestionsHistory();
    
    // Override the original getArcSuggestion to save to history
    if (window.getArcSuggestion) {
        const originalGetArcSuggestion = window.getArcSuggestion;
        window.getArcSuggestion = async function(characterId) {
            // Call original function
            await originalGetArcSuggestion.call(this, characterId);
            
            // Save suggestion to history after a short delay
            setTimeout(() => {
                const suggestionText = document.querySelector('.ai-suggestion p');
                if (suggestionText && suggestionText.textContent) {
                    window.aiHistory.saveSuggestion(characterId, suggestionText.textContent);
                }
            }, 1000);
        };
    }
});

// Export for global access
window.EnhancedUI = EnhancedUI;
window.AISuggestionsHistory = AISuggestionsHistory;
