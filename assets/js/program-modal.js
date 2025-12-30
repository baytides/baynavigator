/**
 * Program Modal - Handles program detail popout/modal
 * Features:
 * - Open modal on card click
 * - Display full program details with new fields
 * - Call Now / Get Directions / Learn More buttons
 * - Report an Issue functionality
 * - Save/bookmark programs
 * - Keyboard accessibility
 */

(function() {
  'use strict';

  // Create modal container once
  let modalOverlay = null;

  function createModalHTML() {
    const overlay = document.createElement('div');
    overlay.className = 'program-modal-overlay';
    overlay.id = 'program-modal-overlay';
    overlay.setAttribute('role', 'dialog');
    overlay.setAttribute('aria-modal', 'true');
    overlay.setAttribute('aria-labelledby', 'modal-title');

    overlay.innerHTML = `
      <div class="program-modal" role="document">
        <!-- Modal Header -->
        <div class="modal-header" id="modal-header">
          <div class="modal-header-gradient" id="modal-header-visual">
            <!-- Icon or image will be inserted here -->
          </div>
          <button class="modal-close-btn" type="button" aria-label="Close modal" id="modal-close">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
          <span class="modal-category" id="modal-category"></span>
        </div>

        <!-- Modal Body -->
        <div class="modal-body" id="modal-body">
          <h2 class="modal-title" id="modal-title"></h2>
          <div class="modal-location" id="modal-location">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
              <circle cx="12" cy="10" r="3"></circle>
            </svg>
            <span id="modal-location-text"></span>
          </div>

          <!-- About Section -->
          <p class="modal-description" id="modal-description"></p>

          <!-- What They Offer Section -->
          <div class="modal-section" id="modal-offer-section">
            <h3 class="modal-section-title">What They Offer</h3>
            <div class="modal-section-content modal-offer-list" id="modal-offer"></div>
          </div>

          <!-- How To Get It Section -->
          <div class="modal-section" id="modal-howto-section">
            <h3 class="modal-section-title">How to Get It</h3>
            <div class="modal-section-content" id="modal-howto"></div>
          </div>

          <!-- Eligibility Section -->
          <div class="modal-section" id="modal-eligibility-section">
            <h3 class="modal-section-title">Who's Eligible</h3>
            <div class="modal-eligibility" id="modal-eligibility"></div>
          </div>

          <!-- Contact Section -->
          <div class="modal-section" id="modal-contact-section">
            <h3 class="modal-section-title">Contact</h3>
            <div class="modal-contact" id="modal-contact"></div>
          </div>

          <!-- Meta info -->
          <div class="modal-meta" id="modal-meta"></div>
        </div>

        <!-- Modal Footer -->
        <div class="modal-footer">
          <div class="modal-actions" id="modal-actions">
            <!-- CTA buttons will be inserted here -->
          </div>
          <button class="modal-save-btn" type="button" aria-label="Save program" id="modal-save">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"></path>
            </svg>
          </button>
        </div>

        <!-- Report Issue Link -->
        <div class="modal-report">
          <button type="button" class="modal-report-btn" id="modal-report">
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"></path>
              <line x1="4" y1="22" x2="4" y2="15"></line>
            </svg>
            Report an Issue
          </button>
        </div>
      </div>
    `;

    return overlay;
  }

  function initModal() {
    if (modalOverlay) return;

    modalOverlay = createModalHTML();
    document.body.appendChild(modalOverlay);

    // Add modal styles
    addModalStyles();

    // Event listeners
    const closeBtn = document.getElementById('modal-close');
    const saveBtn = document.getElementById('modal-save');
    const reportBtn = document.getElementById('modal-report');

    closeBtn.addEventListener('click', closeModal);
    modalOverlay.addEventListener('click', (e) => {
      if (e.target === modalOverlay) closeModal();
    });
    saveBtn.addEventListener('click', toggleSaveProgram);
    reportBtn.addEventListener('click', openReportForm);

    // Keyboard events
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && modalOverlay.classList.contains('active')) {
        closeModal();
      }
    });
  }

  function openModal(programId) {
    initModal();

    // Find program data
    const dataScript = document.querySelector(`.program-data[data-program-id="${programId}"]`);
    if (!dataScript) {
      console.error('Program data not found for:', programId);
      return;
    }

    let program;
    try {
      program = JSON.parse(dataScript.textContent);
    } catch (e) {
      console.error('Error parsing program data:', e);
      return;
    }

    // Populate modal
    populateModal(program);

    // Show modal
    modalOverlay.classList.add('active');
    document.body.style.overflow = 'hidden';

    // Focus management
    document.getElementById('modal-close').focus();
  }

  function closeModal() {
    if (!modalOverlay) return;
    modalOverlay.classList.remove('active');
    document.body.style.overflow = '';

    // Return focus to the triggering card
    const activeCard = document.querySelector('.program-card:focus, .program-card.last-focused');
    if (activeCard) {
      activeCard.focus();
      activeCard.classList.remove('last-focused');
    }
  }

  function populateModal(program) {
    // Header visual
    const headerVisual = document.getElementById('modal-header-visual');
    headerVisual.style.setProperty('--modal-cat-color', program.catColor || '#0891b2');

    if (program.image) {
      headerVisual.innerHTML = `<img src="${program.image}" alt="" class="modal-header-image">`;
      headerVisual.className = 'modal-header-visual';
    } else {
      headerVisual.innerHTML = getCategoryIcon(program.category);
      headerVisual.className = 'modal-header-gradient';
    }

    // Category
    document.getElementById('modal-category').textContent = program.category || '';

    // Title
    const titleEl = document.getElementById('modal-title');
    titleEl.innerHTML = program.name;
    if (program.verified_date) {
      titleEl.innerHTML += `
        <span class="modal-verified" title="Verified ${program.verified_date}">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
            <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
          </svg>
        </span>`;
    }

    // Location
    let locationText = program.city || '';
    if (!locationText && program.area) {
      locationText = Array.isArray(program.area) ? program.area.join(', ') : program.area;
    }
    document.getElementById('modal-location-text').textContent = locationText || 'Bay Area';

    // Description
    document.getElementById('modal-description').textContent = program.description || program.benefit || '';

    // What They Offer
    const offerSection = document.getElementById('modal-offer-section');
    const offerContent = document.getElementById('modal-offer');
    if (program.what_they_offer) {
      offerSection.style.display = 'block';
      // Convert markdown-style lists to HTML
      offerContent.innerHTML = formatOfferList(program.what_they_offer);
    } else if (program.benefit && program.benefit !== program.description) {
      offerSection.style.display = 'block';
      offerContent.innerHTML = `<p>${program.benefit}</p>`;
    } else {
      offerSection.style.display = 'none';
    }

    // How To Get It
    const howtoSection = document.getElementById('modal-howto-section');
    const howtoContent = document.getElementById('modal-howto');
    if (program.how_to_get_it) {
      howtoSection.style.display = 'block';
      howtoContent.textContent = program.how_to_get_it;
    } else {
      howtoSection.style.display = 'none';
    }

    // Eligibility
    const eligSection = document.getElementById('modal-eligibility-section');
    const eligContent = document.getElementById('modal-eligibility');
    if (program.eligibility && program.eligibility.length > 0) {
      eligSection.style.display = 'block';
      eligContent.innerHTML = program.eligibility
        .filter(e => e && !e.startsWith('📍')) // Filter out emoji placeholders
        .map(e => `<span class="modal-tag">${formatEligibility(e)}</span>`)
        .join('');
    } else {
      eligSection.style.display = 'none';
    }

    // Contact Section
    const contactSection = document.getElementById('modal-contact-section');
    const contactContent = document.getElementById('modal-contact');
    if (program.phone || program.address) {
      contactSection.style.display = 'block';
      let contactHTML = '';

      if (program.phone) {
        contactHTML += `
          <div class="modal-contact-item">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path>
            </svg>
            <a href="tel:${program.phone.replace(/[^0-9+]/g, '')}">${program.phone}</a>
          </div>`;
      }

      if (program.address) {
        const mapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(program.address)}`;
        contactHTML += `
          <div class="modal-contact-item">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
              <circle cx="12" cy="10" r="3"></circle>
            </svg>
            <a href="${mapsUrl}" target="_blank" rel="noopener noreferrer">${program.address}</a>
          </div>`;
      }

      contactContent.innerHTML = contactHTML;
    } else {
      contactSection.style.display = 'none';
    }

    // Meta info
    const metaContent = document.getElementById('modal-meta');
    let metaHTML = '';
    if (program.timeframe) {
      metaHTML += `
        <span class="modal-meta-item">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10"></circle>
            <polyline points="12 6 12 12 16 14"></polyline>
          </svg>
          ${program.timeframe}
        </span>`;
    }
    if (program.verified_date) {
      metaHTML += `
        <span class="modal-meta-item">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="20 6 9 17 4 12"></polyline>
          </svg>
          Verified ${program.verified_date}
        </span>`;
    }
    metaContent.innerHTML = metaHTML;

    // Action buttons
    const actionsContainer = document.getElementById('modal-actions');
    let actionsHTML = '';

    // Primary CTA - depends on what we have
    if (program.phone) {
      actionsHTML += `
        <a href="tel:${program.phone.replace(/[^0-9+]/g, '')}" class="modal-cta modal-cta-phone">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path>
          </svg>
          Call Now
        </a>`;
    }

    if (program.address) {
      const mapsUrl = `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(program.address)}`;
      actionsHTML += `
        <a href="${mapsUrl}" target="_blank" rel="noopener noreferrer" class="modal-cta modal-cta-directions ${program.phone ? 'modal-cta-secondary' : ''}">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polygon points="3 11 22 2 13 21 11 13 3 11"></polygon>
          </svg>
          Get Directions
        </a>`;
    }

    if (program.link) {
      const isPrimary = !program.phone && !program.address;
      actionsHTML += `
        <a href="${program.link}" target="_blank" rel="noopener noreferrer" class="modal-cta ${isPrimary ? '' : 'modal-cta-secondary'}">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path>
            <polyline points="15 3 21 3 21 9"></polyline>
            <line x1="10" y1="14" x2="21" y2="3"></line>
          </svg>
          ${program.link_text || 'Learn More'}
        </a>`;
    }

    actionsContainer.innerHTML = actionsHTML;

    // Update save button state
    const saveBtn = document.getElementById('modal-save');
    const savedPrograms = JSON.parse(localStorage.getItem('savedPrograms') || '[]');
    if (savedPrograms.includes(program.id)) {
      saveBtn.classList.add('saved');
    } else {
      saveBtn.classList.remove('saved');
    }
    saveBtn.dataset.programId = program.id;

    // Store current program for report
    modalOverlay.dataset.currentProgramId = program.id;
    modalOverlay.dataset.currentProgramName = program.name;
  }

  function formatOfferList(text) {
    if (!text) return '';

    // Split by lines and convert to list items
    const lines = text.split('\n').filter(line => line.trim());
    let html = '<ul class="modal-offer-list">';

    lines.forEach(line => {
      // Remove leading "- " if present
      const cleanLine = line.replace(/^[\s-]*/, '').trim();
      if (cleanLine) {
        html += `<li>${cleanLine}</li>`;
      }
    });

    html += '</ul>';
    return html;
  }

  function formatEligibility(elig) {
    const map = {
      'low-income': 'Low Income',
      'seniors': 'Seniors',
      'youth': 'Youth',
      'college-students': 'Students',
      'veterans': 'Veterans',
      'families': 'Families',
      'disability': 'Disability',
      'nonprofits': 'Nonprofits',
      'everyone': 'Everyone'
    };
    return map[elig] || elig;
  }

  function getCategoryIcon(category) {
    const icons = {
      'Food': '<svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8h1a4 4 0 0 1 0 8h-1"></path><path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"></path><line x1="6" y1="1" x2="6" y2="4"></line><line x1="10" y1="1" x2="10" y2="4"></line><line x1="14" y1="1" x2="14" y2="4"></line></svg>',
      'Health': '<svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 12h-4l-3 9L9 3l-3 9H2"></path></svg>',
      'Recreation': '<svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M2 7l10-5 10 5-10 5z"></path><path d="M2 17l10 5 10-5"></path><path d="M2 12l10 5 10-5"></path></svg>',
      'Museums': '<svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M2 7l10-5 10 5-10 5z"></path><path d="M2 17l10 5 10-5"></path><path d="M2 12l10 5 10-5"></path></svg>'
    };
    return icons[category] || '<svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>';
  }

  function toggleSaveProgram() {
    const saveBtn = document.getElementById('modal-save');
    const programId = saveBtn.dataset.programId;

    let savedPrograms = JSON.parse(localStorage.getItem('savedPrograms') || '[]');

    if (savedPrograms.includes(programId)) {
      savedPrograms = savedPrograms.filter(id => id !== programId);
      saveBtn.classList.remove('saved');
    } else {
      savedPrograms.push(programId);
      saveBtn.classList.add('saved');
    }

    localStorage.setItem('savedPrograms', JSON.stringify(savedPrograms));

    // Also update the card's save button
    const cardSaveBtn = document.querySelector(`.card-save-btn[data-program-id="${programId}"]`);
    if (cardSaveBtn) {
      cardSaveBtn.classList.toggle('saved', savedPrograms.includes(programId));
    }
  }

  function openReportForm() {
    const programId = modalOverlay.dataset.currentProgramId;
    const programName = modalOverlay.dataset.currentProgramName;

    // Create a simple report form modal
    const reportOverlay = document.createElement('div');
    reportOverlay.className = 'report-overlay active';
    reportOverlay.innerHTML = `
      <div class="report-modal">
        <div class="report-header">
          <h3>Report an Issue</h3>
          <button type="button" class="report-close" aria-label="Close">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        </div>
        <form class="report-form" id="report-form">
          <p class="report-program">Reporting issue with: <strong>${programName}</strong></p>
          <div class="report-field">
            <label for="report-type">What's the issue?</label>
            <select id="report-type" name="type" required>
              <option value="">Select an issue type</option>
              <option value="outdated">Information is outdated</option>
              <option value="incorrect">Information is incorrect</option>
              <option value="broken-link">Link doesn't work</option>
              <option value="program-ended">Program has ended</option>
              <option value="other">Other</option>
            </select>
          </div>
          <div class="report-field">
            <label for="report-details">Details (optional)</label>
            <textarea id="report-details" name="details" rows="3" placeholder="Please describe the issue..."></textarea>
          </div>
          <div class="report-field">
            <label for="report-email">Your email (optional)</label>
            <input type="email" id="report-email" name="email" placeholder="yourname@example.com">
            <small>We'll only use this to follow up if needed</small>
          </div>
          <div class="report-actions">
            <button type="button" class="report-cancel">Cancel</button>
            <button type="submit" class="report-submit">Submit Report</button>
          </div>
        </form>
        <div class="report-success" style="display: none;">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
            <polyline points="22 4 12 14.01 9 11.01"></polyline>
          </svg>
          <h4>Thank you!</h4>
          <p>Your report has been submitted. We'll review it as soon as possible.</p>
          <button type="button" class="report-done">Done</button>
        </div>
      </div>
    `;

    document.body.appendChild(reportOverlay);

    // Event listeners
    const closeBtn = reportOverlay.querySelector('.report-close');
    const cancelBtn = reportOverlay.querySelector('.report-cancel');
    const doneBtn = reportOverlay.querySelector('.report-done');
    const form = reportOverlay.querySelector('#report-form');

    const closeReport = () => {
      reportOverlay.classList.remove('active');
      setTimeout(() => reportOverlay.remove(), 300);
    };

    closeBtn.addEventListener('click', closeReport);
    cancelBtn.addEventListener('click', closeReport);
    doneBtn.addEventListener('click', closeReport);
    reportOverlay.addEventListener('click', (e) => {
      if (e.target === reportOverlay) closeReport();
    });

    form.addEventListener('submit', (e) => {
      e.preventDefault();

      const formData = new FormData(form);
      const reportData = {
        programId,
        programName,
        type: formData.get('type'),
        details: formData.get('details'),
        email: formData.get('email'),
        url: window.location.href,
        timestamp: new Date().toISOString()
      };

      // Store in localStorage for now (could be sent to a backend later)
      const reports = JSON.parse(localStorage.getItem('programReports') || '[]');
      reports.push(reportData);
      localStorage.setItem('programReports', JSON.stringify(reports));

      // Show success message
      form.style.display = 'none';
      reportOverlay.querySelector('.report-success').style.display = 'flex';
    });
  }

  function addModalStyles() {
    if (document.getElementById('program-modal-styles')) return;

    const styles = document.createElement('style');
    styles.id = 'program-modal-styles';
    styles.textContent = `
      /* Modal Overlay */
      .program-modal-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.5);
        backdrop-filter: blur(4px);
        z-index: 9999;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 1rem;
        opacity: 0;
        visibility: hidden;
        transition: all 0.25s ease;
      }

      .program-modal-overlay.active {
        opacity: 1;
        visibility: visible;
      }

      .program-modal {
        background: var(--card-bg, #ffffff);
        border-radius: 20px;
        width: 100%;
        max-width: 600px;
        max-height: 90vh;
        overflow: hidden;
        display: flex;
        flex-direction: column;
        transform: scale(0.95) translateY(20px);
        transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
      }

      .program-modal-overlay.active .program-modal {
        transform: scale(1) translateY(0);
      }

      /* Modal Header */
      .modal-header {
        position: relative;
        height: 140px;
        overflow: hidden;
        flex-shrink: 0;
      }

      .modal-header-gradient {
        width: 100%;
        height: 100%;
        background: linear-gradient(135deg, var(--modal-cat-color, #0891b2), color-mix(in srgb, var(--modal-cat-color, #0891b2) 60%, #1e293b));
        display: flex;
        align-items: center;
        justify-content: center;
        color: rgba(255, 255, 255, 0.2);
      }

      .modal-header-image {
        width: 100%;
        height: 100%;
        object-fit: cover;
      }

      .modal-close-btn {
        position: absolute;
        top: 12px;
        right: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 40px;
        height: 40px;
        padding: 0;
        background: rgba(255, 255, 255, 0.95);
        border: none;
        border-radius: 12px;
        color: #374151;
        cursor: pointer;
        transition: all 0.15s ease;
        z-index: 2;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      }

      .modal-close-btn:hover {
        background: white;
        transform: scale(1.05);
      }

      .modal-category {
        position: absolute;
        bottom: 12px;
        left: 16px;
        display: inline-flex;
        align-items: center;
        padding: 0.375rem 0.75rem;
        font-size: 0.75rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: white;
        background: rgba(0, 0, 0, 0.6);
        backdrop-filter: blur(4px);
        border-radius: 8px;
      }

      /* Modal Body */
      .modal-body {
        padding: 1.5rem;
        overflow-y: auto;
        flex: 1;
      }

      .modal-title {
        font-size: 1.375rem;
        font-weight: 700;
        color: var(--text-primary, #111827);
        margin: 0 0 0.5rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        flex-wrap: wrap;
      }

      .modal-verified {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 20px;
        height: 20px;
        background: #22c55e;
        color: white;
        border-radius: 50%;
      }

      .modal-location {
        display: flex;
        align-items: center;
        gap: 0.375rem;
        font-size: 0.875rem;
        color: var(--text-secondary, #6b7280);
        margin-bottom: 1rem;
      }

      .modal-description {
        font-size: 0.9375rem;
        line-height: 1.6;
        color: var(--text-secondary, #374151);
        margin-bottom: 1.25rem;
      }

      /* Modal Sections */
      .modal-section {
        margin-bottom: 1.25rem;
      }

      .modal-section-title {
        font-size: 0.8125rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: var(--text-secondary, #6b7280);
        margin: 0 0 0.5rem;
      }

      .modal-section-content {
        font-size: 0.9375rem;
        line-height: 1.5;
        color: var(--text-primary, #111827);
      }

      .modal-offer-list {
        margin: 0;
        padding-left: 1.25rem;
      }

      .modal-offer-list li {
        margin-bottom: 0.375rem;
        color: var(--text-primary, #111827);
      }

      /* Eligibility */
      .modal-eligibility {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
      }

      .modal-tag {
        display: inline-flex;
        align-items: center;
        padding: 0.375rem 0.75rem;
        font-size: 0.8125rem;
        font-weight: 500;
        color: var(--color-primary, #0891b2);
        background: var(--color-primary-light, #ecfeff);
        border-radius: 6px;
      }

      /* Contact */
      .modal-contact {
        display: flex;
        flex-direction: column;
        gap: 0.625rem;
      }

      .modal-contact-item {
        display: flex;
        align-items: flex-start;
        gap: 0.625rem;
        font-size: 0.9375rem;
        color: var(--text-primary, #111827);
      }

      .modal-contact-item svg {
        flex-shrink: 0;
        color: var(--color-primary, #0891b2);
        margin-top: 2px;
      }

      .modal-contact-item a {
        color: var(--color-primary, #0891b2);
        text-decoration: none;
      }

      .modal-contact-item a:hover {
        text-decoration: underline;
      }

      /* Meta */
      .modal-meta {
        display: flex;
        flex-wrap: wrap;
        gap: 1rem;
        font-size: 0.8125rem;
        color: var(--text-secondary, #9ca3af);
        margin-top: 1rem;
        padding-top: 1rem;
        border-top: 1px solid var(--card-border, #e5e7eb);
      }

      .modal-meta-item {
        display: flex;
        align-items: center;
        gap: 0.375rem;
      }

      /* Modal Footer */
      .modal-footer {
        padding: 1rem 1.5rem;
        border-top: 1px solid var(--card-border, #e5e7eb);
        display: flex;
        gap: 0.75rem;
        flex-shrink: 0;
      }

      .modal-actions {
        flex: 1;
        display: flex;
        gap: 0.5rem;
        flex-wrap: wrap;
      }

      .modal-cta {
        flex: 1;
        min-width: 120px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        padding: 0.75rem 1rem;
        font-size: 0.875rem;
        font-weight: 600;
        color: white;
        background: var(--color-primary, #0891b2);
        border: none;
        border-radius: 10px;
        text-decoration: none;
        cursor: pointer;
        transition: all 0.15s ease;
        min-height: 44px;
      }

      .modal-cta:hover {
        background: var(--color-primary-dark, #0e7490);
        transform: translateY(-1px);
      }

      .modal-cta-secondary {
        background: var(--neutral-100, #f3f4f6);
        color: var(--text-primary, #374151);
      }

      .modal-cta-secondary:hover {
        background: var(--neutral-200, #e5e7eb);
      }

      .modal-cta-phone {
        background: #22c55e;
      }

      .modal-cta-phone:hover {
        background: #16a34a;
      }

      .modal-save-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 44px;
        height: 44px;
        padding: 0;
        background: var(--neutral-100, #f3f4f6);
        border: 1px solid var(--card-border, #e5e7eb);
        border-radius: 10px;
        color: #6b7280;
        cursor: pointer;
        transition: all 0.15s ease;
        flex-shrink: 0;
      }

      .modal-save-btn:hover {
        background: var(--neutral-200, #e5e7eb);
        color: #374151;
      }

      .modal-save-btn.saved {
        color: #ef4444;
        background: #fef2f2;
        border-color: #fecaca;
      }

      .modal-save-btn.saved svg {
        fill: #ef4444;
      }

      /* Report Issue */
      .modal-report {
        padding: 0.75rem 1.5rem 1.25rem;
        text-align: center;
      }

      .modal-report-btn {
        display: inline-flex;
        align-items: center;
        gap: 0.375rem;
        padding: 0.5rem 0.75rem;
        font-size: 0.75rem;
        color: var(--text-secondary, #9ca3af);
        background: transparent;
        border: none;
        cursor: pointer;
        transition: color 0.15s ease;
      }

      .modal-report-btn:hover {
        color: var(--text-primary, #374151);
      }

      /* Report Form Overlay */
      .report-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.6);
        z-index: 10000;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 1rem;
        opacity: 0;
        visibility: hidden;
        transition: all 0.25s ease;
      }

      .report-overlay.active {
        opacity: 1;
        visibility: visible;
      }

      .report-modal {
        background: var(--card-bg, #ffffff);
        border-radius: 16px;
        width: 100%;
        max-width: 420px;
        padding: 1.5rem;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
      }

      .report-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1rem;
      }

      .report-header h3 {
        margin: 0;
        font-size: 1.125rem;
        font-weight: 600;
        color: var(--text-primary, #111827);
      }

      .report-close {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 32px;
        height: 32px;
        padding: 0;
        background: transparent;
        border: none;
        color: var(--text-secondary, #6b7280);
        cursor: pointer;
        border-radius: 8px;
      }

      .report-close:hover {
        background: var(--neutral-100, #f3f4f6);
        color: var(--text-primary, #374151);
      }

      .report-program {
        font-size: 0.875rem;
        color: var(--text-secondary, #6b7280);
        margin: 0 0 1rem;
        padding-bottom: 1rem;
        border-bottom: 1px solid var(--card-border, #e5e7eb);
      }

      .report-program strong {
        color: var(--text-primary, #111827);
      }

      .report-field {
        margin-bottom: 1rem;
      }

      .report-field label {
        display: block;
        font-size: 0.875rem;
        font-weight: 500;
        color: var(--text-primary, #111827);
        margin-bottom: 0.375rem;
      }

      .report-field select,
      .report-field input,
      .report-field textarea {
        width: 100%;
        padding: 0.625rem 0.75rem;
        font-size: 0.875rem;
        color: var(--text-primary, #111827);
        background: var(--card-bg, #ffffff);
        border: 1px solid var(--card-border, #e5e7eb);
        border-radius: 8px;
        transition: border-color 0.15s ease;
      }

      .report-field select:focus,
      .report-field input:focus,
      .report-field textarea:focus {
        outline: none;
        border-color: var(--color-primary, #0891b2);
      }

      .report-field small {
        display: block;
        margin-top: 0.25rem;
        font-size: 0.75rem;
        color: var(--text-secondary, #9ca3af);
      }

      .report-actions {
        display: flex;
        gap: 0.75rem;
        margin-top: 1.25rem;
      }

      .report-cancel {
        flex: 1;
        padding: 0.75rem 1rem;
        font-size: 0.875rem;
        font-weight: 500;
        color: var(--text-primary, #374151);
        background: var(--neutral-100, #f3f4f6);
        border: none;
        border-radius: 8px;
        cursor: pointer;
        transition: background 0.15s ease;
      }

      .report-cancel:hover {
        background: var(--neutral-200, #e5e7eb);
      }

      .report-submit {
        flex: 1;
        padding: 0.75rem 1rem;
        font-size: 0.875rem;
        font-weight: 600;
        color: white;
        background: var(--color-primary, #0891b2);
        border: none;
        border-radius: 8px;
        cursor: pointer;
        transition: background 0.15s ease;
      }

      .report-submit:hover {
        background: var(--color-primary-dark, #0e7490);
      }

      .report-success {
        display: flex;
        flex-direction: column;
        align-items: center;
        text-align: center;
        padding: 1rem 0;
      }

      .report-success svg {
        color: #22c55e;
        margin-bottom: 1rem;
      }

      .report-success h4 {
        margin: 0 0 0.5rem;
        font-size: 1.125rem;
        font-weight: 600;
        color: var(--text-primary, #111827);
      }

      .report-success p {
        margin: 0 0 1.25rem;
        font-size: 0.875rem;
        color: var(--text-secondary, #6b7280);
      }

      .report-done {
        padding: 0.625rem 1.5rem;
        font-size: 0.875rem;
        font-weight: 500;
        color: white;
        background: var(--color-primary, #0891b2);
        border: none;
        border-radius: 8px;
        cursor: pointer;
      }

      /* Dark Mode */
      @media (prefers-color-scheme: dark) {
        .modal-close-btn,
        .report-close {
          background: rgba(55, 65, 81, 0.95);
          color: #f3f4f6;
        }

        .modal-save-btn,
        .modal-cta-secondary {
          background: #374151;
          border-color: #4b5563;
          color: #f3f4f6;
        }

        .report-modal {
          background: #1f2937;
        }

        .report-field select,
        .report-field input,
        .report-field textarea {
          background: #374151;
          border-color: #4b5563;
          color: #f3f4f6;
        }
      }

      body[data-theme="dark"] .modal-close-btn,
      body[data-theme="dark"] .report-close {
        background: rgba(55, 65, 81, 0.95);
        color: #f3f4f6;
      }

      body[data-theme="dark"] .modal-save-btn,
      body[data-theme="dark"] .modal-cta-secondary {
        background: #374151;
        border-color: #4b5563;
        color: #f3f4f6;
      }

      body[data-theme="dark"] .report-modal {
        background: #1f2937;
      }

      body[data-theme="dark"] .report-field select,
      body[data-theme="dark"] .report-field input,
      body[data-theme="dark"] .report-field textarea {
        background: #374151;
        border-color: #4b5563;
        color: #f3f4f6;
      }

      /* Responsive */
      @media (max-width: 640px) {
        .program-modal {
          max-height: 95vh;
          border-radius: 16px 16px 0 0;
          margin-top: auto;
        }

        .modal-header {
          height: 120px;
        }

        .modal-body {
          padding: 1.25rem;
        }

        .modal-title {
          font-size: 1.25rem;
        }

        .modal-footer {
          padding: 1rem;
          flex-wrap: wrap;
        }

        .modal-actions {
          flex-direction: column;
        }

        .modal-cta {
          width: 100%;
        }
      }

      /* Reduced motion */
      @media (prefers-reduced-motion: reduce) {
        .program-modal-overlay,
        .program-modal,
        .report-overlay {
          transition: none;
        }
      }
    `;
    document.head.appendChild(styles);
  }

  // Initialize card click handlers
  function initCardHandlers() {
    document.addEventListener('click', (e) => {
      const card = e.target.closest('.program-card');
      if (card && !e.target.closest('.card-save-btn')) {
        const programId = card.dataset.programId;
        if (programId) {
          card.classList.add('last-focused');
          openModal(programId);
        }
      }
    });

    // Keyboard support
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        const card = e.target.closest('.program-card');
        if (card) {
          const programId = card.dataset.programId;
          if (programId) {
            card.classList.add('last-focused');
            openModal(programId);
          }
        }
      }
    });

    // Initialize save button handlers on cards
    document.addEventListener('click', (e) => {
      const saveBtn = e.target.closest('.card-save-btn');
      if (saveBtn) {
        e.stopPropagation();
        const programId = saveBtn.dataset.programId;

        let savedPrograms = JSON.parse(localStorage.getItem('savedPrograms') || '[]');

        if (savedPrograms.includes(programId)) {
          savedPrograms = savedPrograms.filter(id => id !== programId);
          saveBtn.classList.remove('saved');
        } else {
          savedPrograms.push(programId);
          saveBtn.classList.add('saved');
        }

        localStorage.setItem('savedPrograms', JSON.stringify(savedPrograms));
      }
    });

    // Restore saved state on page load
    const savedPrograms = JSON.parse(localStorage.getItem('savedPrograms') || '[]');
    savedPrograms.forEach(programId => {
      const btn = document.querySelector(`.card-save-btn[data-program-id="${programId}"]`);
      if (btn) btn.classList.add('saved');
    });
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initCardHandlers);
  } else {
    initCardHandlers();
  }

  // Expose for external use if needed
  window.ProgramModal = {
    open: openModal,
    close: closeModal
  };
})();
