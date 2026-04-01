const { test, expect } = require('@playwright/test');
const {
  enterEssayText,
  openInteractiveCourseView,
  openInteractivePracticeView,
  setEditorSelection,
  setPromptTextSelection,
  setTimerMinutes
} = require('./helpers/app');

const PROMPT_TITLES = [
  'Purpose of College',
  'AI tools in college coursework',
  'Purpose of Technology in Education',
  'Purpose of Higher Education',
  'Social Media and Free Expression'
];

test.describe('Interactive practice smoke', () => {
  test('loads interactive practice and supports prompt switching in launch state', async ({ page }) => {
    await openInteractiveCourseView(page);

    const options = await page.locator('#sim-prompt-select option').allTextContents();
    expect(options).toEqual(PROMPT_TITLES);

    await page.locator('#sim-prompt-select').selectOption('higher-education-purpose');
    await expect(page.locator('#sim-current-prompt-stat')).toContainText('Purpose of Higher Education');
    await expect(page.locator('#sim-issue-title')).toContainText('Purpose of Higher Education');

    const beforeRandom = await page.locator('#sim-prompt-select').inputValue();
    await page.locator('#sim-randomize-launch').click();
    await expect(page.locator('#sim-prompt-select')).not.toHaveValue(beforeRandom);
  });

  test('supports timer configuration, stage navigation, and view toggles', async ({ page }) => {
    await openInteractiveCourseView(page);

    await page.locator('#mode-exam').click();
    await setTimerMinutes(page, '#sim-prewrite-minutes', 7);
    await setTimerMinutes(page, '#sim-writing-minutes', 11);

    await page.locator('#sim-begin-section').click();
    await expect(page.locator('#sim-stage-prewrite.active')).toBeVisible();
    await expect(page.locator('#sim-prewrite-timer-label')).toContainText('07:00');

    await page.waitForTimeout(1400);
    await expect(page.locator('#sim-prewrite-timer-label')).not.toContainText('07:00');

    await page.locator('#sim-pause-section').click();
    const pausedLabel = await page.locator('#sim-prewrite-timer-label').textContent();
    await page.waitForTimeout(1200);
    await expect(page.locator('#sim-prewrite-timer-label')).toHaveText(pausedLabel || '');

    await page.locator('#sim-start-writing').click();
    await expect(page.locator('#sim-stage-writing.active')).toBeVisible();
    await expect(page.locator('#sim-writing-timer-label')).toContainText('11:00');
    await expect(page.locator('#sim-writing-directions-panel')).toBeVisible();

    await page.locator('#sim-go-to-question').click();
    await expect(page.locator('#sim-writing-prompt-panel')).toBeVisible();

    await page.locator('#sim-writing-only-view-2').click();
    await expect(page.locator('#sim-writing-question-panel')).toHaveClass(/lawhub-hidden/);

    await page.locator('#sim-reading-writing-view-2').click();
    await expect(page.locator('#sim-writing-question-panel')).not.toHaveClass(/lawhub-hidden/);
    await expect(page.locator('#sim-writing-prompt-panel')).toBeVisible();

    await page.locator('#sim-directions-view').click();
    await expect(page.locator('#sim-writing-directions-panel')).toBeVisible();
  });

  test('shows a five-minute warning and locks editing when time expires', async ({ page }) => {
    await openInteractivePracticeView(page);

    await page.evaluate(() => {
      localStorage.setItem('simStage', 'writing');
      localStorage.setItem('simViewMode', 'directions');
      localStorage.setItem('simTimerPhase', 'writing');
      localStorage.setItem('simTimerDuration', '600');
      localStorage.setItem('simTimerRemaining', '300');
      localStorage.setItem('simTimerEndTime', '0');
      localStorage.setItem('simTimerRunning', 'false');
      localStorage.setItem('simTimedSessionExpired', 'false');
      localStorage.setItem('simExpiredPhase', '');
    });
    await page.goto('/?view=practice&stage=writing', { waitUntil: 'domcontentloaded' });

    await expect(page.locator('#sim-stage-writing.active')).toBeVisible();
    await expect(page.locator('#sim-writing-warning')).toHaveClass(/visible/);
    await expect(page.locator('#sim-writing-warning')).toContainText('05:00');

    await page.evaluate(() => {
      localStorage.setItem('simTimedSessionExpired', 'true');
      localStorage.setItem('simExpiredPhase', 'writing');
    });
    await page.goto('/?view=practice&stage=writing', { waitUntil: 'domcontentloaded' });

    await expect(page.locator('#sim-time-expired-overlay')).toHaveClass(/visible/);
    await expect(page.locator('#sim-submit-essay')).toBeDisabled();
    await expect(page.locator('#sim-essay-mirror')).toHaveAttribute('contenteditable', 'false');
    await expect(page.locator('#sim-scratchpad-mirror')).toHaveJSProperty('readOnly', true);
  });

  test('reset clears only the current prompt state and unlocks exam mode', async ({ page }) => {
    await openInteractiveCourseView(page);

    await page.locator('#mode-exam').click();
    await page.locator('#sim-prompt-select').selectOption('higher-education-purpose');
    await page.locator('#sim-begin-section').click();
    await expect(page.locator('#sim-prompt-select')).toBeDisabled();

    await page.locator('#sim-scratchpad').fill('Rank perspectives 2 and 3, then test a balanced thesis.');
    await page.locator('#sim-drill-memory').fill('Revise mechanism before comparing alternatives.');
    await enterEssayText(page, '#sim-essay', 'A balanced university model better serves students because it preserves broad judgment while improving practical readiness.');

    await setPromptTextSelection(page, '#sim-question-pane', 'student debt, and job markets continue');
    await page.locator('#sim-stage-prewrite.active button[data-highlight-color="yellow"]').click();
    await expect(page.locator('#sim-question-pane mark.lawhub-highlight-yellow')).toHaveCount(1);

    await page.locator('#sim-start-writing').click();
    await page.locator('#sim-go-to-question').click();

    await page.locator('#sim-reset-prompt').click();
    await expect(page.locator('#sim-stage-launch.active')).toBeVisible();
    await expect(page.locator('#sim-prompt-select')).toBeEnabled();
    await expect(page.locator('#sim-scratchpad')).toHaveValue('');
    await expect(page.locator('#sim-drill-memory')).toHaveValue('');
    await expect(page.locator('#sim-prewrite-timer-label')).toContainText('15:00');
    await expect(page.locator('#sim-question-pane mark')).toHaveCount(0);
    await expect(page.locator('#sim-essay')).toContainText('');
  });

  test('editor tools, prompt highlight, and mirrored draft formatting work', async ({ page, browserName }) => {
    await openInteractiveCourseView(page);
    await page.locator('#sim-begin-section').click();

    await page.locator('#sim-stage-prewrite.active button[data-highlight-color="pink"]').click();
    await expect(page.locator('#sim-stage-prewrite.active button[data-highlight-color="pink"]')).toHaveClass(/active/);
    await setPromptTextSelection(page, '#sim-question-pane', 'failed to provide students with the practical skills necessary to succeed in an increasingly competitive and career focused society');
    await expect(page.locator('#sim-question-pane mark.lawhub-highlight-pink')).toHaveCount(1);
    await expect(page.locator('#sim-question-pane mark.lawhub-highlight-pink')).toHaveText('failed to provide students with the practical skills necessary to succeed in an increasingly competitive and career focused society');
    await expect(page.locator('#sim-stage-prewrite.active button[data-highlight-color="pink"]')).toHaveClass(/active/);
    await setPromptTextSelection(page, '#sim-question-pane', 'trends in the economy');
    await expect(page.locator('#sim-question-pane mark.lawhub-highlight-pink')).toHaveCount(2);

    await page.locator('#sim-stage-prewrite.active button[data-highlight-clear="selection"]').click();
    await expect(page.locator('#sim-stage-prewrite.active button[data-highlight-clear="selection"]')).toHaveClass(/active/);
    await setPromptTextSelection(page, '#sim-question-pane', 'failed to provide students with the practical skills necessary to succeed in an increasingly competitive and career focused society');
    await expect(page.locator('#sim-question-pane mark.lawhub-highlight-pink')).toHaveCount(1);
    await setPromptTextSelection(page, '#sim-question-pane', 'trends in the economy');
    await expect(page.locator('#sim-question-pane mark.lawhub-highlight-pink')).toHaveCount(0);

    await page.locator('#sim-stage-prewrite.active button[data-highlight-color="underline"]').click();
    await expect(page.locator('#sim-stage-prewrite.active button[data-highlight-color="underline"]')).toHaveClass(/active/);
    await setPromptTextSelection(page, '#sim-question-pane', 'a');
    await expect(page.locator('#sim-question-pane mark.lawhub-highlight-underline')).toHaveCount(1);
    await expect(page.locator('#sim-question-pane mark.lawhub-highlight-underline')).toHaveText('a');

    await expect(page.locator('#sim-question-pane')).not.toContainText('@@SIMHL');
    const promptText = await page.locator('#sim-question-pane').evaluate((node) => node.innerText);
    expect(promptText).not.toMatch(/[\u200B-\u200D\uFEFF]/);

    await page.locator('#sim-start-writing').click();
    await enterEssayText(page, '#sim-essay-mirror', 'Human-centered learning should remain central because judgment outlasts any temporary platform.');

    await page.locator('#sim-stage-writing.active button[data-editor-command="underline"]').click();
    await expect(page.locator('#sim-stage-writing.active button[data-editor-command="underline"]')).toHaveClass(/active/);
    await setEditorSelection(page, '#sim-essay-mirror', 'Human-centered');
    await expect(page.locator('#sim-stage-writing.active button[data-editor-command="underline"]')).toHaveClass(/active/);
    await setEditorSelection(page, '#sim-essay-mirror', 'judgment');

    await setEditorSelection(page, '#sim-essay-mirror', 'remain');
    await page.locator('#sim-stage-writing.active button[data-editor-command="bold"]').click();

    await setEditorSelection(page, '#sim-essay-mirror', 'central');
    await page.locator('#sim-stage-writing.active button[data-editor-command="italic"]').click();

    const writingHtml = await page.locator('#sim-essay-mirror').evaluate((node) => node.innerHTML);
    const prewriteHtml = await page.locator('#sim-essay').evaluate((node) => node.innerHTML);
    const writingText = await page.locator('#sim-essay-mirror').evaluate((node) => node.textContent);
    const prewriteText = await page.locator('#sim-essay').evaluate((node) => node.textContent);

    expect(writingHtml).not.toEqual('');
    expect(prewriteText).toEqual(writingText);
    if (browserName !== 'webkit') {
      expect(prewriteHtml).toEqual(writingHtml);
    } else {
      expect(prewriteHtml.toLowerCase()).toMatch(/underline|<u|font-weight|<b|<strong|font-style|<i/);
    }
    expect(writingHtml.toLowerCase()).toMatch(/underline|<u|font-weight|<b|<strong|font-style|<i/);
    expect((writingHtml.toLowerCase().match(/underline|<u|text-decoration/g) || []).length).toBeGreaterThan(0);
    expect(writingHtml).not.toMatch(/[\u200B-\u200D\uFEFF]/);

    if (browserName === 'webkit') {
      await expect(page.locator('#sim-essay-mirror')).toContainText('temporary platform');
    }
  });

  test('persists prompt-specific work across reload and keeps prompt isolation', async ({ page }) => {
    await openInteractiveCourseView(page);

    await page.locator('#sim-begin-section').click();
    await page.locator('#sim-prompt-select').selectOption('career-prep');
    await page.locator('#sim-scratchpad').fill('Career-prep scratch notes');
    await page.locator('#sim-drill-memory').fill('Career drill memory');
    await enterEssayText(page, '#sim-essay', 'Career essay paragraph one.');
    await page.locator('input[data-sim-check="mechanism"]').check();

    await page.locator('#sim-prompt-select').selectOption('social-media-free-expression');
    await expect(page.locator('#sim-scratchpad')).toHaveValue('');
    await expect(page.locator('#sim-drill-memory')).toHaveValue('');
    await page.locator('#sim-scratchpad').fill('Speech scratch notes');
    await enterEssayText(page, '#sim-essay', 'Speech essay paragraph one.');

    await page.locator('#sim-prompt-select').selectOption('career-prep');
    await expect(page.locator('#sim-scratchpad')).toHaveValue('Career-prep scratch notes');
    await expect(page.locator('#sim-drill-memory')).toHaveValue('Career drill memory');
    await expect(page.locator('input[data-sim-check="mechanism"]')).toBeChecked();
    await expect(page.locator('#sim-essay')).toContainText('Career essay paragraph one.');

    await page.locator('#sim-start-writing').click();
    await expect(page.locator('#sim-scratch-shell')).not.toHaveClass(/open/);
    await page.locator('#sim-scratch-toggle').click({ force: true });
    await expect(page.locator('#sim-scratch-shell')).toHaveClass(/open/);
    await expect(page.locator('#sim-scratchpad-mirror')).toHaveValue('Career-prep scratch notes');

    await page.reload();
    await expect(page.locator('#sim-prompt-select')).toHaveValue('career-prep');
    await expect(page.locator('#sim-scratchpad-mirror')).toHaveValue('Career-prep scratch notes');
    await expect(page.locator('#sim-drill-memory')).toHaveValue('Career drill memory');

    await page.locator('#sim-reset-prompt').click();
    await page.locator('#sim-begin-section').click();
    await page.locator('#sim-prompt-select').selectOption('social-media-free-expression');
    await expect(page.locator('#sim-scratchpad')).toHaveValue('Speech scratch notes');
    await expect(page.locator('#sim-essay')).toContainText('Speech essay paragraph one.');
  });

  test('practice pop-out view exposes shell controls and sample response behavior', async ({ page }) => {
    await openInteractivePracticeView(page);
    await expect(page.locator('#sim-return-course')).toBeVisible();
    await expect(page.locator('#sim-shell-reset')).toBeVisible();

    await page.locator('#sim-shell-prompt-select').selectOption('ai-coursework');
    await page.locator('#sim-begin-section').click();
    await page.locator('#sim-start-writing').click();
    await page.locator('#sim-go-to-question').click();
    await page.locator('#sim-sample-response-toggle').click();
    await expect(page.locator('#sim-sample-response')).toContainText('No sample response is attached');

    await page.locator('#sim-shell-reset').click();
    await expect(page.locator('#sim-stage-launch.active')).toBeVisible();
    await expect(page.locator('#sim-shell-prompt-select')).toBeEnabled();
  });
});
