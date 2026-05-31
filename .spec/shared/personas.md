# Personas Reutilizáveis

> Personas comuns que costumam aparecer em specs. Reuse e customize por projeto.

## Persona: Administrador

- **Quem é**: usuário interno com acesso a configurações globais.
- **Objetivo**: configurar o sistema, gerenciar usuários, ver auditoria.
- **Frustrações**: telas lentas, falta de feedback em ações destrutivas, logs incompletos.
- **Restrições**: poucos por organização; tolerância baixa a erro destrutivo sem confirmação.

## Persona: Usuário operacional

- **Quem é**: usuário do dia-a-dia, executa a maior parte das tarefas.
- **Objetivo**: completar fluxos repetitivos com o mínimo de cliques.
- **Frustrações**: formulários longos, validação tardia, navegação imprevisível.
- **Restrições**: muitas vezes em ambiente desktop com múltiplas abas.

## Persona: Usuário consumidor / Cliente

- **Quem é**: usuário externo que consome o serviço (B2C ou B2B).
- **Objetivo**: alcançar um valor específico (comprar, consultar, agendar).
- **Frustrações**: cadastro complexo, esperas longas, mensagens de erro genéricas.
- **Restrições**: provavelmente em mobile, com conexão instável.

## Persona: Desenvolvedor (consumidor de API)

- **Quem é**: dev integrando seu sistema com nossa API.
- **Objetivo**: integrar rapidamente, sem ler código nosso.
- **Frustrações**: docs incompletas, mensagens de erro vagas, breaking changes silenciosas.
- **Restrições**: confia no contrato — qualquer divergência implementação/doc quebra integração.

## Persona: Operador / SRE

- **Quem é**: responsável pelo sistema rodando em produção.
- **Objetivo**: detectar e mitigar incidentes rápido.
- **Frustrações**: logs sem correlação, métricas vagas, alerts falso-positivos.
- **Restrições**: opera múltiplos serviços; só tem atenção pro nosso quando algo quebra.

## Como usar

Em uma spec, cite a persona por nome e detalhe apenas o que muda do template. Não copie e cole o bloco todo.
