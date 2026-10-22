// Requires Node.js and sharp.
// From map_generator/: npm run render -- <profile-name|all>
const profiles = require('./map-profiles.cjs');
const { renderMap } = require('./parchment-renderer.cjs');

async function main() {
    const name = process.argv[2] ?? 'wilderness';
    if (process.argv.length > 3 || (name !== 'all' && !Object.hasOwn(profiles, name))) {
        throw new Error(`Usage: npm run render -- [${Object.keys(profiles).join('|')}|all]`);
    }
    const selected = name === 'all' ? Object.values(profiles) : [profiles[name]];
    for (const profile of selected) {
        await renderMap(profile);
    }
}

main().catch((error) => {
    console.error('Failed to render parchment map:', error);
    process.exitCode = 1;
});
