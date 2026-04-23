// Import/Export functionality with automatic backup system
class ImportExportManager {
    constructor() {
        this.backupInterval = null;
        this.backupFrequency = 5 * 60 * 1000; // 5 minutes (configurable)
        this.currentScreenplayId = null;
        this.autoBackupEnabled = true;
        this.saveCount = 0;
        this.backupCount = 0;
        
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.loadBackupSettings();
        this.setupAutoBackup();
    }
    
    setupEventListeners() {
        // Export buttons
        document.addEventListener('click', (e) => {
            if (e.target.matches('[data-export]')) {
                const format = e.target.dataset.export;
                const screenplayId = e.target.dataset.screenplayId;
                this.exportScreenplay(screenplayId, format);
            }
            
            if (e.target.matches('[data-import]')) {
                this.showImportDialog();
            }
            
            if (e.target.matches('[data-backup]')) {
                const screenplayId = e.target.dataset.screenplayId;
                this.createBackupWithFeedback(screenplayId);
            }
            
            if (e.target.matches('[data-restore]')) {
                this.showRestoreDialog();
            }
        });
        
        // File input for import
        document.addEventListener('change', (e) => {
            if (e.target.matches('#import-file-input')) {
                this.handleFileImport(e.target.files[0]);
            }
        });
        
        // Override the save function to add feedback
        if (window.saveScreenplay) {
            const originalSave = window.saveScreenplay;
            window.saveScreenplay = async function() {
                await importExportManager.saveScreenplayWithFeedback();
            };
        }
    }
    
    // Export functionality
    async exportScreenplay(screenplayId, format) {
        try {
            this.showProgress('Exporting screenplay...');
            
            const response = await fetch(`/api/screenplay/${screenplayId}/export/${format}`);
            
            if (!response.ok) {
                throw new Error('Export failed');
            }
            
            // Get filename from headers or create one
            const contentDisposition = response.headers.get('content-disposition');
            let filename = `screenplay.${this.getFileExtension(format)}`;
            
            if (contentDisposition) {
                const filenameMatch = contentDisposition.match(/filename="?([^"]+)"?/);
                if (filenameMatch) {
                    filename = filenameMatch[1];
                }
            }
            
            // Download the file
            const blob = await response.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = filename;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);
            
            this.hideProgress();
            this.showNotification('Screenplay exported successfully!', 'success');
            
        } catch (error) {
            this.hideProgress();
            this.showNotification('Export failed: ' + error.message, 'error');
        }
    }
    
    getFileExtension(format) {
        const extensions = {
            'fountain': 'fountain',
            'plain_text': 'txt',
            'final_draft': 'fdx',
            'backup': 'json'
        };
        return extensions[format] || 'txt';
    }
    
    // Import functionality
    showImportDialog() {
        const modal = this.createImportModal();
        document.body.appendChild(modal);
        modal.style.display = 'flex';
    }
    
    createImportModal() {
        const modal = document.createElement('div');
        modal.className = 'modal';
        modal.innerHTML = `
            <div class="modal-content">
                <h2>Import Screenplay</h2>
                <div class="import-form">
                    <div class="form-group">
                        <label for="import-title">Screenplay Title:</label>
                        <input type="text" id="import-title" placeholder="Enter title (optional)">
                    </div>
                    <div class="form-group">
                        <label for="import-format">Format:</label>
                        <select id="import-format">
                            <option value="auto">Auto-detect</option>
                            <option value="fountain">Fountain (.fountain)</option>
                            <option value="plain_text">Plain Text (.txt)</option>
                            <option value="final_draft">Final Draft (.fdx)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="import-file-input">Choose File:</label>
                        <input type="file" id="import-file-input" accept=".fountain,.txt,.fdx,.json">
                    </div>
                    <div class="form-actions">
                        <button type="button" id="import-confirm" class="btn btn-primary">Import</button>
                        <button type="button" id="import-cancel" class="btn btn-secondary">Cancel</button>
                    </div>
                </div>
            </div>
        `;
        
        // Add event listeners
        modal.querySelector('#import-cancel').addEventListener('click', () => {
            document.body.removeChild(modal);
        });
        
        modal.querySelector('#import-confirm').addEventListener('click', () => {
            const fileInput = modal.querySelector('#import-file-input');
            const title = modal.querySelector('#import-title').value;
            const format = modal.querySelector('#import-format').value;
            
            if (fileInput.files.length > 0) {
                this.handleFileImport(fileInput.files[0], title, format);
                document.body.removeChild(modal);
            } else {
                this.showNotification('Please select a file', 'error');
            }
        });
        
        return modal;
    }
    
    async handleFileImport(file, title = '', format = 'auto') {
        try {
            this.showProgress('Importing screenplay...');
            
            const formData = new FormData();
            formData.append('file', file);
            formData.append('title', title);
            formData.append('format', format);
            
            const response = await fetch('/api/screenplay/import', {
                method: 'POST',
                body: formData
            });
            
            const result = await response.json();
            
            if (!response.ok) {
                throw new Error(result.error || 'Import failed');
            }
            
            this.hideProgress();
            this.showNotification('Screenplay imported successfully!', 'success');
            
            // Redirect to the imported screenplay
            if (result.screenplay && result.screenplay.id) {
                window.location.href = `/screenplay/${result.screenplay.id}`;
            }
            
        } catch (error) {
            this.hideProgress();
            this.showNotification('Import failed: ' + error.message, 'error');
        }
    }
    
    // Backup functionality
    setupAutoBackup() {
        if (!this.autoBackupEnabled) return;
        
        // Clear existing interval
        if (this.backupInterval) {
            clearInterval(this.backupInterval);
        }
        
        // Set up new interval
        this.backupInterval = setInterval(() => {
            if (this.currentScreenplayId) {
                this.createAutoBackup(this.currentScreenplayId);
            }
        }, this.backupFrequency);
        
        console.log(`Auto backup enabled: every ${this.backupFrequency / 60000} minutes`);
    }
    
    async createBackup(screenplayId) {
        try {
            const response = await fetch(`/api/screenplay/${screenplayId}/backup`, {
                method: 'POST'
            });
            
            const result = await response.json();
            
            if (!response.ok) {
                throw new Error(result.error || 'Backup failed');
            }
            
            // Check if content has changed since last backup
            const backupKey = `screenplay_backup_${screenplayId}`;
            const existingBackups = JSON.parse(localStorage.getItem(backupKey) || '[]');
            
            if (existingBackups.length > 0) {
                const lastBackup = existingBackups[0]; // Most recent backup
                if (lastBackup.content_hash === result.content_hash) {
                    // Content hasn't changed, skip backup
                    return { skipped: true, reason: 'No changes' };
                }
            }
            
            // Save backup to localStorage with enhanced metadata
            const backups = JSON.parse(localStorage.getItem(backupKey) || '[]');
            
            // Add version number and timestamp to backup
            const enhancedBackup = {
                ...result.backup,
                backup_number: backups.length + 1,
                timestamp: new Date().toISOString(),
                local_timestamp: new Date().toLocaleString(),
                id: Date.now(),
                version_info: {
                    save_count: this.saveCount,
                    backup_count: this.backupCount + 1
                }
            };
            
            // Add new backup to the beginning
            backups.unshift(enhancedBackup);
            
            // Apply retention policy (configurable)
            const maxBackups = this.getBackupRetentionLimit();
            if (backups.length > maxBackups) {
                backups.splice(maxBackups);
            }
            
            localStorage.setItem(backupKey, JSON.stringify(backups));
            
            console.log('Backup created successfully');
            return { skipped: false, backup: enhancedBackup };
            
        } catch (error) {
            console.error('Auto backup failed:', error);
            throw error; // Re-throw to handle in UI
        }
    }
    
    async createAutoBackup(screenplayId) {
        // Silent backup without notifications
        await this.createBackup(screenplayId);
    }
    
    showRestoreDialog() {
        const modal = this.createRestoreModal();
        document.body.appendChild(modal);
        modal.style.display = 'flex';
        this.loadBackupList(modal);
    }
    
    createRestoreModal() {
        const modal = document.createElement('div');
        modal.className = 'modal';
        modal.innerHTML = `
            <div class="modal-content">
                <h2>Restore from Backup</h2>
                <div class="backup-list">
                    <div id="backup-items">Loading backups...</div>
                </div>
                <div class="form-actions">
                    <button type="button" id="restore-cancel" class="btn btn-secondary">Cancel</button>
                </div>
            </div>
        `;
        
        modal.querySelector('#restore-cancel').addEventListener('click', () => {
            document.body.removeChild(modal);
        });
        
        return modal;
    }
    
    loadBackupList(modal) {
        const backupItems = modal.querySelector('#backup-items');
        const backups = [];
        
        // Load backups from localStorage for all screenplays
        for (let i = 0; i < localStorage.length; i++) {
            const key = localStorage.key(i);
            if (key.startsWith('screenplay_backup_')) {
                const screenplayBackups = JSON.parse(localStorage.getItem(key) || '[]');
                backups.push(...screenplayBackups);
            }
        }
        
        // Sort by timestamp (newest first)
        backups.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
        
        if (backups.length === 0) {
            backupItems.innerHTML = '<p>No backups found.</p>';
            return;
        }
        
        backupItems.innerHTML = backups.map(backup => `
            <div class="backup-item">
                <div class="backup-info">
                    <h4>${backup.title || 'Untitled Screenplay'}</h4>
                    <p class="backup-timestamp">
                        ${backup.local_timestamp || new Date(backup.timestamp).toLocaleString()}
                        ${backup.backup_number ? `• Backup #${backup.backup_number}` : ''}
                    </p>
                    <p class="backup-meta">
                        Characters: ${backup.metadata.character_count} | 
                        Words: ${backup.metadata.word_count} | 
                        Lines: ${backup.metadata.line_count}
                    </p>
                    ${backup.version_info ? `
                        <p class="backup-versions">
                            Save v${backup.version_info.save_count} • 
                            Backup #${backup.version_info.backup_count}
                        </p>
                    ` : ''}
                </div>
                <div class="backup-actions">
                    <button class="btn btn-primary btn-sm" onclick="importExportManager.restoreBackup(${backup.id})">Restore</button>
                    <button class="btn btn-secondary btn-sm" onclick="importExportManager.downloadBackup(${backup.id})">Download</button>
                </div>
            </div>
        `).join('');
        
        // Store backups for restoration
        this.availableBackups = backups;
    }
    
    async restoreBackup(backupId) {
        const backup = this.availableBackups.find(b => b.id === backupId);
        if (!backup) {
            this.showNotification('Backup not found', 'error');
            return;
        }
        
        if (!confirm(`Are you sure you want to restore "${backup.title}"? This will create a new screenplay.`)) {
            return;
        }
        
        try {
            this.showProgress('Restoring screenplay...');
            
            const response = await fetch('/api/screenplay/restore', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ backup: backup })
            });
            
            const result = await response.json();
            
            if (!response.ok) {
                throw new Error(result.error || 'Restore failed');
            }
            
            this.hideProgress();
            this.showNotification('Screenplay restored successfully!', 'success');
            
            // Redirect to the restored screenplay
            if (result.screenplay && result.screenplay.id) {
                window.location.href = `/screenplay/${result.screenplay.id}`;
            }
            
        } catch (error) {
            this.hideProgress();
            this.showNotification('Restore failed: ' + error.message, 'error');
        }
    }
    
    downloadBackup(backupId) {
        const backup = this.availableBackups.find(b => b.id === backupId);
        if (!backup) return;
        
        const blob = new Blob([JSON.stringify(backup, null, 2)], { type: 'application/json' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${backup.title}_backup_${new Date(backup.timestamp).toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
    }
    
    // Settings management
    loadBackupSettings() {
        const settings = JSON.parse(localStorage.getItem('import_export_settings') || '{}');
        this.autoBackupEnabled = settings.autoBackup !== false;
        this.backupFrequency = settings.backupFrequency || 5 * 60 * 1000;
        this.backupRetentionLimit = settings.backupRetentionLimit || 20; // Default to 20 backups
    }
    
    saveBackupSettings() {
        const settings = {
            autoBackup: this.autoBackupEnabled,
            backupFrequency: this.backupFrequency,
            backupRetentionLimit: this.backupRetentionLimit
        };
        localStorage.setItem('import_export_settings', JSON.stringify(settings));
    }
    
    getBackupRetentionLimit() {
        return this.backupRetentionLimit || 20;
    }
    
    setBackupRetentionLimit(limit) {
        this.backupRetentionLimit = parseInt(limit) || 20;
        this.saveBackupSettings();
    }
    
    showBackupSettingsDialog() {
        const modal = document.createElement('div');
        modal.className = 'modal';
        
        // Load saved max prompt length
        const savedMaxPromptLength = localStorage.getItem('maxPromptLength') || '2000';
        
        modal.innerHTML = `
            <div class="modal-content">
                <h2>Settings</h2>
                <div class="backup-settings">
                    <div class="setting-group">
                        <label>
                            <input type="checkbox" id="auto-backup-enabled" ${this.autoBackupEnabled ? 'checked' : ''}>
                            Enable automatic backups
                        </label>
                    </div>
                    <div class="setting-group">
                        <label for="backup-frequency">Backup frequency:</label>
                        <select id="backup-frequency">
                            <option value="300000" ${this.backupFrequency === 300000 ? 'selected' : ''}>5 minutes</option>
                            <option value="600000" ${this.backupFrequency === 600000 ? 'selected' : ''}>10 minutes</option>
                            <option value="1800000" ${this.backupFrequency === 1800000 ? 'selected' : ''}>30 minutes</option>
                            <option value="3600000" ${this.backupFrequency === 3600000 ? 'selected' : ''}>1 hour</option>
                        </select>
                    </div>
                    <div class="setting-group">
                        <label for="backup-retention">Maximum backups to keep:</label>
                        <select id="backup-retention">
                            <option value="10" ${this.backupRetentionLimit === 10 ? 'selected' : ''}>10 backups</option>
                            <option value="20" ${this.backupRetentionLimit === 20 ? 'selected' : ''}>20 backups</option>
                            <option value="50" ${this.backupRetentionLimit === 50 ? 'selected' : ''}>50 backups</option>
                            <option value="100" ${this.backupRetentionLimit === 100 ? 'selected' : ''}>100 backups</option>
                        </select>
                    </div>
                    <div class="setting-group">
                        <label for="max-prompt-length">Maximum prompt length (characters):</label>
                        <input type="number" id="max-prompt-length" min="100" max="10000" step="100" value="${savedMaxPromptLength}">
                        <small>Maximum number of characters to include in AI prompt context</small>
                    </div>
                </div>
                <div class="form-actions">
                    <button type="button" id="settings-save" class="btn btn-primary">Save Settings</button>
                    <button type="button" id="settings-cancel" class="btn btn-secondary">Cancel</button>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        modal.style.display = 'flex';
        
        // Add event listeners
        modal.querySelector('#settings-cancel').addEventListener('click', () => {
            document.body.removeChild(modal);
        });
        
        modal.querySelector('#settings-save').addEventListener('click', () => {
            const enabled = modal.querySelector('#auto-backup-enabled').checked;
            const frequency = parseInt(modal.querySelector('#backup-frequency').value);
            const retention = parseInt(modal.querySelector('#backup-retention').value);
            const maxPromptLength = parseInt(modal.querySelector('#max-prompt-length').value);
            
            this.autoBackupEnabled = enabled;
            this.backupFrequency = frequency;
            this.backupRetentionLimit = retention;
            
            // Save max prompt length to localStorage
            localStorage.setItem('maxPromptLength', maxPromptLength.toString());
            
            this.saveBackupSettings();
            this.setupAutoBackup(); // Restart auto backup with new settings
            
            this.showNotification('Settings saved', 'success');
            document.body.removeChild(modal);
        });
    }
    
    setCurrentScreenplay(screenplayId) {
        this.currentScreenplayId = screenplayId;
    }
    
    // UI helpers
    showProgress(message) {
        this.hideProgress(); // Remove any existing progress
        
        const progress = document.createElement('div');
        progress.id = 'import-export-progress';
        progress.className = 'progress-overlay';
        progress.innerHTML = `
            <div class="progress-content">
                <div class="spinner"></div>
                <p>${message}</p>
            </div>
        `;
        document.body.appendChild(progress);
    }
    
    hideProgress() {
        const progress = document.getElementById('import-export-progress');
        if (progress) {
            document.body.removeChild(progress);
        }
    }
    
    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        
        // Position at top-right
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 15px 20px;
            border-radius: 4px;
            z-index: 10000;
            max-width: 300px;
        `;
        
        // Set color based on type
        const colors = {
            'success': '#27ae60',
            'error': '#e74c3c',
            'info': '#3498db',
            'warning': '#f39c12'
        };
        
        notification.style.backgroundColor = colors[type] || colors.info;
        notification.style.color = 'white';
        
        document.body.appendChild(notification);
        
        // Auto-remove after 3 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 3000);
    }
    
    // Button state management
    setButtonState(button, state, text = null) {
        if (!button) return;
        
        button.classList.remove('loading', 'success', 'error');
        
        if (state === 'loading') {
            button.classList.add('loading');
            button.disabled = true;
            if (text) button.textContent = text;
        } else if (state === 'success') {
            button.classList.add('success');
            button.disabled = false;
            if (text) button.textContent = text;
            
            // Reset after 2 seconds
            setTimeout(() => {
                button.classList.remove('success');
                if (button.dataset.originalText) {
                    button.textContent = button.dataset.originalText;
                }
            }, 2000);
        } else if (state === 'error') {
            button.classList.add('error');
            button.disabled = false;
            if (text) button.textContent = text;
            
            // Reset after 2 seconds
            setTimeout(() => {
                button.classList.remove('error');
                if (button.dataset.originalText) {
                    button.textContent = button.dataset.originalText;
                }
            }, 2000);
        } else {
            button.disabled = false;
            if (text) {
                button.dataset.originalText = button.textContent;
                button.textContent = text;
            }
        }
    }
    
    // Enhanced save functionality with visual feedback
    async saveScreenplayWithFeedback() {
        const saveButton = document.querySelector('[onclick="saveScreenplay()"]');
        if (!saveButton) return;
        
        this.setButtonState(saveButton, 'loading', 'Saving...');
        
        try {
            // Call the existing saveScreenplay function
            await window.saveScreenplay();
            
            this.saveCount++;
            const timestamp = new Date().toLocaleTimeString();
            this.setButtonState(saveButton, 'success', `Saved v${this.saveCount} (${timestamp})`);
            this.showNotification(`Screenplay saved as v${this.saveCount}`, 'success');
            
        } catch (error) {
            this.setButtonState(saveButton, 'error', 'Save Failed');
            this.showNotification('Save failed: ' + error.message, 'error');
        }
    }
    
    // Enhanced backup functionality with visual feedback
    async createBackupWithFeedback(screenplayId) {
        const backupButton = document.querySelector('[data-backup]');
        if (!backupButton) return;
        
        this.setButtonState(backupButton, 'loading', 'Backing up...');
        
        try {
            const result = await this.createBackup(screenplayId);
            
            if (result.skipped) {
                this.setButtonState(backupButton, 'success', 'No Changes');
                this.showNotification('No changes to backup', 'info');
                return;
            }
            
            this.backupCount++;
            const timestamp = new Date().toLocaleTimeString();
            this.setButtonState(backupButton, 'success', `Backup #${this.backupCount} (${timestamp})`);
            this.showNotification(`Backup #${this.backupCount} created`, 'success');
            
        } catch (error) {
            this.setButtonState(backupButton, 'error', 'Backup Failed');
            this.showNotification('Backup failed: ' + error.message, 'error');
        }
    }
}

// Initialize the import/export manager
const importExportManager = new ImportExportManager();

// Global function for screenplay pages
window.setCurrentScreenplayForBackup = (screenplayId) => {
    importExportManager.setCurrentScreenplay(screenplayId);
};

// Export for global access
window.ImportExportManager = ImportExportManager;

// Add backup settings to global scope
window.showBackupSettings = () => {
    importExportManager.showBackupSettingsDialog();
};
