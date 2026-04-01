const { expect } = require('@playwright/test');

async function openFresh(page, path = '/') {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.evaluate(() => localStorage.clear());
  await page.goto(path, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('domcontentloaded');
}

async function openTab(page, tabId) {
  await page.locator(`.tab-button[data-tab="${tabId}"]`).click({ force: true });
  await expect(page.locator(`section#${tabId}.tab-panel.active`)).toBeVisible();
}

async function openInteractiveCourseView(page) {
  await openFresh(page, '/');
  await openTab(page, 'simulator');
  await expect(page.locator('#sim-stage-launch.active')).toBeVisible();
}

async function openInteractivePracticeView(page) {
  await openFresh(page, '/?view=practice');
  await expect(page.locator('#sim-stage-launch.active')).toBeVisible();
}

async function setPromptTextSelection(page, selector, snippet) {
  await page.evaluate(({ selector, snippet }) => {
    const root = document.querySelector(selector);
    if (!root) {
      throw new Error(`Missing selection root: ${selector}`);
    }
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    while (walker.nextNode()) {
      const node = walker.currentNode;
      const text = node.textContent || '';
      const index = text.indexOf(snippet);
      if (index >= 0) {
        const range = document.createRange();
        range.setStart(node, index);
        range.setEnd(node, index + snippet.length);
        const selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
        document.dispatchEvent(new Event('selectionchange'));
        root.dispatchEvent(new MouseEvent('mouseup', { bubbles: true }));
        return;
      }
    }
    throw new Error(`Snippet not found: ${snippet}`);
  }, { selector, snippet });
}

async function setEditorSelection(page, selector, snippet) {
  await page.evaluate(({ selector, snippet }) => {
    const root = document.querySelector(selector);
    if (!root) {
      throw new Error(`Missing editor: ${selector}`);
    }
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    while (walker.nextNode()) {
      const node = walker.currentNode;
      const text = node.textContent || '';
      const index = text.indexOf(snippet);
      if (index >= 0) {
        const range = document.createRange();
        range.setStart(node, index);
        range.setEnd(node, index + snippet.length);
        const selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
        root.focus();
        return;
      }
    }
    throw new Error(`Editor snippet not found: ${snippet}`);
  }, { selector, snippet });
}

async function enterEssayText(page, selector, text) {
  const target = page.locator(selector);
  if (await target.isVisible()) {
    await target.click();
  }
  await page.evaluate(({ selector, text }) => {
    const editor = document.querySelector(selector);
    editor.innerHTML = '';
    const lines = String(text).split(/\n\n/);
    editor.innerHTML = lines.map((paragraph) => `<div>${paragraph.replace(/\n/g, '<br>')}</div>`).join('');
    editor.dispatchEvent(new InputEvent('input', { bubbles: true, inputType: 'insertText', data: text }));
  }, { selector, text });
}

async function setTimerMinutes(page, fieldSelector, minutes) {
  const input = page.locator(fieldSelector);
  await input.click();
  await input.fill(String(minutes));
  await input.blur();
}

async function visibleWithin(page, parentSelector, childSelector) {
  return page.locator(`${parentSelector} ${childSelector}`);
}

module.exports = {
  enterEssayText,
  openFresh,
  openInteractiveCourseView,
  openInteractivePracticeView,
  openTab,
  setEditorSelection,
  setPromptTextSelection,
  setTimerMinutes,
  visibleWithin
};
