// Simple, privacy-friendly analytics
// Tracks only:
// - Most searched terms
// - Most clicked programs
// - Most used filters
// Does NOT track: users, IPs, sessions, or any personal data

class SimpleAnalytics {
  constructor() {
    this.storageKey = 'bayarea_analytics';
    this.data = this.loadData();
  }

  loadData() {
    try {
      const stored = localStorage.getItem(this.storageKey);
      return stored
        ? JSON.parse(stored)
        : {
            searches: {},
            clicks: {},
            filters: {},
            carlFeedback: { up: 0, down: 0, samples: [] },
          };
    } catch {
      return {
        searches: {},
        clicks: {},
        filters: {},
        carlFeedback: { up: 0, down: 0, samples: [] },
      };
    }
  }

  saveData() {
    try {
      localStorage.setItem(this.storageKey, JSON.stringify(this.data));
    } catch (err) {
      console.warn('Could not save analytics:', err);
    }
  }

  // Track search term
  trackSearch(term) {
    if (!term || term.length < 2) return;

    term = term.toLowerCase().trim();
    this.data.searches[term] = (this.data.searches[term] || 0) + 1;
    this.saveData();
  }

  // Track program click
  trackProgramClick(programId, programName) {
    if (!programId) return;

    this.data.clicks[programId] = {
      name: programName,
      count: (this.data.clicks[programId]?.count || 0) + 1,
    };
    this.saveData();
  }

  // Track filter usage
  trackFilter(filterType, filterValue) {
    if (!filterType || !filterValue) return;

    const key = `${filterType}:${filterValue}`;
    this.data.filters[key] = (this.data.filters[key] || 0) + 1;
    this.saveData();
  }

  // Get top searches
  getTopSearches(limit = 10) {
    return Object.entries(this.data.searches)
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit)
      .map(([term, count]) => ({ term, count }));
  }

  // Get top clicked programs
  getTopClicks(limit = 10) {
    return Object.entries(this.data.clicks)
      .sort((a, b) => b[1].count - a[1].count)
      .slice(0, limit)
      .map(([id, data]) => ({ id, name: data.name, count: data.count }));
  }

  // Get top filters
  getTopFilters(limit = 10) {
    return Object.entries(this.data.filters)
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit)
      .map(([key, count]) => {
        const [type, value] = key.split(':');
        return { type, value, count };
      });
  }

  // Track Carl AI response feedback (thumbs up/down)
  trackCarlFeedback(questionSnippet, sentiment) {
    if (!this.data.carlFeedback) {
      this.data.carlFeedback = { up: 0, down: 0, samples: [] };
    }

    // Increment counter
    this.data.carlFeedback[sentiment]++;

    // Keep last 50 samples for review (question + sentiment only, no response text)
    this.data.carlFeedback.samples.push({
      q: questionSnippet.slice(0, 100), // Truncate for privacy
      s: sentiment,
      t: Date.now(),
    });

    // Limit to 50 samples
    if (this.data.carlFeedback.samples.length > 50) {
      this.data.carlFeedback.samples.shift();
    }

    this.saveData();
  }

  // Get Carl feedback statistics
  getCarlFeedbackStats() {
    const fb = this.data.carlFeedback || { up: 0, down: 0, samples: [] };
    const total = fb.up + fb.down;
    return {
      thumbsUp: fb.up,
      thumbsDown: fb.down,
      total: total,
      satisfactionRate: total > 0 ? ((fb.up / total) * 100).toFixed(1) + '%' : 'N/A',
      recentSamples: fb.samples.slice(-10),
    };
  }

  // Export data (for maintainers to review)
  exportData() {
    return {
      topSearches: this.getTopSearches(20),
      topClicks: this.getTopClicks(20),
      topFilters: this.getTopFilters(20),
      carlFeedback: this.getCarlFeedbackStats(),
      exportedAt: new Date().toISOString(),
    };
  }

  // Clear all analytics data
  clearData() {
    this.data = {
      searches: {},
      clicks: {},
      filters: {},
      carlFeedback: { up: 0, down: 0, samples: [] },
    };
    localStorage.removeItem(this.storageKey);
  }
}

// Initialize analytics
window.analytics = new SimpleAnalytics();

// Usage examples:

// Track search
document.getElementById('search-input')?.addEventListener('input', function (e) {
  const term = e.target.value;
  if (term.length >= 2) {
    // Debounce tracking
    clearTimeout(this.searchTimeout);
    this.searchTimeout = setTimeout(() => {
      window.analytics.trackSearch(term);
    }, 1000);
  }
});

// Track program clicks
document.addEventListener('click', function (e) {
  const programLink = e.target.closest('.program-link');
  if (programLink) {
    const card = programLink.closest('.program-card');
    const programId = card?.dataset.programId;
    const programName = card?.dataset.programName;

    if (programId) {
      window.analytics.trackProgramClick(programId, programName);
    }
  }
});

// Track filter clicks
document.addEventListener('click', function (e) {
  const filterBtn = e.target.closest('.filter-btn');
  if (filterBtn) {
    const filterType = filterBtn.dataset.filterType || filterBtn.dataset.filter;
    const filterValue = filterBtn.dataset.filterValue || filterBtn.dataset.value;

    if (filterType && filterValue) {
      window.analytics.trackFilter(filterType, filterValue);
    }
  }
});

// Console command for maintainers to view analytics
// Type in browser console: viewAnalytics()
window.viewAnalytics = function () {
  console.log('📊 Bay Navigator Analytics');
  console.log('================================');
  console.log('\n🔍 Top Searches:');
  console.table(window.analytics.getTopSearches(10));
  console.log('\n👆 Top Clicked Programs:');
  console.table(window.analytics.getTopClicks(10));
  console.log('\n🎯 Top Used Filters:');
  console.table(window.analytics.getTopFilters(10));
  console.log('\n🤖 Carl Feedback:');
  const carlStats = window.analytics.getCarlFeedbackStats();
  console.log(`   👍 Thumbs Up: ${carlStats.thumbsUp}`);
  console.log(`   👎 Thumbs Down: ${carlStats.thumbsDown}`);
  console.log(`   📈 Satisfaction: ${carlStats.satisfactionRate}`);
  if (carlStats.recentSamples.length > 0) {
    console.log('   Recent samples:');
    console.table(carlStats.recentSamples);
  }
  console.log('\n💾 Export all data: analytics.exportData()');
};
