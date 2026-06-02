#!/usr/bin/env node
// slice-openapi.mjs — fatia um OpenAPI (springdoc) grande em UMA spec por tag.
//
// Para cada tag do contrato, gera:
//   .spec/changes/SPEC-<NNN>-<slug>/spec.md
// contendo SÓ as operations daquela tag + o FECHO TRANSITIVO dos schemas que elas
// referenciam ($ref). Assim o agente que executa a spec lê um arquivo pequeno e
// auto-contido — nunca o api-docs inteiro — e a lista de endpoints/schemas é FATO
// (parsing puro), não interpretação. Isso é o que evita alucinação/omissão.
//
// Uso:
//   node slice-openapi.mjs --input <api-docs.json|url> [opções]
//
// Opções:
//   --input <f|url>       Caminho do api-docs.json OU URL (ex: http://localhost:8080/v3/api-docs). Obrigatório.
//   --spec-root <dir>     Raiz do .spec (default: ./.spec)
//   --domains-root <dir>  Raiz dos domains, p/ detectar scaffold vs sync (default: libs/domains)
//   --author <nome>       Autor no frontmatter (default: api-contract-sync)
//   --date <YYYY-MM-DD>   Data no frontmatter (default: hoje)
//   --only <tag>          Gera só a spec dessa tag (pode repetir)
//   --force               Regera mesmo se já existir SPEC com o mesmo slug em changes/ ou archive/
//   --dry-run             Mostra o que faria, sem escrever nada
//   -h, --help            Esta ajuda
//
// Notas:
//   - Aceita só JSON. Se o spec for YAML, exporte/baixe como JSON antes.
//   - Numeração SPEC-<NNN> continua a sequência existente em changes/ + archive/.

import fs from 'node:fs';
import path from 'node:path';

const HTTP_METHODS = ['get', 'put', 'post', 'delete', 'patch', 'options', 'head', 'trace'];

function parseArgs(argv) {
  const args = { only: [], specRoot: './.spec', domainsRoot: 'libs/domains', author: 'api-contract-sync' };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const next = () => argv[++i];
    switch (a) {
      case '--input': args.input = next(); break;
      case '--spec-root': args.specRoot = next(); break;
      case '--domains-root': args.domainsRoot = next(); break;
      case '--author': args.author = next(); break;
      case '--date': args.date = next(); break;
      case '--only': args.only.push(next()); break;
      case '--force': args.force = true; break;
      case '--dry-run': args.dryRun = true; break;
      case '-h': case '--help': args.help = true; break;
      default: throw new Error(`Opção desconhecida: ${a}`);
    }
  }
  return args;
}

function help() {
  const src = fs.readFileSync(new URL(import.meta.url), 'utf8');
  for (const line of src.split('\n')) {
    if (line.startsWith('//')) console.log(line.replace(/^\/\/ ?/, ''));
    else if (line.startsWith('#!')) continue;
    else break;
  }
}

async function loadSpec(input) {
  let raw;
  if (/^https?:\/\//.test(input)) {
    const res = await fetch(input);
    if (!res.ok) throw new Error(`Falha ao baixar ${input}: HTTP ${res.status}`);
    raw = await res.text();
  } else {
    raw = fs.readFileSync(input, 'utf8');
  }
  try {
    return JSON.parse(raw);
  } catch {
    throw new Error('Não consegui parsear como JSON. Se for YAML, exporte/baixe o spec como JSON antes.');
  }
}

function slugify(tag) {
  return tag
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}

function fallbackTag(p) {
  const seg = p.split('/').filter(Boolean)[0] || 'api';
  return seg.replace(/\{.*\}/g, '').replace(/[^a-zA-Z0-9]/g, '') || 'api';
}

// Coleta todos os nomes de schema referenciados via #/components/schemas/<Nome>
function collectRefs(node, acc) {
  if (!node || typeof node !== 'object') return;
  if (Array.isArray(node)) { for (const n of node) collectRefs(n, acc); return; }
  for (const [k, v] of Object.entries(node)) {
    if (k === '$ref' && typeof v === 'string') {
      const m = v.match(/#\/components\/schemas\/(.+)$/);
      if (m) acc.add(decodeURIComponent(m[1]));
    } else {
      collectRefs(v, acc);
    }
  }
}

// Fecho transitivo: a partir das sementes, puxa cada schema e segue seus $ref até estabilizar.
function closure(seedNames, schemas, missing) {
  const result = new Set();
  const queue = [...seedNames];
  while (queue.length) {
    const name = queue.pop();
    if (result.has(name)) continue;
    result.add(name);
    const schema = schemas[name];
    if (!schema) { missing.add(name); continue; }
    const refs = new Set();
    collectRefs(schema, refs);
    for (const r of refs) if (!result.has(r)) queue.push(r);
  }
  return result;
}

function groupByTag(spec) {
  const byTag = {};
  for (const [p, item] of Object.entries(spec.paths ?? {})) {
    for (const method of HTTP_METHODS) {
      const op = item[method];
      if (!op) continue;
      const tags = (op.tags && op.tags.length) ? op.tags : [fallbackTag(p)];
      for (const tag of tags) {
        (byTag[tag] ??= { operations: [], seedRefs: new Set() });
        byTag[tag].operations.push({
          method: method.toUpperCase(), path: p,
          operationId: op.operationId, summary: op.summary,
          parameters: op.parameters, requestBody: op.requestBody, responses: op.responses,
        });
        collectRefs({ parameters: op.parameters, requestBody: op.requestBody, responses: op.responses }, byTag[tag].seedRefs);
      }
    }
  }
  return byTag;
}

function nextSpecNumber(specRoot) {
  let max = 0;
  for (const dir of ['changes', 'archive']) {
    const full = path.join(specRoot, dir);
    if (!fs.existsSync(full)) continue;
    for (const entry of fs.readdirSync(full)) {
      const m = entry.match(/^SPEC-(\d{3})/);
      if (m) max = Math.max(max, parseInt(m[1], 10));
    }
  }
  return max + 1;
}

function specExistsForSlug(specRoot, slug) {
  for (const dir of ['changes', 'archive']) {
    const full = path.join(specRoot, dir);
    if (!fs.existsSync(full)) continue;
    for (const entry of fs.readdirSync(full)) {
      if (entry.match(new RegExp(`^SPEC-\\d{3}-${slug}$`))) return path.join(dir, entry);
    }
  }
  return null;
}

function operationsTable(operations) {
  const rows = operations.map((o) => {
    const id = o.operationId || '—';
    const sum = (o.summary || '').replace(/\|/g, '\\|');
    return `| \`${o.method}\` | \`${o.path}\` | \`${id}\` | ${sum} |`;
  });
  return ['| Método | Path | operationId | Resumo |', '|--------|------|-------------|--------|', ...rows].join('\n');
}

function renderSpec({ id, tag, slug, tipo, date, author, slice, missing }) {
  const opCount = slice.operations.length;
  const schemaNames = Object.keys(slice.schemas);
  const acaoModels = tipo === 'sync'
    ? 'Regerar `<dominio>.model.ts` 1:1 com os schemas abaixo (sobrescreve — é seguro, sem lógica).'
    : 'Criar `<dominio>.model.ts` com as interfaces 1:1 com os schemas abaixo.';
  const acaoService = tipo === 'sync'
    ? 'NÃO sobrescrever `<dominio>.service.ts`/`.state.ts` (têm lógica custom). Reportar **drift**: operations novas/removidas/alteradas pro dev aplicar à mão.'
    : 'Criar `<dominio>.state.ts` (signals públicos graváveis: lista, `selecionado`, `carregando`, `erro: ProblemDetails|null`) e `<dominio>.service.ts` (um método por operation, sobre `HttpClient`, `baseUrl` via `API_BASE_URL`, `tap`→state, `catchError`→`handleError`).';
  const acaoSpec = tipo === 'sync'
    ? 'Atualizar o `<dominio>.service.spec.ts` só se já não cobrir as operations atuais.'
    : 'Criar `<dominio>.service.spec.ts` com `HttpTestingController` cobrindo o CRUD (método/URL/body + mutação do state + erro→ProblemDetails).';

  const missingNote = missing.length
    ? `\n> ⚠️ Schemas referenciados mas ausentes em \`components.schemas\`: ${missing.map((m) => `\`${m}\``).join(', ')}. Conferir o backend.\n`
    : '';

  return `---
id: SPEC-${id}
titulo: Sincronizar domain ${tag}
status: aprovada   # gerada por api-contract-sync, pronta pra execução
tipo: contract-sync
operacao: ${tipo}   # scaffold (domain novo) | sync (domain existente → só models + drift)
tag: ${tag}
dominio: ${slug}
gerada-por: api-contract-sync
autor: ${author}
criada-em: ${date}
atualizada-em: ${date}
relacionadas: []
---

# SPEC-${id}: Sincronizar domain \`${tag}\`

> Spec auto-gerada a partir do OpenAPI do Spring. Fatia auto-contida: ${opCount} operation(s)
> e ${schemaNames.length} schema(s) (fecho transitivo de \`$ref\`). Construir conforme o padrão
> do \`angular-engineer\` (signals + service inteligente sobre \`HttpClient\`, \`ProblemDetails\`).
${missingNote}
## 1. Objetivo

${tipo === 'sync' ? 'Sincronizar' : 'Criar'} o domain \`libs/domains/${slug}/\` com o contrato atual da tag \`${tag}\`.

## 2. Ação (operação: ${tipo})

- **Models**: ${acaoModels}
- **State + Service**: ${acaoService}
- **Testes**: ${acaoSpec}
- **Barrel**: garantir \`index.ts\` exportando model, service e state.

## 3. Critérios de aceitação

1. [ ] \`<dominio>.model.ts\` tem exatamente ${schemaNames.length} interface(s), 1:1 com os schemas.
2. [ ] Cada uma das ${opCount} operation(s) abaixo vira um método no service (ou está reportada como drift).
3. [ ] \`ng lint\` limpo no domain.
4. [ ] \`ng test\` verde para o \`<dominio>.service.spec.ts\`.

## 4. Verificação (determinística — antes de arquivar)

- nº de interfaces em \`model.ts\` == **${schemaNames.length}** (schemas no slice).
- nº de métodos públicos no \`service.ts\` == **${opCount}** (operations no slice) — ou diferença justificada no drift report.

## 5. Contrato — operations

${operationsTable(slice.operations)}

## 6. Contrato — fatia OpenAPI (fecho transitivo)

> Use SÓ este JSON como fonte. Não vá no api-docs completo.

\`\`\`json
${JSON.stringify(slice, null, 2)}
\`\`\`
`;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) { help(); return; }
  if (!args.input) { console.error('Erro: --input é obrigatório. Use -h para ajuda.'); process.exit(1); }

  const date = args.date || new Date().toISOString().slice(0, 10);
  const spec = await loadSpec(args.input);
  const schemas = spec.components?.schemas ?? {};
  const byTag = groupByTag(spec);

  let tags = Object.keys(byTag).sort();
  if (args.only.length) tags = tags.filter((t) => args.only.includes(t));
  if (!tags.length) { console.error('Nenhuma tag encontrada (ou nenhuma bateu com --only).'); process.exit(1); }

  const changesDir = path.join(args.specRoot, 'changes');
  if (!args.dryRun && !fs.existsSync(changesDir)) fs.mkdirSync(changesDir, { recursive: true });

  let nnn = nextSpecNumber(args.specRoot);
  const created = [];
  const skipped = [];

  for (const tag of tags) {
    const slug = slugify(tag);
    const existing = specExistsForSlug(args.specRoot, slug);
    if (existing && !args.force) { skipped.push({ tag, slug, at: existing }); continue; }

    const missing = new Set();
    const names = [...closure(byTag[tag].seedRefs, schemas, missing)].sort();
    const sliceSchemas = {};
    for (const n of names) if (schemas[n]) sliceSchemas[n] = schemas[n];

    const slice = { tag, operations: byTag[tag].operations, schemas: sliceSchemas };
    const tipo = fs.existsSync(path.join(args.domainsRoot, slug)) ? 'sync' : 'scaffold';
    const id = String(nnn).padStart(3, '0');
    const folder = path.join(changesDir, `SPEC-${id}-${slug}`);
    const file = path.join(folder, 'spec.md');
    const content = renderSpec({ id, tag, slug, tipo, date, author: args.author, slice, missing: [...missing] });

    if (args.dryRun) {
      console.log(`  [dry-run] criaria: ${file}  (${tipo}, ${slice.operations.length} ops, ${names.length} schemas)`);
    } else {
      fs.mkdirSync(folder, { recursive: true });
      fs.writeFileSync(file, content);
      console.log(`  criado: ${file}  (${tipo}, ${slice.operations.length} ops, ${names.length} schemas)`);
    }
    created.push({ id, tag, slug, tipo });
    nnn++;
  }

  console.log(`\nResumo: ${created.length} spec(s) ${args.dryRun ? 'seriam geradas' : 'geradas'}, ${skipped.length} puladas.`);
  if (skipped.length) {
    console.log('Puladas (já existem — use --force pra regerar):');
    for (const s of skipped) console.log(`  - ${s.tag} → ${s.at}`);
  }
  if (created.length && !args.dryRun) {
    console.log('\nFila pronta em .spec/changes/. Próximo passo: o agente drena a fila (executa → arquiva → próxima).');
  }
}

main().catch((err) => { console.error(`Erro: ${err.message}`); process.exit(1); });
