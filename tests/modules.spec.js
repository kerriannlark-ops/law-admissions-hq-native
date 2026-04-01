const { test, expect } = require('@playwright/test');
const { openFresh, openTab } = require('./helpers/app');

test.describe('Learning module smoke', () => {
  test.skip(({ browserName }) => browserName === 'webkit', 'Module smoke runs in Chromium; interactive suite covers WebKit sanity.');


  test('curriculum dashboard renders three sprint days and routes into the course', async ({ page }) => {
    await openFresh(page, '/');
    await expect(page.locator('#curriculum-next-lesson')).toBeVisible();
    await expect(page.locator('.curriculum-day-card')).toHaveCount(3);
    await expect(page.locator('#curriculum-quickstart-row')).toBeVisible();
    await expect(page.locator('#curriculum-study-library-panel')).toBeVisible();
    await expect(page.locator('#curriculum-resource-grid .curriculum-resource-card')).toHaveCount(4);
    await expect(page.locator('#curriculum-study-paths .curriculum-path-card')).toHaveCount(5);

    await page.locator('[data-open-day="day1"]').click();
    await expect(page.locator('#mechanism.tab-panel.active')).toBeVisible();

    await openTab(page, 'overview');
    await page.locator('#curriculum-resume').click();
    await expect(page.locator('#mechanism.tab-panel.active')).toBeVisible();

    await openTab(page, 'progress');
    await expect(page.locator('#curriculum-summary-grid')).toBeVisible();
    await expect(page.locator('#curriculum-progress-lessons .lesson-card')).toHaveCount(18);
  });

  test('overview quick starts and Units 1-2 inputs persist', async ({ page }) => {
    await openFresh(page, '/');
    await expect(page.locator('#overview.tab-panel.active')).toBeVisible();

    await page.locator('.jump-button[data-target="mechanism"]').click();
    await expect(page.locator('#mechanism.tab-panel.active')).toBeVisible();

    await page.locator('#mechanism-response').fill('Integrating career preparation helps because students practice applying abstract learning to real choices.');
    await page.locator('[data-mechanism-verb="facilitates"]').click();
    await expect(page.locator('#mechanism-response')).toHaveValue(/facilitates/);
    await page.locator('#mechanism input[type="checkbox"]').nth(0).check();
    await page.locator('#mechanism .rating-button[data-rating="strong"]').click();

    await openTab(page, 'inference');
    await page.locator('#inference-a').fill('This matters because labor-market volatility makes adaptable preparation more valuable than static specialization.');
    await page.locator('#inference-b').fill('This matters because students need judgment about where and how to apply their education.');
    await page.locator('#inference-a').click();
    await page.locator('[data-insert-text="suggests"][data-insert-target="inference-a"]').click();
    await expect(page.locator('#inference-a')).toHaveValue(/suggests/);
    await page.locator('#toggle-model-answer').click();
    await expect(page.locator('#model-answer-box')).toBeVisible();
    await page.locator('#toggle-model-answer').click();
    await expect(page.locator('#model-answer-box')).toBeHidden();

    await page.reload();
    await expect(page.locator('#inference-a')).toHaveValue(/labor-market volatility/);
    await openTab(page, 'mechanism');
    await expect(page.locator('#mechanism-response')).toHaveValue(/Integrating career preparation helps/);
    await expect(page.locator('#mechanism input[type="checkbox"]').nth(0)).toBeChecked();
    await expect(page.locator('#mechanism .rating-button[data-rating="strong"]')).toHaveClass(/active/);
  });

  test('paragraph lab, Toulmin map, and sample builders render useful output', async ({ page }) => {
    await openFresh(page, '/');
    await openTab(page, 'paragraph');

    const builderValues = {
      '#builder-claim': 'Colleges best serve students when they integrate career preparation.',
      '#builder-mechanism': 'Integration turns broad learning into usable judgment.',
      '#builder-evidence': 'Perspective 1 emphasizes employability and opportunity.',
      '#builder-inference': 'This matters because usable judgment travels across changing job markets.',
      '#builder-counter': 'Critics worry that career focus can thin out intellectual exploration.',
      '#builder-limitation': 'That concern is strongest only when career training replaces broader inquiry.',
      '#builder-conclusion': 'An integrated model is stronger because it preserves breadth while adding practical payoff.'
    };

    for (const [selector, value] of Object.entries(builderValues)) {
      await page.locator(selector).fill(value);
    }
    await page.locator('#compile-paragraph').click();
    await expect(page.locator('#paragraph-preview')).toContainText('integrate career preparation');
    await expect(page.locator('#transition-detail')).not.toBeEmpty();
    await page.locator('[data-transition-target="counter"]').click();
    await expect(page.locator('#transition-detail')).toContainText(/counter|limit/i);
    await page.locator('[data-skeleton-target="inference"]').click();
    await expect(page.locator('#skeleton-detail')).toContainText(/This matters because|inference/i);

    await openTab(page, 'toulmin');
    await expect(page.locator('.map-card')).toHaveCount(6);
    await expect(page.locator('#model-detail')).not.toBeEmpty();
    await page.locator('[data-model-target="weak"]').click();
    await expect(page.locator('#model-detail')).toContainText(/weak|summary|vague/i);

    await openTab(page, 'sample');
    await page.locator('#thesis-tension').fill('broader inquiry still matters');
    await page.locator('#thesis-position').fill('universities should integrate career preparation into broader learning');
    await page.locator('#thesis-group').fill('students and civic life');
    await page.locator('#thesis-mechanism').fill('integration connects intellectual breadth to practical adaptability');
    await page.locator('#thesis-limitation').fill('when it supplements rather than replaces general education');
    await page.locator('#thesis-position').click();
    await page.locator('[data-insert-text="better serves"][data-insert-target="thesis-position"]').click();
    await expect(page.locator('#thesis-position')).toHaveValue(/better serves/);
    await page.locator('#build-thesis').click();
    await expect(page.locator('#thesis-preview')).toContainText(/Although broader inquiry still matters/);

    await page.locator('#scope-issue').fill('whether universities should emphasize career preparation');
    await page.locator('#scope-population').fill('students choosing among educational models');
    await page.locator('#scope-condition').fill('under rising tuition and unstable labor markets');
    await page.locator('#scope-comparison').fill('career-first and integrated models');
    await page.locator('#scope-criterion').fill('which approach better protects adaptability and judgment');
    await page.locator('#build-scope').click();
    await expect(page.locator('#scope-preview')).toContainText(/This essay evaluates/);

    await page.locator('#intro-context').fill('Higher education now sits between economic pressure and intellectual aspiration.');
    await page.locator('#intro-tension').fill('Students need employable skills without reducing college to technical training.');
    await page.locator('#intro-thesis-line').fill('Universities should preserve broad learning while integrating practical preparation.');
    await page.locator('#intro-tension').click();
    await page.locator('[data-insert-text="raises"][data-insert-target="intro-tension"]').click();
    await expect(page.locator('#intro-tension')).toHaveValue(/raises/);
    await page.locator('#build-intro').click();
    await expect(page.locator('#intro-preview')).toContainText(/Higher education now sits between/);

    await page.locator('[data-outline-target="counter"]').click();
    await expect(page.locator('#outline-detail')).toContainText(/counter|limitation/i);

    await page.locator('#coach-lens').selectOption('essay');
    await page.locator('#coach-input').fill('Universities should integrate practical preparation because broad learning becomes more usable. However, this objection has force only when career training replaces inquiry.');
    await page.locator('#analyze-coach').click();
    await expect(page.locator('#coach-score-value')).not.toHaveText('0/0');
    await expect(page.locator('#coach-results')).not.toBeEmpty();
  });

  test('timed lab controls and course tracker persist', async ({ page }) => {
    await openFresh(page, '/');
    await openTab(page, 'timed');

    await expect(page.locator('#timer-readout')).toHaveText('23:00');
    await page.locator('[data-testid="timed-start-23"]').click();
    await expect.poll(async () => page.evaluate(() => localStorage.getItem('timerRunning'))).toBe('true');
    await expect.poll(async () => page.evaluate(() => Number(localStorage.getItem('timerEndTime') || '0'))).toBeGreaterThan(0);

    await page.locator('#pause-timer').click();
    await expect.poll(async () => page.evaluate(() => localStorage.getItem('timerRunning'))).toBe('false');

    await page.locator('#reset-timer').click();
    await expect(page.locator('#timer-readout')).toHaveText('23:00');

    await page.locator('#timed-prewrite-notes').fill('criterion | thesis | body 1 | body 2 | counter');
    await page.locator('#timed-essay-draft').fill('This draft is long enough to update the pace report with usable words for the writing block.');
    await expect(page.locator('#pace-prewrite-words')).not.toHaveText('0');
    await expect(page.locator('#pace-essay-words')).not.toHaveText('0');

    await openTab(page, 'progress');
    const interactiveToggle = page.locator('[data-progress-key="progressInteractive"]');
    await interactiveToggle.click();
    await expect(interactiveToggle).toHaveClass(/active/);

    await page.reload();
    await openTab(page, 'timed');
    await expect(page.locator('#timed-prewrite-notes')).toHaveValue(/criterion/);
    await expect(page.locator('#timed-essay-draft')).toHaveValue(/pace report/);

    await openTab(page, 'progress');
    await expect(page.locator('[data-progress-key="progressInteractive"]')).toHaveClass(/active/);
    await expect(page.locator('[data-progress-badge="progressInteractive"]')).toContainText('Completed');
  });

  test('counter verb bank inserts into the correct counter drill fields', async ({ page }) => {
    await openFresh(page, '/');
    await openTab(page, 'counter');

    await page.locator('#counterWeakOne').click();
    await page.locator('[data-insert-text="acknowledges"][data-insert-target="counterWeakOne"]').click();
    await expect(page.locator('#counterWeakOne')).toHaveValue(/acknowledges/);

    await page.locator('#counterWeakTwo').click();
    await page.locator('[data-insert-text="qualifies"][data-insert-target="counterWeakTwo"]').click();
    await expect(page.locator('#counterWeakTwo')).toHaveValue(/qualifies/);
  });
});
