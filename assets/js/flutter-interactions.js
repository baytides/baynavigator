/**
 * Flutter-Inspired Interactions
 * ============================================
 * Brings Material Design micro-interactions to the Jekyll site:
 * - Ripple effect on buttons and interactive elements
 * - Haptic feedback via Web Vibration API
 * - Spring-like animations coordination
 *
 * WCAG 2.2 AAA Compliant:
 * - Respects prefers-reduced-motion
 * - No functionality depends on animations
 * - All interactions are progressive enhancements
 */

(function() {
  'use strict';

  // Check for reduced motion preference
  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // ============================================
  // HAPTIC FEEDBACK - Web Vibration API
  // ============================================

  const haptic = {
    /**
     * Light impact - for button taps, selections
     */
    light: function() {
      if ('vibrate' in navigator && !prefersReducedMotion) {
        navigator.vibrate(10);
      }
    },

    /**
     * Medium impact - for toggles, confirmations
     */
    medium: function() {
      if ('vibrate' in navigator && !prefersReducedMotion) {
        navigator.vibrate(20);
      }
    },

    /**
     * Heavy impact - for errors, important actions
     */
    heavy: function() {
      if ('vibrate' in navigator && !prefersReducedMotion) {
        navigator.vibrate([30, 10, 30]);
      }
    },

    /**
     * Selection changed - subtle feedback
     */
    selection: function() {
      if ('vibrate' in navigator && !prefersReducedMotion) {
        navigator.vibrate(5);
      }
    },

    /**
     * Success pattern
     */
    success: function() {
      if ('vibrate' in navigator && !prefersReducedMotion) {
        navigator.vibrate([10, 50, 10]);
      }
    },

    /**
     * Error pattern
     */
    error: function() {
      if ('vibrate' in navigator && !prefersReducedMotion) {
        navigator.vibrate([50, 30, 50, 30, 50]);
      }
    }
  };

  // Expose globally for other scripts
  window.haptic = haptic;

  // ============================================
  // RIPPLE EFFECT
  // ============================================

  /**
   * Create a ripple effect on an element
   * @param {HTMLElement} element - The element to add ripple to
   * @param {MouseEvent|TouchEvent} event - The triggering event
   */
  function createRipple(element, event) {
    if (prefersReducedMotion) return;

    // Get element position and dimensions
    const rect = element.getBoundingClientRect();

    // Calculate ripple size (diagonal of element)
    const size = Math.max(rect.width, rect.height);

    // Get click/touch position relative to element
    let x, y;
    if (event.touches && event.touches.length > 0) {
      x = event.touches[0].clientX - rect.left;
      y = event.touches[0].clientY - rect.top;
    } else {
      x = event.clientX - rect.left;
      y = event.clientY - rect.top;
    }

    // Create ripple element
    const ripple = document.createElement('span');
    ripple.className = 'ripple';
    ripple.style.width = ripple.style.height = size + 'px';
    ripple.style.left = (x - size / 2) + 'px';
    ripple.style.top = (y - size / 2) + 'px';

    // Add to element
    element.appendChild(ripple);

    // Remove after animation
    ripple.addEventListener('animationend', function() {
      ripple.remove();
    });

    // Fallback removal
    setTimeout(function() {
      if (ripple.parentNode) {
        ripple.remove();
      }
    }, 600);
  }

  // ============================================
  // RIPPLE INITIALIZATION
  // ============================================

  /**
   * Initialize ripple effect on an element
   * @param {HTMLElement} element - Element to add ripple to
   */
  function initRipple(element) {
    // Mark as having ripple
    element.classList.add('has-ripple');

    // Ensure proper positioning
    const computedStyle = getComputedStyle(element);
    if (computedStyle.position === 'static') {
      element.style.position = 'relative';
    }

    // Ensure overflow hidden for ripple containment
    element.style.overflow = 'hidden';

    // Add event listeners
    element.addEventListener('mousedown', function(e) {
      // Don't trigger on right click
      if (e.button !== 0) return;
      createRipple(element, e);
      haptic.light();
    });

    element.addEventListener('touchstart', function(e) {
      createRipple(element, e);
      haptic.light();
    }, { passive: true });
  }

  // ============================================
  // AUTO-INITIALIZE RIPPLES
  // ============================================

  function initAllRipples() {
    // Selectors for elements that should have ripple
    const rippleSelectors = [
      '.btn',
      '.filter-btn',
      '.card-save-btn',
      '.mobile-filter-toggle',
      '.mobile-bottom-nav button',
      '.back-to-top',
      '.step-submit',
      '.mobile-drawer-close'
    ];

    // Initialize ripples on matching elements
    rippleSelectors.forEach(function(selector) {
      document.querySelectorAll(selector).forEach(function(element) {
        if (!element.classList.contains('has-ripple')) {
          initRipple(element);
        }
      });
    });
  }

  // ============================================
  // HAPTIC ON COMMON INTERACTIONS
  // ============================================

  function initHapticFeedback() {
    // Filter button clicks
    document.addEventListener('click', function(e) {
      const filterBtn = e.target.closest('.filter-btn');
      if (filterBtn) {
        if (filterBtn.classList.contains('active')) {
          haptic.selection();
        } else {
          haptic.light();
        }
      }

      // Program card favorite toggle
      const saveBtn = e.target.closest('.card-save-btn');
      if (saveBtn) {
        haptic.medium();
      }

      // Modal open/close
      const modalTrigger = e.target.closest('[data-modal]');
      if (modalTrigger) {
        haptic.light();
      }

      // Back to top
      const backToTop = e.target.closest('.back-to-top');
      if (backToTop) {
        haptic.light();
      }
    });

    // Search input - haptic on clear
    document.addEventListener('click', function(e) {
      const clearBtn = e.target.closest('.search-clear, [aria-label*="clear"]');
      if (clearBtn) {
        haptic.light();
      }
    });

    // Form submission
    document.addEventListener('submit', function() {
      haptic.success();
    });
  }

  // ============================================
  // DRAWER DRAG GESTURE (Touch support)
  // ============================================

  function initDrawerDrag() {
    const panel = document.querySelector('.search-panel');
    if (!panel) return;

    let startY = 0;
    let currentY = 0;
    let isDragging = false;

    // Only on mobile
    if (window.innerWidth > 768) return;

    panel.addEventListener('touchstart', function(e) {
      // Only start drag from the top area (drag handle)
      const touch = e.touches[0];
      const rect = panel.getBoundingClientRect();
      const touchY = touch.clientY - rect.top;

      // Only drag from top 60px (handle area)
      if (touchY > 60) return;

      startY = touch.clientY;
      isDragging = true;
      panel.style.transition = 'none';
    }, { passive: true });

    panel.addEventListener('touchmove', function(e) {
      if (!isDragging) return;

      currentY = e.touches[0].clientY;
      const deltaY = currentY - startY;

      // Only allow dragging down
      if (deltaY > 0) {
        panel.style.transform = 'translateY(' + deltaY + 'px)';
      }
    }, { passive: true });

    panel.addEventListener('touchend', function() {
      if (!isDragging) return;

      isDragging = false;
      panel.style.transition = '';

      const deltaY = currentY - startY;

      // If dragged more than 100px, close the drawer
      if (deltaY > 100) {
        panel.classList.remove('mobile-open');
        const backdrop = document.querySelector('.mobile-filter-backdrop');
        if (backdrop) backdrop.classList.remove('show');
        document.body.style.overflow = '';
        const toggle = document.getElementById('mobile-filter-toggle');
        if (toggle) toggle.setAttribute('aria-expanded', 'false');
        haptic.light();
      }

      // Reset transform
      panel.style.transform = '';
    });
  }

  // ============================================
  // MUTATION OBSERVER - For Dynamic Content
  // ============================================

  function initMutationObserver() {
    const observer = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
          // Re-initialize ripples for new elements
          initAllRipples();
        }
      });
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }

  // ============================================
  // INITIALIZE ON DOM READY
  // ============================================

  function init() {
    initAllRipples();
    initHapticFeedback();
    initDrawerDrag();
    initMutationObserver();
  }

  // Run on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  // Re-init on window resize (for responsive changes)
  let resizeTimer;
  window.addEventListener('resize', function() {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(function() {
      initDrawerDrag();
    }, 250);
  });

})();
