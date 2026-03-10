#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🔄 Initializing CTRL (Close The Running Loop) framework...');

const projectRoot = process.cwd();
const repoUrl = 'https://raw.githubusercontent.com/henrino3/ctrl/master';

async function downloadFile(remotePath, localName) {
  try {
    const res = await fetch(`${repoUrl}/${remotePath}`);
    if (!res.ok) throw new Error(`Failed to fetch ${remotePath}`);
    const text = await res.text();
    fs.writeFileSync(path.join(projectRoot, localName), text);
    console.log(`✅ Created ${localName}`);
  } catch (e) {
    console.error(`❌ Failed to create ${localName}: ${e.message}`);
  }
}

async function run() {
  await downloadFile('AGENTS.md', 'AGENTS.md');
  await downloadFile('TESTING.md', 'TESTING.md');
  await downloadFile('scripts/ctrl-bootstrap.sh', '.ctrl-bootstrap.sh');

  console.log('⚙️  Running setup script...');
  try {
    execSync('bash .ctrl-bootstrap.sh ' + projectRoot, { stdio: 'inherit' });
    fs.unlinkSync(path.join(projectRoot, '.ctrl-bootstrap.sh'));
    console.log('\n🎉 CTRL framework installed successfully!');
    console.log('Your AI agents will now automatically follow the Close The Running Loop protocol.');
  } catch (err) {
    console.error('❌ Failed to run bootstrap script.');
  }
}

run();
