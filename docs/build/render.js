const { chromium } = require('/opt/node22/lib/node_modules/playwright');
const fs = require('fs');
const dir = __dirname;

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 3,
  });
  const screens = ['onboarding', 'food', 'drinks', 'cart', 'orders', 'admin'];
  for (const s of screens) {
    const page = await ctx.newPage();
    await page.goto('file://' + dir + '/screen_' + s + '.html');
    await page.waitForTimeout(350);
    await page.screenshot({ path: dir + '/shots/' + s + '.png' });
    await page.close();
    console.log('captured', s);
  }
  await browser.close();
})();
