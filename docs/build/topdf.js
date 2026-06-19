const { chromium } = require('/opt/node22/lib/node_modules/playwright');
const dir = __dirname;
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('file://' + dir + '/doc.html', { waitUntil: 'networkidle' });
  await page.waitForTimeout(500);
  await page.pdf({
    path: dir + '/../TCC-Pantry-Project-Overview.pdf',
    format: 'A4', printBackground: true,
    margin: { top: '0', bottom: '0', left: '0', right: '0' },
  });
  await browser.close();
  console.log('pdf written');
})();
