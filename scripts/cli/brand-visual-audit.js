#!/usr/bin/env node
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
/**
 * BlackRoad Brand Visual Audit
 * Takes screenshots and compares visual elements against brand standards
 * Requires: npm install playwright pixelmatch pngjs
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// Brand standards for visual comparison
const BRAND_STANDARDS = {
    colors: {
        hotPink: '#FF1D6C',
        amber: '#F5A623',
        electricBlue: '#2979FF',
        violet: '#9C27B0',
        black: '#000000',
        white: '#FFFFFF'
    },
    requiredElements: [
        '.scroll-progress',
        'nav',
        '.road-dashes',  // Logo animation class
    ],
    fonts: [
        '-apple-system',
        'SF Pro Display',
        'BlinkMacSystemFont'
    ]
};

async function auditProject(url, projectName) {
    console.log(`\n🔍 Auditing: ${projectName}`);
    console.log(`   URL: ${url}`);

    const browser = await chromium.launch();
    const page = await browser.newPage({
        viewport: { width: 1920, height: 1080 }
    });

    const results = {
        project: projectName,
        url,
        timestamp: new Date().toISOString(),
        score: 100,
        issues: [],
        screenshots: {}
    };

    try {
        await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });

        // Take full page screenshot
        const screenshotPath = path.join(__dirname, '../brand-audit-screenshots', `${projectName}.png`);
        fs.mkdirSync(path.dirname(screenshotPath), { recursive: true });
        await page.screenshot({ path: screenshotPath, fullPage: true });
        results.screenshots.full = screenshotPath;

        console.log(`   📸 Screenshot saved`);

        // Check for required HTML elements
        for (const selector of BRAND_STANDARDS.requiredElements) {
            const element = await page.$(selector);
            if (!element) {
                results.issues.push(`Missing element: ${selector}`);
                results.score -= 10;
                console.log(`   ❌ Missing: ${selector}`);
            } else {
                console.log(`   ✓ Found: ${selector}`);
            }
        }

        // Check CSS variables
        const cssVars = await page.evaluate(() => {
            const styles = getComputedStyle(document.documentElement);
            return {
                hotPink: styles.getPropertyValue('--hot-pink').trim(),
                amber: styles.getPropertyValue('--amber').trim(),
                electricBlue: styles.getPropertyValue('--electric-blue').trim(),
                violet: styles.getPropertyValue('--violet').trim(),
                gradientBrand: styles.getPropertyValue('--gradient-brand').trim()
            };
        });

        // Validate colors
        if (cssVars.hotPink && cssVars.hotPink.toLowerCase() !== BRAND_STANDARDS.colors.hotPink.toLowerCase()) {
            results.issues.push(`Wrong hot-pink color: ${cssVars.hotPink} (expected ${BRAND_STANDARDS.colors.hotPink})`);
            results.score -= 15;
            console.log(`   ❌ Wrong hot-pink: ${cssVars.hotPink}`);
        } else if (!cssVars.hotPink) {
            results.issues.push('Missing --hot-pink CSS variable');
            results.score -= 15;
            console.log(`   ❌ Missing --hot-pink`);
        } else {
            console.log(`   ✓ Correct hot-pink color`);
        }

        if (!cssVars.gradientBrand) {
            results.issues.push('Missing --gradient-brand CSS variable');
            results.score -= 15;
            console.log(`   ❌ Missing --gradient-brand`);
        } else {
            console.log(`   ✓ Found --gradient-brand`);
        }

        // Check for logo animation
        const hasLogoAnimation = await page.evaluate(() => {
            const dashesElement = document.querySelector('.road-dashes');
            if (!dashesElement) return false;
            const styles = getComputedStyle(dashesElement);
            return styles.animation && styles.animation.includes('logo-spin');
        });

        if (!hasLogoAnimation) {
            results.issues.push('Logo animation (logo-spin) not detected');
            results.score -= 10;
            console.log(`   ❌ Logo animation missing`);
        } else {
            console.log(`   ✓ Logo animation active`);
        }

        // Check scroll progress bar
        const hasScrollProgress = await page.evaluate(() => {
            const progress = document.querySelector('.scroll-progress');
            if (!progress) return false;
            const styles = getComputedStyle(progress);
            return styles.position === 'fixed' && styles.top === '0px';
        });

        if (!hasScrollProgress) {
            results.issues.push('Scroll progress bar not properly configured');
            results.score -= 10;
            console.log(`   ❌ Scroll progress bar issue`);
        } else {
            console.log(`   ✓ Scroll progress bar configured`);
        }

        // Check font stack
        const bodyFont = await page.evaluate(() => {
            const styles = getComputedStyle(document.body);
            return styles.fontFamily;
        });

        const hasBrandFont = BRAND_STANDARDS.fonts.some(font =>
            bodyFont.includes(font)
        );

        if (!hasBrandFont) {
            results.issues.push('Missing SF Pro Display / -apple-system font stack');
            results.score -= 10;
            console.log(`   ❌ Wrong font: ${bodyFont}`);
        } else {
            console.log(`   ✓ Correct font stack`);
        }

        // Check line-height
        const lineHeight = await page.evaluate(() => {
            const styles = getComputedStyle(document.body);
            return parseFloat(styles.lineHeight) / parseFloat(styles.fontSize);
        });

        if (Math.abs(lineHeight - 1.618) > 0.1) {
            results.issues.push(`Line-height not Golden Ratio (found ${lineHeight.toFixed(3)}, expected 1.618)`);
            results.score -= 5;
            console.log(`   ⚠️  Line-height: ${lineHeight.toFixed(3)} (should be 1.618)`);
        } else {
            console.log(`   ✓ Golden Ratio line-height`);
        }

    } catch (error) {
        results.issues.push(`Error during audit: ${error.message}`);
        results.score = 0;
        console.log(`   ❌ Audit error: ${error.message}`);
    } finally {
        await browser.close();
    }

    // Determine compliance level
    if (results.score >= 90) {
        results.compliance = 'COMPLIANT';
        console.log(`   ✅ ${results.score}% - COMPLIANT`);
    } else if (results.score >= 70) {
        results.compliance = 'NEEDS_WORK';
        console.log(`   ⚠️  ${results.score}% - NEEDS WORK`);
    } else {
        results.compliance = 'NON_COMPLIANT';
        console.log(`   ❌ ${results.score}% - NON-COMPLIANT`);
    }

    return results;
}

async function main() {
    const args = process.argv.slice(2);

    if (args.length === 0) {
        console.log('Usage: brand-visual-audit.js <url> <project-name>');
        console.log('');
        console.log('Example:');
        console.log('  brand-visual-audit.js https://blackroad-io.pages.dev blackroad-io');
        process.exit(1);
    }

    const [url, projectName = 'unknown'] = args;

    console.log('🌌 BlackRoad Brand Visual Audit');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    const results = await auditProject(url, projectName);

    // Save results
    const resultsPath = path.join(__dirname, '../brand-audit-results', `${projectName}.json`);
    fs.mkdirSync(path.dirname(resultsPath), { recursive: true });
    fs.writeFileSync(resultsPath, JSON.stringify(results, null, 2));

    console.log('');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`📊 Final Score: ${results.score}%`);
    console.log(`📁 Results saved: ${resultsPath}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = { auditProject };
