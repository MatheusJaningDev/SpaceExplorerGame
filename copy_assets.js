const fs = require('fs');
const path = require('path');

const srcDir = 'C:/Users/dudu_/.gemini/antigravity/brain/50cd038d-ebf2-4042-9ec5-34fbe52b9923';
const destDir = path.join(__dirname, 'assets', 'sprites');

const filesToCopy = {
  'pixel_space_background_1782491762166.png': 'space_background.png',
  'pixel_planet_1782492698526.png': 'planet.png',
  'pixel_planet_large_1_1782492737125.png': 'planet_large_1.png',
  'pixel_planet_large_2_1782492782746.png': 'planet_large_2.png'
};

console.log('Copying visual assets...');

for (const [srcName, destName] of Object.entries(filesToCopy)) {
  const srcPath = path.join(srcDir, srcName);
  const destPath = path.join(destDir, destName);
  const importPath = destPath + '.import';
  
  if (fs.existsSync(srcPath)) {
    fs.copyFileSync(srcPath, destPath);
    console.log(`Copied ${srcName} -> ${destName} (${fs.statSync(destPath).size} bytes)`);
    
    if (fs.existsSync(importPath)) {
      fs.unlinkSync(importPath);
      console.log(`Deleted old import metadata: ${destName}.import`);
    }
  } else {
    console.error(`Source asset not found: ${srcPath}`);
  }
}

console.log('Asset copy completed successfully!');
