/**
 * Carl Storage - Local conversation history for Ask Carl
 * Uses IndexedDB for privacy-respecting, on-device storage
 * No data ever leaves the user's device
 */

(function () {
  'use strict';

  const DB_NAME = 'carl_storage';
  const DB_VERSION = 1;
  const STORE_CONVERSATIONS = 'conversations';
  const STORE_SETTINGS = 'settings';

  let db = null;

  /**
   * Initialize IndexedDB
   */
  async function initDB() {
    if (db) return db;

    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION);

      request.onerror = () => {
        console.warn('Carl Storage: IndexedDB not available');
        resolve(null);
      };

      request.onsuccess = (event) => {
        db = event.target.result;
        resolve(db);
      };

      request.onupgradeneeded = (event) => {
        const database = event.target.result;

        // Conversations store
        if (!database.objectStoreNames.contains(STORE_CONVERSATIONS)) {
          const convStore = database.createObjectStore(STORE_CONVERSATIONS, {
            keyPath: 'id',
            autoIncrement: true,
          });
          convStore.createIndex('timestamp', 'timestamp', { unique: false });
        }

        // Settings store
        if (!database.objectStoreNames.contains(STORE_SETTINGS)) {
          database.createObjectStore(STORE_SETTINGS, { keyPath: 'key' });
        }
      };
    });
  }

  /**
   * Check if history storage is enabled
   */
  async function isHistoryEnabled() {
    const database = await initDB();
    if (!database) return false;

    return new Promise((resolve) => {
      try {
        const tx = database.transaction(STORE_SETTINGS, 'readonly');
        const store = tx.objectStore(STORE_SETTINGS);
        const request = store.get('historyEnabled');

        request.onsuccess = () => {
          // Default to false (opt-in for privacy)
          resolve(request.result?.value === true);
        };

        request.onerror = () => resolve(false);
      } catch (e) {
        resolve(false);
      }
    });
  }

  /**
   * Set history storage enabled/disabled
   */
  async function setHistoryEnabled(enabled) {
    const database = await initDB();
    if (!database) return false;

    return new Promise((resolve) => {
      try {
        const tx = database.transaction(STORE_SETTINGS, 'readwrite');
        const store = tx.objectStore(STORE_SETTINGS);
        store.put({ key: 'historyEnabled', value: enabled });

        tx.oncomplete = () => {
          // Dispatch event for UI updates
          document.dispatchEvent(
            new CustomEvent('carlHistorySettingChanged', { detail: { enabled } })
          );
          resolve(true);
        };

        tx.onerror = () => resolve(false);
      } catch (e) {
        resolve(false);
      }
    });
  }

  /**
   * Save a conversation
   */
  async function saveConversation(messages, metadata = {}) {
    const enabled = await isHistoryEnabled();
    if (!enabled) return null;

    const database = await initDB();
    if (!database) return null;

    return new Promise((resolve) => {
      try {
        const tx = database.transaction(STORE_CONVERSATIONS, 'readwrite');
        const store = tx.objectStore(STORE_CONVERSATIONS);

        const conversation = {
          timestamp: Date.now(),
          messages: messages,
          summary: generateSummary(messages),
          metadata: {
            ...metadata,
            userCity: metadata.userCity || null,
            programsDiscussed: metadata.programsDiscussed || [],
          },
        };

        const request = store.add(conversation);

        request.onsuccess = () => {
          resolve(request.result); // Returns the ID
        };

        request.onerror = () => resolve(null);
      } catch (e) {
        resolve(null);
      }
    });
  }

  /**
   * Update an existing conversation
   */
  async function updateConversation(id, messages, metadata = {}) {
    const enabled = await isHistoryEnabled();
    if (!enabled) return false;

    const database = await initDB();
    if (!database) return false;

    return new Promise((resolve) => {
      try {
        const tx = database.transaction(STORE_CONVERSATIONS, 'readwrite');
        const store = tx.objectStore(STORE_CONVERSATIONS);

        const request = store.get(id);

        request.onsuccess = () => {
          const conversation = request.result;
          if (conversation) {
            conversation.messages = messages;
            conversation.summary = generateSummary(messages);
            conversation.metadata = { ...conversation.metadata, ...metadata };
            conversation.lastUpdated = Date.now();

            store.put(conversation);
          }
          resolve(true);
        };

        request.onerror = () => resolve(false);
      } catch (e) {
        resolve(false);
      }
    });
  }

  /**
   * Get recent conversations
   */
  async function getRecentConversations(limit = 10) {
    const database = await initDB();
    if (!database) return [];

    return new Promise((resolve) => {
      try {
        const tx = database.transaction(STORE_CONVERSATIONS, 'readonly');
        const store = tx.objectStore(STORE_CONVERSATIONS);
        const index = store.index('timestamp');

        const conversations = [];
        const request = index.openCursor(null, 'prev'); // Newest first

        request.onsuccess = (event) => {
          const cursor = event.target.result;
          if (cursor && conversations.length < limit) {
            conversations.push(cursor.value);
            cursor.continue();
          } else {
            resolve(conversations);
          }
        };

        request.onerror = () => resolve([]);
      } catch (e) {
        resolve([]);
      }
    });
  }

  /**
   * Get a specific conversation by ID
   */
  async function getConversation(id) {
    const database = await initDB();
    if (!database) return null;

    return new Promise((resolve) => {
      try {
        const tx = database.transaction(STORE_CONVERSATIONS, 'readonly');
        const store = tx.objectStore(STORE_CONVERSATIONS);
        const request = store.get(id);

        request.onsuccess = () => resolve(request.result || null);
        request.onerror = () => resolve(null);
      } catch (e) {
        resolve(null);
      }
    });
  }

  /**
   * Delete a specific conversation
   */
  async function deleteConversation(id) {
    const database = await initDB();
    if (!database) return false;

    return new Promise((resolve) => {
      try {
        const tx = database.transaction(STORE_CONVERSATIONS, 'readwrite');
        const store = tx.objectStore(STORE_CONVERSATIONS);
        store.delete(id);

        tx.oncomplete = () => resolve(true);
        tx.onerror = () => resolve(false);
      } catch (e) {
        resolve(false);
      }
    });
  }

  /**
   * Clear all conversation history
   */
  async function clearAllHistory() {
    const database = await initDB();
    if (!database) return false;

    return new Promise((resolve) => {
      try {
        const tx = database.transaction(STORE_CONVERSATIONS, 'readwrite');
        const store = tx.objectStore(STORE_CONVERSATIONS);
        store.clear();

        tx.oncomplete = () => {
          document.dispatchEvent(new CustomEvent('carlHistoryCleared'));
          resolve(true);
        };

        tx.onerror = () => resolve(false);
      } catch (e) {
        resolve(false);
      }
    });
  }

  /**
   * Export all data (for user data portability)
   */
  async function exportData() {
    const conversations = await getRecentConversations(1000); // Get all
    const enabled = await isHistoryEnabled();

    return {
      exportDate: new Date().toISOString(),
      version: 1,
      historyEnabled: enabled,
      conversations: conversations,
    };
  }

  /**
   * Import data (for restoring from backup)
   */
  async function importData(data) {
    if (!data || !data.conversations) return false;

    const database = await initDB();
    if (!database) return false;

    return new Promise((resolve) => {
      try {
        const tx = database.transaction(STORE_CONVERSATIONS, 'readwrite');
        const store = tx.objectStore(STORE_CONVERSATIONS);

        // Clear existing and import new
        store.clear();

        for (const conv of data.conversations) {
          // Remove the id so it gets a new one
          const { id, ...convWithoutId } = conv;
          store.add(convWithoutId);
        }

        tx.oncomplete = () => resolve(true);
        tx.onerror = () => resolve(false);
      } catch (e) {
        resolve(false);
      }
    });
  }

  /**
   * Generate a summary from conversation messages
   */
  function generateSummary(messages) {
    if (!messages || messages.length === 0) return 'New conversation';

    // Find the first user message
    const firstUserMsg = messages.find((m) => m.role === 'user');
    if (firstUserMsg) {
      const content = firstUserMsg.content;
      // Truncate to ~50 chars
      if (content.length > 50) {
        return content.substring(0, 47) + '...';
      }
      return content;
    }

    return 'Conversation';
  }

  /**
   * Get conversation count
   */
  async function getConversationCount() {
    const database = await initDB();
    if (!database) return 0;

    return new Promise((resolve) => {
      try {
        const tx = database.transaction(STORE_CONVERSATIONS, 'readonly');
        const store = tx.objectStore(STORE_CONVERSATIONS);
        const request = store.count();

        request.onsuccess = () => resolve(request.result);
        request.onerror = () => resolve(0);
      } catch (e) {
        resolve(0);
      }
    });
  }

  // Initialize on load
  if (typeof window !== 'undefined') {
    initDB();
  }

  // Expose globally
  window.CarlStorage = {
    isHistoryEnabled,
    setHistoryEnabled,
    saveConversation,
    updateConversation,
    getRecentConversations,
    getConversation,
    deleteConversation,
    clearAllHistory,
    exportData,
    importData,
    getConversationCount,
  };
})();
