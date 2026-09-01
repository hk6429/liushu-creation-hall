#!/usr/bin/env node

import { copyFile, mkdir, readFile, readdir, stat, writeFile } from 'node:fs/promises';
import { basename, join, resolve } from 'node:path';
import { execFileSync } from 'node:child_process';

const sourceRoot = resolve(process.argv[2] || '../liushu-quest');
const projectRoot = resolve(new URL('..', import.meta.url).pathname);
const resourcesRoot = join(projectRoot, 'LiushuCreationHall', 'Resources');
const contentRoot = join(resourcesRoot, 'WebContent');
const imageRoot = join(resourcesRoot, 'ImportedImages');

const entityMap = new Map([
  ['&nbsp;', ' '], ['&amp;', '&'], ['&lt;', '<'], ['&gt;', '>'],
  ['&quot;', '"'], ['&#39;', "'"], ['&rarr;', '→']
]);

function decodeEntities(text) {
  return [...entityMap].reduce((value, [entity, replacement]) => value.split(entity).join(replacement), text);
}

function plainText(html) {
  return decodeEntities(html)
    .replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<br\s*\/?\s*>/gi, '\n')
    .replace(/<\/p>|<\/li>|<\/div>|<\/details>|<\/figure>/gi, '\n')
    .replace(/<li[^>]*>/gi, '• ')
    .replace(/<summary[^>]*>/gi, '\n檢核：')
    .replace(/<[^>]+>/g, '')
    .replace(/\$\{[^}]+\}/g, '')
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function extractTemplate(source) {
  const match = source.match(/const html = `([\s\S]*?)`;\s*\n/);
  if (!match) throw new Error('找不到 HTML template literal');
  return match[1];
}

function parseSections(html, kind) {
  const headingPattern = /<h([23])[^>]*>([\s\S]*?)<\/h\1>/gi;
  const headings = [...html.matchAll(headingPattern)];
  return headings.map((heading, index) => {
    const start = heading.index + heading[0].length;
    const end = index + 1 < headings.length ? headings[index + 1].index : html.length;
    const title = plainText(heading[2]);
    const body = plainText(html.slice(start, end));
    return {
      id: `${kind}-${String(index).padStart(2, '0')}`,
      title,
      body,
      imageName: imageNameFor(kind, title)
    };
  }).filter(section => section.title && section.body);
}

function imageNameFor(kind, title) {
  const conceptMap = [
    ['文字誕生', 'concept-00-origin'],
    ['六書總覽', 'concept-01-overview'],
    ['象形', 'concept-02-pictograph'],
    ['指事', 'concept-03-indicative'],
    ['會意', 'concept-04-compound'],
    ['假借', 'concept-05-loan'],
    ['形聲', 'concept-06-phonetic'],
    ['轉注', 'concept-07-transfer']
  ];
  const storyMap = [
    ['楔子', 'story-00-prologue'],
    ['象形', 'story-01-pictograph'],
    ['指事', 'story-02-indicative'],
    ['會意', 'story-03-compound'],
    ['假借', 'story-04-loan'],
    ['形聲', 'story-05-phonetic'],
    ['轉注', 'story-06-transfer'],
    ['尾聲', 'story-07-epilogue']
  ];
  const pairs = kind === 'concept' ? conceptMap : storyMap;
  return pairs.find(([needle]) => title.includes(needle))?.[1] || null;
}

async function copyDirectoryFiles(from, prefix = '') {
  const names = await readdir(from);
  for (const name of names) {
    const source = join(from, name);
    if (!(await stat(source)).isFile()) continue;
    const targetName = prefix ? `${prefix}-${name}` : name;
    await copyFile(source, join(imageRoot, targetName));
  }
}

await mkdir(contentRoot, { recursive: true });
await mkdir(imageRoot, { recursive: true });

const sourceVersion = execFileSync('git', ['rev-parse', 'HEAD'], {
  cwd: sourceRoot,
  encoding: 'utf8'
}).trim();

await copyFile(join(sourceRoot, 'data', 'chars.json'), join(contentRoot, 'characters.json'));

const conceptSource = await readFile(join(sourceRoot, 'js', 'concept.js'), 'utf8');
const storySource = await readFile(join(sourceRoot, 'js', 'story.js'), 'utf8');
const library = {
  schemaVersion: 1,
  sourceRepository: 'hk6429/liushu-quest',
  sourceVersion,
  importedAt: new Date().toISOString(),
  concept: parseSections(extractTemplate(conceptSource), 'concept'),
  story: parseSections(extractTemplate(storySource), 'story')
};
await writeFile(
  join(contentRoot, 'learning-library.json'),
  JSON.stringify(library, null, 2) + '\n',
  'utf8'
);

await copyDirectoryFiles(join(sourceRoot, 'img', 'chars'));
await copyDirectoryFiles(join(sourceRoot, 'img', 'concept'), 'concept');
await copyDirectoryFiles(join(sourceRoot, 'img', 'story'), 'story');
await copyDirectoryFiles(join(sourceRoot, 'img', 'characters'), 'character');
await copyDirectoryFiles(join(sourceRoot, 'img', 'masters'), 'master');
await copyFile(join(sourceRoot, 'assets', 'icons', 'icon-1024.png'), join(imageRoot, 'app-icon-source.png'));

console.log(JSON.stringify({
  sourceRoot,
  sourceVersion,
  characters: JSON.parse(await readFile(join(contentRoot, 'characters.json'), 'utf8')).length,
  conceptSections: library.concept.length,
  storySections: library.story.length
}, null, 2));
