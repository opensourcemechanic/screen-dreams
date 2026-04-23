// Global editor utilities

// Check AI status periodically
async function checkAIStatus() {
    try {
        const response = await fetch('/api/ai/status');
        const result = await response.json();
        const statusEl = document.getElementById('ai-status');
        if (statusEl) {
            statusEl.textContent = result.available ? '🤖 AI Ready' : '🤖 AI Offline';
            statusEl.className = result.available ? 'ai-status ai-online' : 'ai-status ai-offline';
        }
    } catch (error) {
        console.error('Error checking AI status:', error);
    }
}

// Initialize AI status check on page load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', checkAIStatus);
} else {
    checkAIStatus();
}

// Check AI status every 30 seconds
setInterval(checkAIStatus, 30000);
