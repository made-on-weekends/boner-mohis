// Service worker to handle clicking on the extension icon.
// Opens the dashboard interface in a new browser tab.
chrome.action.onClicked.addListener(() => {
  chrome.tabs.create({
    url: chrome.runtime.getURL("index.html")
  });
});

// Listener for fetching external URLs (e.g. DESCO API) to bypass CORS restrictions
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'FETCH') {
    fetch(message.url)
      .then(async (response) => {
        let data = null;
        let text = '';
        if (response.ok) {
          try {
            data = await response.json();
          } catch {
            try {
              text = await response.text();
            } catch {
              text = 'Failed to read response body';
            }
          }
        } else {
          try {
            text = await response.text();
          } catch {
            text = `HTTP ${response.status}`;
          }
        }

        sendResponse({
          ok: response.ok,
          status: response.status,
          data: data,
          error: response.ok ? null : (text || `HTTP ${response.status}`)
        });
      })
      .catch((error) => {
        sendResponse({
          ok: false,
          status: 0,
          error: error.message || 'Network request failed'
        });
      });
    return true; // Keep the message channel open for asynchronous sendResponse
  }
});
