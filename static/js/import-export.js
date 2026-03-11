// Import/Export functionality with automatic backup system
class ImportExportManager {
    constructor() {
        this.backupInterval = null;
        this.backupFrequency = 5 * 60 * 1000; // 5 minutes (configurable)
        this.currentScreenplayId = null;
        this.autoBackupEnabled = true;
        
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
                this.createBackup(screenplayId);
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
            
            // Save backup to localStorage
            const backupKey = `screenplay_backup_${screenplayId}`;
            const backups = JSON.parse(localStorage.getItem(backupKey) || '[]');
            
            // Add new backup to the beginning
            backups.unshift({
                ...result.backup,
                timestamp: new Date().toISOString(),
                id: Date.now()
            });
            
            // Keep only the last 10 backups
            if (backups.length > 10) {
                backups.splice(10);
            }
            
            localStorage.setItem(backupKey, JSON.stringify(backups));
            
            console.log('Backup created successfully');
            
        } catch (error) {
            console.error('Auto backup failed:', error);
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
                    <h4>${backup.title}</h4>
                    <p>${new Date(backup.timestamp).toLocaleString()}</p>
                    <p>Characters: ${backup.metadata.character_count} | Words: ${backup.metadata.word_count}</p>
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
    }
    
    saveBackupSettings() {
        const settings = {
            autoBackup: this.autoBackupEnabled,
            backupFrequency: this.backupFrequency
        };
        localStorage.setItem('import_export_settings', JSON.stringify(settings));
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
}

// Initialize the import/export manager
const importExportManager = new ImportExportManager();

// Global function for screenplay pages
window.setCurrentScreenplayForBackup = (screenplayId) => {
    importExportManager.setCurrentScreenplay(screenplayId);
};

// Export for global access
window.ImportExportManager = ImportExportManager;
