const fs = require('fs');
const path = require('path');
const cheerio = require('cheerio');
const JavaScriptObfuscator = require('javascript-obfuscator');
const yaml = require('js-yaml');

const config = yaml.load(fs.readFileSync('config/encrypted-pages.yml', 'utf8'));
const pages = config.pages;
const siteDir = 'build';

pages.forEach(page => {
  const filePath = path.join(siteDir, page);
  if (!fs.existsSync(filePath)) {
    console.error(`File not found: ${filePath}`);
    return;
  }
  const html = fs.readFileSync(filePath, 'utf8');
  const $ = cheerio.load(html);
  $('script').each((i, elem) => {
    const scriptText = $(elem).html();
    const scriptType = $(elem).attr('type');
    
    // Skip if no content
    if (!scriptText || !scriptText.trim()) {
      return;
    }
    
    // Skip JSON-LD and other data types
    if (scriptType === 'application/ld+json' || 
        scriptType === 'application/json' ||
        scriptType === 'text/json') {
      return;
    }
    
    // Skip external scripts (no inline content)
    if ($(elem).attr('src')) {
      return;
    }
    
    // Skip if it's likely not JavaScript
    if (scriptText.trim().startsWith('{') && scriptText.trim().endsWith('}')) {
      return;
    }

    try {
      const obfuscated = JavaScriptObfuscator.obfuscate(scriptText).getObfuscatedCode();
      $(elem).html(obfuscated);
      console.log(`Obfuscated script in: ${filePath}`);
    } catch (error) {
      console.error(`Failed to obfuscate script in ${filePath}:`, error.message);
    }
  });
  fs.writeFileSync(filePath, $.html());
  console.log(`Obfuscated: ${filePath}`);
});