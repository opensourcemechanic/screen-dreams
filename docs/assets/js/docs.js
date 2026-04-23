// Screen Dreams Documentation JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Initialize tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl)
    });

    // Smooth scrolling for navigation links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Add scroll effect to navbar
    window.addEventListener('scroll', function() {
        const navbar = document.querySelector('.navbar');
        if (window.scrollY > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
    });

    // Copy code functionality
    document.querySelectorAll('pre code').forEach(codeBlock => {
        const button = document.createElement('button');
        button.className = 'copy-code-btn';
        button.innerHTML = '<i class="fas fa-copy"></i>';
        button.title = 'Copy to clipboard';
        
        codeBlock.style.position = 'relative';
        codeBlock.style.paddingRight = '40px';
        
        const wrapper = document.createElement('div');
        wrapper.style.position = 'relative';
        wrapper.style.display = 'inline-block';
        wrapper.style.width = '100%';
        
        codeBlock.parentNode.insertBefore(wrapper, codeBlock);
        wrapper.appendChild(codeBlock);
        wrapper.appendChild(button);
        
        button.addEventListener('click', () => {
            navigator.clipboard.writeText(codeBlock.textContent).then(() => {
                button.innerHTML = '<i class="fas fa-check"></i>';
                button.style.color = '#28ca42';
                
                setTimeout(() => {
                    button.innerHTML = '<i class="fas fa-copy"></i>';
                    button.style.color = '';
                }, 2000);
            });
        });
    });

    // Add copy button styles
    const style = document.createElement('style');
    style.textContent = `
        .navbar.scrolled {
            background: rgba(102, 126, 234, 0.95) !important;
            backdrop-filter: blur(10px);
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .copy-code-btn {
            position: absolute;
            top: 0.5rem;
            right: 0.5rem;
            background: #4a5568;
            color: white;
            border: none;
            border-radius: 0.375rem;
            padding: 0.5rem;
            cursor: pointer;
            font-size: 0.875rem;
            transition: all 0.2s ease;
            z-index: 10;
        }
        
        .copy-code-btn:hover {
            background: #667eea;
            transform: scale(1.05);
        }
        
        .download-card {
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .download-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }
        
        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .animate-in {
            animation: fadeInUp 0.6s ease forwards;
        }
    `;
    document.head.appendChild(style);

    // Mobile menu handling
    const navbarToggler = document.querySelector('.navbar-toggler');
    const navbarCollapse = document.querySelector('.navbar-collapse');
    
    if (navbarToggler && navbarCollapse) {
        navbarToggler.addEventListener('click', () => {
            navbarCollapse.classList.toggle('show');
        });
        
        // Close mobile menu when clicking on a link
        document.querySelectorAll('.navbar-nav .nav-link').forEach(link => {
            link.addEventListener('click', () => {
                navbarCollapse.classList.remove('show');
            });
        });
    }

    // Add animation to elements on scroll
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate-in');
            }
        });
    }, observerOptions);

    // Observe elements for animation
    document.querySelectorAll('.download-card, .docs-content h2, .docs-content h3').forEach(el => {
        observer.observe(el);
    });

    // Image lightbox functionality
    document.querySelectorAll('img').forEach(img => {
        img.addEventListener('click', () => {
            createLightbox(img.src, img.alt || 'Screen Dreams Screenshot');
        });
    });

    function createLightbox(src, alt) {
        const lightbox = document.createElement('div');
        lightbox.className = 'docs-lightbox';
        lightbox.innerHTML = `
            <div class="lightbox-backdrop">
                <div class="lightbox-content">
                    <img src="${src}" alt="${alt}">
                    <button class="lightbox-close">&times;</button>
                </div>
            </div>
        `;
        
        document.body.appendChild(lightbox);
        
        // Add lightbox styles if not already present
        if (!document.querySelector('#lightbox-styles')) {
            const lightboxStyles = document.createElement('style');
            lightboxStyles.id = 'lightbox-styles';
            lightboxStyles.textContent = `
                .docs-lightbox {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    z-index: 9999;
                }
                
                .lightbox-backdrop {
                    width: 100%;
                    height: 100%;
                    background: rgba(0, 0, 0, 0.9);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    animation: fadeIn 0.3s ease;
                }
                
                .lightbox-content {
                    position: relative;
                    max-width: 90%;
                    max-height: 90%;
                }
                
                .lightbox-content img {
                    width: 100%;
                    height: auto;
                    border-radius: 0.5rem;
                    box-shadow: 0 10px 50px rgba(0, 0, 0, 0.5);
                }
                
                .lightbox-close {
                    position: absolute;
                    top: -2rem;
                    right: 0;
                    background: white;
                    border: none;
                    border-radius: 50%;
                    width: 2rem;
                    height: 2rem;
                    font-size: 1.5rem;
                    cursor: pointer;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
                    transition: all 0.2s ease;
                }
                
                .lightbox-close:hover {
                    transform: scale(1.1);
                    background: #f8f9fa;
                }
                
                @keyframes fadeIn {
                    from { opacity: 0; }
                    to { opacity: 1; }
                }
            `;
            document.head.appendChild(lightboxStyles);
        }
        
        // Close lightbox on backdrop click or close button
        const closeLightbox = () => {
            lightbox.remove();
        };
        
        lightbox.querySelector('.lightbox-backdrop').addEventListener('click', closeLightbox);
        lightbox.querySelector('.lightbox-close').addEventListener('click', closeLightbox);
        
        // Close on escape key
        const handleEscape = (e) => {
            if (e.key === 'Escape') {
                closeLightbox();
                document.removeEventListener('keydown', handleEscape);
            }
        };
        document.addEventListener('keydown', handleEscape);
    }

    // Table of contents for long pages
    if (document.querySelector('.docs-content h2')) {
        const toc = document.createElement('div');
        toc.className = 'table-of-contents mb-4';
        toc.innerHTML = '<h5>Table of Contents</h5><ul class="list-unstyled"></ul>';
        
        const headings = document.querySelectorAll('.docs-content h2');
        const tocList = toc.querySelector('ul');
        
        headings.forEach((heading, index) => {
            const li = document.createElement('li');
            const a = document.createElement('a');
            a.href = `#${heading.id || heading.textContent.toLowerCase().replace(/\s+/g, '-')}`;
            a.textContent = heading.textContent;
            a.className = 'toc-link';
            li.appendChild(a);
            tocList.appendChild(li);
            
            // Add ID if not present
            if (!heading.id) {
                heading.id = `heading-${index}`;
            }
        });
        
        // Insert after first paragraph
        const firstParagraph = document.querySelector('.docs-content p');
        if (firstParagraph) {
            firstParagraph.parentNode.insertBefore(toc, firstParagraph.nextSibling);
        }
        
        // Add TOC styles
        const tocStyles = document.createElement('style');
        tocStyles.textContent = `
            .table-of-contents {
                background: #f8f9fa;
                border: 1px solid #e9ecef;
                border-radius: 0.75rem;
                padding: 1.5rem;
                margin-bottom: 2rem;
            }
            
            .table-of-contents h5 {
                color: #2c3e50;
                margin-bottom: 1rem;
                font-weight: 600;
            }
            
            .toc-link {
                color: #495057;
                text-decoration: none;
                padding: 0.5rem 0;
                display: block;
                transition: color 0.3s ease;
            }
            
            .toc-link:hover {
                color: #667eea;
            }
        `;
        document.head.appendChild(tocStyles);
    }

    // Search functionality (if search input exists)
    const searchInput = document.querySelector('#search');
    if (searchInput) {
        searchInput.addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase();
            const content = document.querySelector('.docs-content');
            
            if (query.length > 2) {
                // Simple search implementation
                const sections = content.querySelectorAll('h2, h3');
                sections.forEach(section => {
                    const sectionText = section.textContent.toLowerCase();
                    const sectionParent = section.parentElement;
                    
                    if (sectionText.includes(query)) {
                        sectionParent.style.display = 'block';
                        highlightText(sectionParent, query);
                    } else {
                        sectionParent.style.display = 'none';
                    }
                });
            } else {
                // Reset all sections
                const sections = content.querySelectorAll('h2, h3');
                sections.forEach(section => {
                    const sectionParent = section.parentElement;
                    sectionParent.style.display = 'block';
                    removeHighlight(sectionParent);
                });
            }
        });
    }

    function highlightText(element, query) {
        const walker = document.createTreeWalker(
            element,
            NodeFilter.SHOW_TEXT,
            null,
            false
        );
        
        const textNodes = [];
        let node;
        while (node = walker.nextNode()) {
            if (node.nodeValue.toLowerCase().includes(query)) {
                textNodes.push(node);
            }
        }
        
        textNodes.forEach(textNode => {
            const parent = textNode.parentNode;
            const text = textNode.nodeValue;
            const regex = new RegExp(`(${query})`, 'gi');
            const highlightedHTML = text.replace(regex, '<mark>$1</mark>');
            
            const wrapper = document.createElement('span');
            wrapper.innerHTML = highlightedHTML;
            parent.replaceChild(wrapper, textNode);
        });
    }

    function removeHighlight(element) {
        const marks = element.querySelectorAll('mark');
        marks.forEach(mark => {
            const parent = mark.parentNode;
            parent.replaceChild(document.createTextNode(mark.textContent), mark);
            parent.normalize();
        });
    }

    // Print functionality
    const printButton = document.querySelector('#print-button');
    if (printButton) {
        printButton.addEventListener('click', () => {
            window.print();
        });
    }

    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
        // Ctrl/Cmd + K for search
        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            const searchInput = document.querySelector('#search');
            if (searchInput) {
                searchInput.focus();
            }
        }
        
        // Ctrl/Cmd + / for search
        if ((e.ctrlKey || e.metaKey) && e.key === '/') {
            e.preventDefault();
            const searchInput = document.querySelector('#search');
            if (searchInput) {
                searchInput.focus();
            }
        }
        
        // Escape to clear search
        if (e.key === 'Escape') {
            const searchInput = document.querySelector('#search');
            if (searchInput && searchInput.value) {
                searchInput.value = '';
                searchInput.dispatchEvent(new Event('input'));
            }
        }
    });
});
