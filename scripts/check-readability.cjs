#!/usr/bin/env node
/**
 * Readability Scoring Script
 *
 * Analyzes program descriptions for reading level complexity.
 * Flags descriptions above 8th grade reading level (too complex for
 * general public, especially those in crisis).
 *
 * Uses Flesch-Kincaid Grade Level formula.
 *
 * Run: node scripts/check-readability.cjs
 * CI: Fails if more than 20% of descriptions exceed grade 10.
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

// Data directory
const DATA_DIR = path.join(__dirname, '..', 'src', 'data');

// Non-program YAML files to skip
const NON_PROGRAM_FILES = [
  'categories.yml',
  'groups.yml',
  'areas.yml',
  'glossary.yml',
  'search-config.yml',
  'site-config.yml',
  'county-supervisors.yml',
  'transit-agencies.yml',
];

// Thresholds
const WARN_GRADE = 8; // Warn if above 8th grade
const ERROR_GRADE = 12; // Error if above 12th grade
const MAX_COMPLEX_PERCENT = 20; // Fail if more than 20% exceed grade 10

/**
 * Count syllables in a word (approximation)
 */
function countSyllables(word) {
  word = word.toLowerCase().replace(/[^a-z]/g, '');
  if (word.length <= 3) return 1;

  // Count vowel groups
  const vowels = word.match(/[aeiouy]+/g);
  let count = vowels ? vowels.length : 1;

  // Adjustments for common patterns
  if (word.endsWith('e') && !word.endsWith('le')) count--;
  if (word.endsWith('es') || word.endsWith('ed')) count--;
  if (word.match(/[aeiouy]{2}/)) count--; // Diphthongs
  if (count < 1) count = 1;

  return count;
}

/**
 * Calculate Flesch-Kincaid Grade Level
 * Formula: 0.39 * (words/sentences) + 11.8 * (syllables/words) - 15.59
 */
function calculateFleschKincaid(text) {
  if (!text || typeof text !== 'string') return 0;

  // Clean text
  const cleanText = text.replace(/[^\w\s.!?]/g, ' ').trim();
  if (!cleanText) return 0;

  // Count sentences (periods, exclamations, questions)
  const sentences = cleanText.split(/[.!?]+/).filter((s) => s.trim().length > 0);
  const sentenceCount = Math.max(sentences.length, 1);

  // Count words
  const words = cleanText.split(/\s+/).filter((w) => w.match(/[a-zA-Z]/));
  const wordCount = Math.max(words.length, 1);

  // Count syllables
  let syllableCount = 0;
  for (const word of words) {
    syllableCount += countSyllables(word);
  }

  // Calculate grade level
  const grade = 0.39 * (wordCount / sentenceCount) + 11.8 * (syllableCount / wordCount) - 15.59;

  return Math.max(0, Math.round(grade * 10) / 10);
}

/**
 * Get grade level description
 */
function getGradeDescription(grade) {
  if (grade <= 5) return 'Easy (5th grade or below)';
  if (grade <= 8) return 'Standard (6th-8th grade)';
  if (grade <= 10) return 'Fairly Difficult (9th-10th grade)';
  if (grade <= 12) return 'Difficult (11th-12th grade)';
  return 'Very Difficult (College level)';
}

/**
 * Main analysis
 */
async function main() {
  console.log('Readability Analysis');
  console.log('====================\n');

  const files = fs.readdirSync(DATA_DIR).filter((f) => f.endsWith('.yml') || f.endsWith('.yaml'));

  const results = [];
  let totalPrograms = 0;
  let complexCount = 0;
  let errorCount = 0;

  for (const file of files) {
    if (NON_PROGRAM_FILES.includes(file)) continue;

    const filePath = path.join(DATA_DIR, file);
    const content = fs.readFileSync(filePath, 'utf8');

    let programs;
    try {
      programs = yaml.load(content);
    } catch (e) {
      console.warn(`Warning: Could not parse ${file}`);
      continue;
    }

    if (!Array.isArray(programs)) continue;

    for (const program of programs) {
      if (!program.name) continue;

      totalPrograms++;

      // Analyze description
      const description = program.description || '';
      const grade = calculateFleschKincaid(description);

      const result = {
        file,
        name: program.name,
        descriptionLength: description.length,
        grade,
        gradeDescription: getGradeDescription(grade),
      };

      results.push(result);

      if (grade > 10) complexCount++;
      if (grade > ERROR_GRADE) errorCount++;
    }
  }

  // Sort by grade (highest first)
  results.sort((a, b) => b.grade - a.grade);

  // Print summary
  console.log(`Total programs analyzed: ${totalPrograms}`);
  console.log(`Programs above 8th grade: ${results.filter((r) => r.grade > WARN_GRADE).length}`);
  console.log(`Programs above 10th grade: ${complexCount}`);
  console.log(`Programs above 12th grade (errors): ${errorCount}\n`);

  // Print top 20 most complex
  console.log('Top 20 Most Complex Descriptions:');
  console.log('-'.repeat(80));

  for (const result of results.slice(0, 20)) {
    const status =
      result.grade > ERROR_GRADE ? '❌ ERROR' : result.grade > WARN_GRADE ? '⚠️  WARN' : '✓';
    console.log(`${status} Grade ${result.grade}: ${result.name}`);
    console.log(`   File: ${result.file}`);
    console.log(`   Level: ${result.gradeDescription}`);
    console.log('');
  }

  // Calculate percentage
  const complexPercent = totalPrograms > 0 ? (complexCount / totalPrograms) * 100 : 0;

  console.log('-'.repeat(80));
  console.log(`\nComplexity Summary:`);
  console.log(`  ${complexPercent.toFixed(1)}% of descriptions are above 10th grade level`);
  console.log(`  Threshold: ${MAX_COMPLEX_PERCENT}%\n`);

  // Determine exit code
  if (complexPercent > MAX_COMPLEX_PERCENT) {
    console.log(
      `❌ FAIL: ${complexPercent.toFixed(1)}% exceeds ${MAX_COMPLEX_PERCENT}% threshold\n`
    );
    console.log('Recommendations:');
    console.log('  - Use shorter sentences (aim for 15-20 words)');
    console.log('  - Replace complex words with simpler alternatives');
    console.log('  - Break long descriptions into bullet points');
    console.log('  - Consider running through the plain language workflow\n');
    process.exit(1);
  }

  if (errorCount > 0) {
    console.log(`⚠️  WARNING: ${errorCount} programs have college-level readability\n`);
    console.log('Consider simplifying these descriptions for accessibility.\n');
    // Don\'t fail, just warn
  }

  console.log('✅ PASS: Readability within acceptable range\n');
  process.exit(0);
}

main().catch((error) => {
  console.error('Error:', error);
  process.exit(1);
});
