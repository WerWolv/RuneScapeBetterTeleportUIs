// Shared rendering pipeline. Each invocation has its own dimensions and seed.
const path = require('node:path');
const fs = require('node:fs/promises');
const sharp = require('sharp');

async function renderMap(profile) {
    const WIDTH = profile.width;
    const HEIGHT = profile.height;
    const PIXEL_COUNT = WIDTH * HEIGHT;
    const RGB_CHANNELS = 3;
    const RANDOM_SEED = 73841;
    const INPUT_DIRECTORY = path.resolve(__dirname, '../templates');
    const OUTPUT_DIRECTORY = path.resolve(__dirname, '../../plugin/resources/backgrounds');
    const INPUT_PATH = path.join(INPUT_DIRECTORY, profile.input);
    const OUTPUT_PATH = path.join(OUTPUT_DIRECTORY, profile.output);

    const PALETTE = {
        sourceOcean: [137, 146, 159],
        paper: [242, 226, 186],
        oceanStain: [175, 143, 91],
        oceanShore: [112, 141, 135],
        oceanFoam: [255, 246, 215],
        lowTerrain: [174, 143, 98],
        highTerrain: [224, 199, 154],
        snow: [247, 239, 216],
        terrainShadow: [103, 83, 53],
        landmarkInk: [91, 68, 42],
        scorch: [113, 83, 55],
        lavaOutline: [89, 54, 31],
        lavaBank: [119, 66, 34],
        lavaCenter: [213, 148, 65],
        lavaHighlight: [239, 190, 104],
        inlandStain: [157, 137, 98],
        vegetation: [146, 144, 100],
        landShore: [103, 128, 116],
        landFoam: [249, 228, 185],
        coastalBank: [145, 119, 76],
        agedEdge: [104, 64, 26],
        ...profile.palette,
    };

    const COMPASS = profile.compass;
    const SHORELINE_SCALE = profile.shorelineScale ?? 1;

    // Pixel helpers ---------------------------------------------------------------

    function clamp(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, value));
    }

    function mixColors(from, to, amount) {
        const weight = clamp(amount, 0, 1);
        return from.map((channel, index) => channel + (to[index] - channel) * weight);
    }

    function readRgb(pixels, index) {
        const offset = index * RGB_CHANNELS;
        return [pixels[offset], pixels[offset + 1], pixels[offset + 2]];
    }

    function brightness([red, green, blue]) {
        // Intentionally unweighted: these thresholds were tuned to the source map.
        return (red + green + blue) / 3;
    }

    function colorSpread([red, green, blue]) {
        return Math.max(red, green, blue) - Math.min(red, green, blue);
    }

    function rawImage(buffer, channels) {
        return sharp(buffer, { raw: { width: WIDTH, height: HEIGHT, channels } });
    }

    async function blurMask(mask, radius) {
        return rawImage(mask, 1).blur(radius).greyscale().raw().toBuffer();
    }

    function sampleBilinear(mask, x, y) {
        // Leave room for the right/bottom neighbours used by interpolation.
        const safeX = clamp(x, 0, WIDTH - 1.001);
        const safeY = clamp(y, 0, HEIGHT - 1.001);
        const column = Math.floor(safeX);
        const row = Math.floor(safeY);
        const fractionX = safeX - column;
        const fractionY = safeY - row;
        const index = row * WIDTH + column;

        return (
            mask[index] * (1 - fractionX) * (1 - fractionY) +
            mask[index + 1] * fractionX * (1 - fractionY) +
            mask[index + WIDTH] * (1 - fractionX) * fractionY +
            mask[index + WIDTH + 1] * fractionX * fractionY
        );
    }

    // Deterministic paper and pen textures -----------------------------------------

    function createRandom(seed) {
        let state = seed;
        return function random() {
            state = (Math.imul(state, 1664525) + 1013904223) >>> 0;
            return state / 4294967296;
        };
    }

    async function createNoise(random, width, height, blurRadius = 0) {
        const pixels = Buffer.alloc(width * height);
        for (let index = 0; index < pixels.length; index++) {
            pixels[index] = Math.floor(random() * 256);
        }

        let image = sharp(pixels, { raw: { width, height, channels: 1 } }).resize(WIDTH, HEIGHT, {
            kernel: 'cubic',
        });
        if (blurRadius > 0) {
            image = image.blur(blurRadius);
        }
        return image.greyscale().raw().toBuffer();
    }

    async function createTextures() {
        const random = createRandom(RANDOM_SEED);
        // Keep this order stable: all textures consume the same seeded sequence.
        const fine = await createNoise(random, WIDTH, HEIGHT);
        const broad = await createNoise(random, 18, 15, 12);
        const medium = await createNoise(random, 110, 94, 2);
        const penX = await createNoise(random, 95, 81, 1);
        const penY = await createNoise(random, 95, 81, 1);
        const penPressure = await createNoise(random, 175, 149, 0.7);
        return { fine, broad, medium, penX, penY, penPressure };
    }

    // Ocean and coastline ---------------------------------------------------------

    function findOcean(source) {
        const candidates = new Uint8Array(PIXEL_COUNT);
        for (let index = 0; index < PIXEL_COUNT; index++) {
            const [red, green, blue] = readRgb(source, index);
            const difference =
                Math.abs(red - PALETTE.sourceOcean[0]) +
                Math.abs(green - PALETTE.sourceOcean[1]) +
                Math.abs(blue - PALETTE.sourceOcean[2]);
            candidates[index] = difference < profile.oceanTolerance ? 1 : 0;
        }

        // Only border-connected water is sea. Grey inland buildings must not acquire
        // blue shorelines, and islands must remain excluded from the ocean mask.
        const ocean = new Uint8Array(PIXEL_COUNT);
        const queue = new Int32Array(PIXEL_COUNT);
        let head = 0;
        let tail = 0;

        function enqueue(index) {
            if (candidates[index] && !ocean[index]) {
                ocean[index] = 1;
                queue[tail++] = index;
            }
        }

        for (let x = 0; x < WIDTH; x++) {
            enqueue(x);
            enqueue((HEIGHT - 1) * WIDTH + x);
        }
        for (let y = 0; y < HEIGHT; y++) {
            enqueue(y * WIDTH);
            enqueue(y * WIDTH + WIDTH - 1);
        }
        while (head < tail) {
            const index = queue[head++];
            const x = index % WIDTH;
            if (x > 0) enqueue(index - 1);
            if (x < WIDTH - 1) enqueue(index + 1);
            if (index >= WIDTH) enqueue(index - WIDTH);
            if (index < WIDTH * (HEIGHT - 1)) enqueue(index + WIDTH);
        }
        return ocean;
    }

    function measureCoastDistance(ocean) {
        const distance = new Float32Array(PIXEL_COUNT).fill(10000);
        for (let y = 1; y < HEIGHT - 1; y++) {
            for (let x = 1; x < WIDTH - 1; x++) {
                const index = y * WIDTH + x;
                const isCoast =
                    ocean[index] !== ocean[index - 1] ||
                    ocean[index] !== ocean[index + 1] ||
                    ocean[index] !== ocean[index - WIDTH] ||
                    ocean[index] !== ocean[index + WIDTH];
                if (isCoast) distance[index] = 0;
            }
        }

        // Two-pass approximate distance field. Preserve the tuned diagonal cost
        // and neighbour set; this is for shading, not the compass clearance check.
        const diagonalCost = 1.414;
        for (let y = 1; y < HEIGHT; y++) {
            for (let x = 1; x < WIDTH; x++) {
                const index = y * WIDTH + x;
                distance[index] = Math.min(
                    distance[index],
                    distance[index - 1] + 1,
                    distance[index - WIDTH] + 1,
                    distance[index - WIDTH - 1] + diagonalCost,
                );
            }
        }
        for (let y = HEIGHT - 2; y >= 0; y--) {
            for (let x = WIDTH - 2; x >= 0; x--) {
                const index = y * WIDTH + x;
                distance[index] = Math.min(
                    distance[index],
                    distance[index + 1] + 1,
                    distance[index + WIDTH] + 1,
                    distance[index + WIDTH + 1] + diagonalCost,
                );
            }
        }
        return distance;
    }

    // Lava channels and hand-inked landmarks --------------------------------------

    async function createLavaMasks(source, ocean) {
        const mask = Buffer.alloc(PIXEL_COUNT);
        for (let index = 0; index < PIXEL_COUNT; index++) {
            const [red, green, blue] = readRgb(source, index);
            const isLava = red > 105 && green > 95 && blue < green * 0.62 && red > green * 0.85;
            if (profile.lava && !ocean[index] && isLava) mask[index] = 255;
        }

        const edge = await blurMask(mask, 0.65);
        const core = await blurMask(mask, 1.8);
        const scorch = await blurMask(mask, 5);
        const outline = Buffer.alloc(PIXEL_COUNT);

        // Dilate the softened edge by one pixel, then subtract it to leave a bank.
        for (let y = 1; y < HEIGHT - 1; y++) {
            for (let x = 1; x < WIDTH - 1; x++) {
                const index = y * WIDTH + x;
                let outer = 0;
                for (let dy = -1; dy <= 1; dy++) {
                    for (let dx = -1; dx <= 1; dx++) {
                        outer = Math.max(outer, edge[index + dy * WIDTH + dx]);
                    }
                }
                outline[index] = Math.max(0, outer - edge[index]);
            }
        }
        return { edge, core, scorch, outline };
    }

    function extractLandmarks(source, smoothed, ocean, coastDistance, lava) {
        const mask = Buffer.alloc(PIXEL_COUNT);
        for (let y = 1; y < HEIGHT - 1; y++) {
            for (let x = 1; x < WIDTH - 1; x++) {
                const index = y * WIDTH + x;
                const color = readRgb(source, index);
                const localBrightness = brightness(readRgb(smoothed, index));
                const isLandmark =
                    !ocean[index] &&
                    coastDistance[index] > 7 &&
                    lava.core[index] < 12 &&
                    colorSpread(color) < 40;
                if (isLandmark) {
                    const contrast = (brightness(color) - localBrightness - 8) / 48;
                    mask[index] = Math.round(clamp(contrast, 0, 1) * 255);
                }
            }
        }
        return mask;
    }

    async function drawLandmarkInk(mask, textures) {
        const strokes = Buffer.alloc(PIXEL_COUNT);
        for (let y = 0; y < HEIGHT; y++) {
            for (let x = 0; x < WIDTH; x++) {
                const index = y * WIDTH + x;
                const offsetX = ((textures.penX[index] - 128) / 128) * 1.65;
                const offsetY = ((textures.penY[index] - 128) / 128) * 1.65;
                const pressure = 0.78 + (textures.penPressure[index] / 255) * 0.38;
                const mainStroke = sampleBilinear(mask, x + offsetX, y + offsetY);
                const retracedStroke = sampleBilinear(mask, x + offsetX + 0.85, y + offsetY - 0.55) * 0.18;
                strokes[index] = Math.min(255, Math.round(Math.max(mainStroke, retracedStroke) * pressure));
            }
        }

        // Only the ink wanders; the geography and teleport coordinates stay aligned.
        const feathering = await blurMask(strokes, 0.65);
        return { strokes, feathering };
    }

    // Parchment painting ----------------------------------------------------------

    async function createDistrictWashes() {
        const washes = [];
        for (const district of profile.districtWashes ?? []) {
            const points = district.points.map(([x, y]) => `${x},${y}`).join(' ');
            const svg = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}">
                <rect width="100%" height="100%" fill="black"/>
                <polygon points="${points}" fill="white"/>
            </svg>`);
            const mask = await sharp(svg).flatten({ background: '#000000' })
                .blur(district.feather ?? 12).greyscale().raw().toBuffer();
            washes.push({ ...district, mask });
        }
        return washes;
    }

    function paintDistrictWashes(color, index, districts, textures) {
        for (const district of districts) {
            // Uneven pigment deposit and soft edges, with paper grain added later.
            const pigment = 0.8 + textures.broad[index] / 255 * 0.3
                + (textures.medium[index] - 128) / 128 * 0.1;
            color = mixColors(color, district.color, district.mask[index] / 255 * district.opacity * pigment);
        }
        return color;
    }

    function paintOcean(distance) {
        distance /= SHORELINE_SCALE;
        let color = mixColors(PALETTE.paper, PALETTE.oceanStain, 0.25 * Math.exp(-distance / 11));
        if (distance < 1.2) {
            color = mixColors(color, PALETTE.oceanShore, 0.72);
        } else if (distance < 3) {
            color = mixColors(color, PALETTE.oceanFoam, 0.8);
        }
        return color;
    }

    function paintLava(color, index, lava, textures) {
        const coverage = lava.edge[index] / 255;
        color = mixColors(color, PALETTE.scorch, (lava.scorch[index] / 255) * 0.32);
        color = mixColors(color, PALETTE.lavaOutline, (lava.outline[index] / 255) * 0.95);
        if (coverage > 0.015) {
            const core = clamp((lava.core[index] / 255 - 0.25) / 0.65, 0, 1);
            let fill = mixColors(PALETTE.lavaBank, PALETTE.lavaCenter, core);
            fill = mixColors(fill, PALETTE.lavaHighlight, Math.pow(core, 3) * 0.48);
            const variation =
                ((textures.medium[index] - 128) / 128) * 10 + ((textures.fine[index] - 128) / 128) * 3;
            fill = fill.map((channel) => channel + variation);
            color = mixColors(color, fill, coverage * 0.9);
        }
        return color;
    }

    function paintLandmarkInk(color, index, ink) {
        const coverage = Math.max(ink.strokes[index] / 255, (ink.feathering[index] / 255) * 1.55);
        return mixColors(color, PALETTE.landmarkInk, coverage * profile.landmarkOpacity);
    }

    function paintLand(index, source, smoothed, coastDistance, lava, ink, textures, districts) {
        const sourceColor = readRgb(source, index);
        const smoothColor = readRgb(smoothed, index);
        const [red, green, blue] = sourceColor;
        const localBrightness = brightness(smoothColor);
        const relief = clamp((localBrightness - 58) / 170, 0, 1);
        let color = mixColors(PALETTE.lowTerrain, PALETTE.highTerrain, relief * 0.85);

        // Broad pale terrain is snow; thin white architectural lines become ink.
        const neutral = 1 - Math.min(1, colorSpread(smoothColor) / 48);
        const snow = clamp((localBrightness - 146) / 66, 0, 1) * neutral;
        color = mixColors(color, PALETTE.snow, profile.snow ? snow * 0.88 : 0);
        const shade = Math.max(0, (localBrightness - brightness(sourceColor) - 9) / 90);
        color = mixColors(color, PALETTE.terrainShadow, shade * 0.65);
        color = paintDistrictWashes(color, index, districts, textures);

        // Washed maps receive their linework after the terrain wash below.
        if (!(profile.inkWash > 0)) {
            color = paintLandmarkInk(color, index, ink);
        }
        color = paintLava(color, index, lava, textures);

        // Inland green/cyan effects are sepia stains, not false blue water.
        if (green > red * 1.16 && blue > red * 1.08 && green > 65) {
            if (profile.marsh) {
                const waterCoverage = clamp((green - red - 12) / 30, 0, 1);
                color = mixColors(color, profile.marsh.color, waterCoverage * profile.marsh.opacity);
            } else {
                color = mixColors(color, PALETTE.inlandStain, 0.3);
            }
        } else if (green > red * 1.12 && green > blue * 1.12) {
            color = mixColors(color, PALETTE.vegetation, 0.26);
        }

        const distance = coastDistance[index] / SHORELINE_SCALE;
        if (distance < 1.2) {
            color = mixColors(color, PALETTE.landShore, 0.65);
        } else if (distance < 3) {
            color = mixColors(color, PALETTE.landFoam, 0.84);
        } else if (distance < 6) {
            color = mixColors(color, PALETTE.coastalBank, 0.22);
        }
        return color;
    }

    function paintMap({ source, smoothed, ocean, coastDistance, lava, ink, textures, districts }) {
        const output = Buffer.alloc(PIXEL_COUNT * RGB_CHANNELS);
        for (let y = 0; y < HEIGHT; y++) {
            for (let x = 0; x < WIDTH; x++) {
                const index = y * WIDTH + x;
                let color = ocean[index]
                    ? paintOcean(coastDistance[index])
                    : paintLand(index, source, smoothed, coastDistance, lava, ink, textures, districts);

                // Thin pigment lets the paper supply the colour and texture beneath
                // the drawing. Low-frequency variation avoids a uniform digital tint.
                if (!ocean[index] && profile.inkWash > 0) {
                    const variation = ((textures.broad[index] - 128) / 128) * 0.10
                        + ((textures.medium[index] - 128) / 128) * 0.04;
                    color = mixColors(color, PALETTE.paper, clamp(profile.inkWash + variation, 0, 1));
                    color = paintLandmarkInk(color, index, ink);
                }

                // Age the paper edges and add fibres last, over both sea and land.
                const edgeDistance = Math.min(x, WIDTH - 1 - x, y, HEIGHT - 1 - y);
                const age = 0.2 * Math.exp(-edgeDistance / 20) + 0.075 * Math.exp(-edgeDistance / 90);
                color = mixColors(color, PALETTE.agedEdge, age);
                const fiber =
                    ((textures.fine[index] - 128) / 128) * 5 +
                    ((textures.medium[index] - 128) / 128) * 4 +
                    ((textures.broad[index] - 128) / 128) * 6;

                for (let channel = 0; channel < RGB_CHANNELS; channel++) {
                    output[index * RGB_CHANNELS + channel] = clamp(
                        Math.round(color[channel] + fiber),
                        0,
                        255,
                    );
                }
            }
        }
        return output;
    }

    // Compass placement and artwork ----------------------------------------------

    function isOceanDisk(ocean, centerX, centerY, radius) {
        // Inspect the whole disk, including islands and the clearance margin.
        for (let dy = -radius; dy <= radius; dy++) {
            const span = Math.floor(Math.sqrt(radius * radius - dy * dy));
            for (let dx = -span; dx <= span; dx++) {
                const x = centerX + dx;
                const y = centerY + dy;
                if (x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT || !ocean[y * WIDTH + x]) {
                    return false;
                }
            }
        }
        return true;
    }

    function findCompassPosition(ocean) {
        const clearance = Math.ceil(COMPASS.outerRadius * COMPASS.scale) + COMPASS.oceanMargin;
        let position = null;
        let bestScore = Infinity;

        for (let y = COMPASS.searchTop; y <= COMPASS.searchBottom; y += COMPASS.searchStep) {
            for (let x = COMPASS.searchLeft; x < WIDTH - clearance; x += COMPASS.searchStep) {
                const score = (x - COMPASS.preferredX) ** 2 + (y - COMPASS.preferredY) ** 2;
                if (score < bestScore && isOceanDisk(ocean, x, y, clearance)) {
                    position = { x, y };
                    bestScore = score;
                }
            }
        }
        if (position === null) {
            throw new Error('No ocean-only space for the compass and its clearance margin');
        }
        return { ...position, clearance };
    }

    function createCompassSvg({ x, y }) {
        const ticks = Array.from({ length: COMPASS.tickCount }, (_, index) => {
            const angle = (index * 360) / COMPASS.tickCount;
            const innerRadius = index % 4 === 0 ? 53 : 59;
            return `<path transform="rotate(${angle})" d="M0 -64 V-${innerRadius}" stroke-width=".65"/>`;
        }).join('\n');

        return Buffer.from(`
        <svg width="${WIDTH}" height="${HEIGHT}" xmlns="http://www.w3.org/2000/svg">
            <g transform="translate(${x} ${y}) scale(${COMPASS.scale})"
               stroke="#876638" fill="none" opacity=".25">
                <circle r="64" stroke-width=".8"/>
                <circle r="59" stroke-width=".6"/>
                <circle r="32" stroke-width=".7"/>
                ${ticks}
                <path d="M0-72 7-8 0-18-7-8ZM0 72 7 8 0 18-7 8ZM-72 0-8-7-18 0-8 7ZM72 0 8-7 18 0 8 7Z"
                      fill="#a2844e" fill-opacity=".32" stroke-width=".7"/>
                <path d="M-47-47 47 47M47-47-47 47" stroke-width=".5"/>
                <circle r="4" stroke-width=".6"/>
            </g>
        </svg>
    `);
    }

    // Rendering pipeline ----------------------------------------------------------

    const source = await sharp(INPUT_PATH).resize(WIDTH, HEIGHT).removeAlpha().raw().toBuffer();
    const smoothed = await rawImage(source, RGB_CHANNELS).median(3).blur(2).raw().toBuffer();
    const textures = await createTextures();
    const districts = await createDistrictWashes();

    const ocean = findOcean(source);
    const coastDistance = measureCoastDistance(ocean);
    const lava = await createLavaMasks(source, ocean);
    const landmarks = extractLandmarks(source, smoothed, ocean, coastDistance, lava);
    const ink = await drawLandmarkInk(landmarks, textures);

    const parchment = paintMap({ source, smoothed, ocean, coastDistance, lava, ink, textures, districts });
    let output = rawImage(parchment, RGB_CHANNELS);
    if (COMPASS !== null) {
        const compassPosition = findCompassPosition(ocean);
        const compass = createCompassSvg(compassPosition);
        console.log(
            `Compass at (${compassPosition.x}, ${compassPosition.y}); ocean-only radius ${compassPosition.clearance}px verified.`,
        );
        output = output.composite([{ input: compass }]);
    }
    await fs.mkdir(OUTPUT_DIRECTORY, { recursive: true });
    await output.png().toFile(OUTPUT_PATH);
    console.log(`Rendered ${profile.output} (${WIDTH}x${HEIGHT}).`);
}

module.exports = { renderMap };
