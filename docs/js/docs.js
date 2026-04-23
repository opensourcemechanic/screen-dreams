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

    // Add animation to feature cards on scroll
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

    // Observe feature cards and other elements
    document.querySelectorAll('.feature-card, .screenshot-card, .step-item, .provider-item').forEach(el => {
        observer.observe(el);
    });

    // Terminal typing effect
    const terminalLines = document.querySelectorAll('.terminal-line');
    terminalLines.forEach((line, index) => {
        line.style.opacity = '0';
        line.style.transform = 'translateX(-20px)';
        
        setTimeout(() => {
            line.style.transition = 'all 0.5s ease';
            line.style.opacity = '1';
            line.style.transform = 'translateX(0)';
        }, 1000 + (index * 500));
    });

    // Copy code functionality
    document.querySelectorAll('code').forEach(codeBlock => {
        if (codeBlock.textContent.includes('uvx') || codeBlock.textContent.includes('curl')) {
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
        }
    });

    // Add copy button styles
    const style = document.createElement('style');
    style.textContent = `
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
        
        .navbar.scrolled {
            background: rgba(102, 126, 234, 0.95) !important;
            backdrop-filter: blur(10px);
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .animate-in {
            animation: fadeInUp 0.6s ease forwards;
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
        
        .screenshot-card {
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .screenshot-card:hover {
            transform: translateY(-8px) scale(1.02);
            box-shadow: 0 15px 35px rgba(0,0,0,0.2);
        }
        
        .install-card {
            cursor: pointer;
        }
        
        .install-card:hover {
            transform: translateY(-8px);
        }
        
        .hero-buttons .btn {
            transition: all 0.3s ease;
        }
        
        .hero-buttons .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.2);
        }
    `;
    document.head.appendChild(style);

    // Lightbox for screenshots
    document.querySelectorAll('.screenshot-card img').forEach(img => {
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

    // Add hover effects to installation cards
    document.querySelectorAll('.install-card').forEach(card => {
        card.addEventListener('mouseenter', () => {
            card.style.transform = 'translateY(-8px) scale(1.02)';
        });
        
        card.addEventListener('mouseleave', () => {
            card.style.transform = 'translateY(0) scale(1)';
        });
    });

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

    // Performance optimization: Lazy load images
    const images = document.querySelectorAll('img[data-src]');
    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.classList.remove('lazy');
                imageObserver.unobserve(img);
            }
        });
    });

    images.forEach(img => imageObserver.observe(img));
});
