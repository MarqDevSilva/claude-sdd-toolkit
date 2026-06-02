#!/usr/bin/env node
// index-domains.mjs — varre libs/domains/src/lib/* e emite um índice FACTUAL (parsing, sem LLM):
// por domain → recurso (baseUrl), métodos públicos do service e interfaces/types do model.
// Dá ao agente de blueprint um índice compacto em vez de dezenas de pastas.
//
// Uso:
//   node index-domains.mjs --domains-root frontend/libs/domains/src/lib --out .spec/discovery/_domain-index.md
//   node index-domains.mjs --domains-root <dir> --dry-run     (imprime no stdout, não escreve)

import { readdirSync, readFileSync, writeFileSync, statSync, mkdirSync } from 'node:fs';
import { join, dirname, basename } from 'node:path';

function parseArgs(argv) {
  const args = { domainsRoot: 'frontend/libs/domains/src/lib', out: '.spec/discovery/_domain-index.md', dryRun: false };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--domains-root') args.domainsRoot = argv[++i];
    else if (a === '--out') args.out = argv[++i];
    else if (a === '--dry-run') args.dryRun = true;
    else if (a === '--help' || a === '-h') { printHelp(); process.exit(0); }
  }
  return args;
}

function printHelp() {
  console.log(`index-domains.mjs
  --domains-root <dir>   raiz dos domains (default: frontend/libs/domains/src/lib)
  --out <file>           arquivo de saída (default: .spec/discovery/_domain-index.md)
  --dry-run              imprime no stdout, não escreve`);
}

function safeRead(path) {
  try { return readFileSync(path, 'utf8'); } catch { return ''; }
}

function isDir(p) {
  try { return statSync(p).isDirectory(); } catch { return false; }
}

// recurso do baseUrl: `${inject(API_BASE_URL)}/<recurso>`
function extractResource(serviceSrc) {
  const m = serviceSrc.match(/baseUrl\s*=\s*[`'"]\$\{inject\(API_BASE_URL\)\}\/([^`'"]+)[`'"]/);
  if (m) return '/' + m[1];
  // fallback: qualquer http.<verbo>(`${...}/<algo>`) — pega o primeiro segmento literal
  const m2 = serviceSrc.match(/API_BASE_URL\)\}\/([a-zA-Z0-9\-_]+)/);
  return m2 ? '/' + m2[1] : '(?)';
}

// métodos públicos = declarações que retornam Observable, menos helpers conhecidos.
function extractMethods(serviceSrc) {
  const skip = new Set(['iniciarCarregamento', 'handleError', 'constructor']);
  const methods = [];
  const re = /(?:^|\n)\s*(?!private |protected )([a-zA-Z_]\w*)\s*\([^)]*\)\s*:\s*Observable\b/g;
  let m;
  while ((m = re.exec(serviceSrc)) !== null) {
    const name = m[1];
    if (!skip.has(name) && !methods.includes(name)) methods.push(name);
  }
  return methods;
}

// interfaces/types exportados do model
function extractModelTypes(modelSrc) {
  const types = [];
  const re = /export\s+(?:interface|type)\s+([A-Za-z_]\w*)/g;
  let m;
  while ((m = re.exec(modelSrc)) !== null) {
    if (!types.includes(m[1])) types.push(m[1]);
  }
  return types;
}

function main() {
  const args = parseArgs(process.argv);
  if (!isDir(args.domainsRoot)) {
    console.error(`erro: domains-root não encontrado: ${args.domainsRoot}`);
    process.exit(1);
  }

  const domains = readdirSync(args.domainsRoot)
    .filter((d) => isDir(join(args.domainsRoot, d)))
    .sort();

  const rows = [];
  for (const dom of domains) {
    const dir = join(args.domainsRoot, dom);
    const serviceSrc = safeRead(join(dir, `${dom}.service.ts`));
    const modelSrc = safeRead(join(dir, `${dom}.model.ts`));
    const resource = serviceSrc ? extractResource(serviceSrc) : '(sem service)';
    const methods = serviceSrc ? extractMethods(serviceSrc) : [];
    const models = modelSrc ? extractModelTypes(modelSrc) : [];
    rows.push({ dom, resource, methods, models });
  }

  const today = process.env.UI_BLUEPRINT_DATE || '';
  const lines = [];
  lines.push(`# Índice de domains (factual — gerado por ui-blueprint/index-domains.mjs)`);
  lines.push('');
  lines.push(`> ${rows.length} domain(s) em \`${args.domainsRoot}\`${today ? ` · ${today}` : ''}.`);
  lines.push(`> Resumo pra planejamento de telas. A fonte de verdade é o código do domain.`);
  lines.push('');
  lines.push(`| Domain | Recurso | Métodos (service) | Models (interfaces) |`);
  lines.push(`|--------|---------|-------------------|---------------------|`);
  for (const r of rows) {
    const methods = r.methods.length ? r.methods.map((m) => `\`${m}\``).join(', ') : '—';
    const models = r.models.length ? r.models.map((m) => `\`${m}\``).join(', ') : '—';
    lines.push(`| \`${r.dom}\` | \`${r.resource}\` | ${methods} | ${models} |`);
  }
  lines.push('');
  const totalMethods = rows.reduce((a, r) => a + r.methods.length, 0);
  const totalModels = rows.reduce((a, r) => a + r.models.length, 0);
  lines.push(`_Totais: ${rows.length} domains · ${totalMethods} métodos · ${totalModels} interfaces._`);
  lines.push('');

  const out = lines.join('\n');
  if (args.dryRun) {
    console.log(out);
  } else {
    mkdirSync(dirname(args.out), { recursive: true });
    writeFileSync(args.out, out, 'utf8');
    console.log(`Índice escrito em ${args.out} (${rows.length} domains, ${totalMethods} métodos, ${totalModels} interfaces).`);
  }
}

main();
