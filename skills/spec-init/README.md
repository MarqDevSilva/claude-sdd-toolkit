# spec-init

> Scaffolda a estrutura `.spec/` completa num projeto que ainda não a tem — passo zero do fluxo SDD.

Skill de bootstrap: cria `.spec/` com todas as subpastas (`discovery/`, `changes/`, `archive/`, `memory/`, `templates/`), cada uma com `.gitkeep`, mais um `README.md` na raiz explicando o papel de cada pasta. Idempotente: roda quantas vezes quiser, nunca apaga nada, só completa o que falta.

## Quando usar

- Comando explícito `/spec-init`.
- Projeto sem `.spec/` que vai adotar o fluxo SDD.
- Usuário pede pra "inicializar o SDD aqui", "criar a pasta .spec" ou "preparar o terreno pras specs".

## Conteúdo

- `SKILL.md` — quando usar, o que o script cria, opções e comportamento (idempotente, aditivo, não inicia o kickoff sozinho).
- `scripts/init-spec.sh` — script que cria a estrutura. Aceita `[destino]`, `--dry-run`, `--force`, `--no-readme`.

## Uso direto do script

```bash
bash skills/spec-init/scripts/init-spec.sh --dry-run   # ver o que faria
bash skills/spec-init/scripts/init-spec.sh             # criar .spec/ aqui
bash skills/spec-init/scripts/init-spec.sh /outro/projeto
```

## Relação com outras skills

Passo **zero** do ciclo, antes de tudo: `spec-init` → `app-kickoff` (novo) ou `project-onboard` (existente) → `spec-new` → `spec-review` → `spec-plan` → `spec-tasks` → implementação. Só prepara as pastas; não cria specs nem faz descoberta.
