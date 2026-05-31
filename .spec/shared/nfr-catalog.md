# Catálogo de Requisitos Não-Funcionais (NFRs)

> Lista de NFRs comuns com alvos sugeridos. Em cada spec, **selecione** apenas os relevantes e **calibre** os números pro contexto.

## Performance

| NFR | Alvo sugerido | Como medir |
|-----|---------------|------------|
| Latência API (leitura) | p95 < 300ms, p99 < 800ms | Micrometer + Prometheus |
| Latência API (escrita) | p95 < 500ms | Micrometer + Prometheus |
| Tempo até interativo (TTI) | < 3s em 4G simulado | Lighthouse / Web Vitals |
| First Contentful Paint | < 1.5s | Web Vitals |
| Throughput | X req/s sustentado por 5min | Carga sintética (k6 / Gatling) |

## Disponibilidade

| NFR | Alvo sugerido | Como medir |
|-----|---------------|------------|
| SLA | 99.5% mensal | Uptime monitor externo |
| Recovery Time Objective (RTO) | < 30min | Drill de DR |
| Recovery Point Objective (RPO) | < 1h | Política de backup |

## Segurança

| NFR | Alvo |
|-----|------|
| Autenticação | Obrigatória em todos endpoints exceto `/health`, `/api/v1/auth/*` |
| Autorização | Por endpoint + por recurso (verificação de ownership) |
| Senhas | bcrypt (cost ≥ 12) ou Argon2id |
| Tokens | JWT curto (≤ 15min) + refresh token rotativo |
| CORS | Lista explícita de origins; nada de `*` em prod |
| Rate limiting | 100 req/min por usuário (configurável por endpoint sensível) |
| Logs sem PII | Confirmar por revisão e regex nos logs |

## Privacidade e LGPD

| NFR | Alvo |
|-----|------|
| Dados pessoais identificáveis | Criptografados em repouso (AES-256) |
| Direito ao esquecimento | Endpoint de exclusão por usuário; soft delete + purge em 30 dias |
| Consentimento | Registrado com timestamp + versão dos termos |

## Observabilidade

> Padrão detalhado em [observability.md](observability.md).

| NFR | Alvo |
|-----|------|
| Logs (back) | Logback — dev: pretty + cores / prod: JSON (`logstash-logback-encoder`); MDC com `traceId` |
| Logs (front) | `LoggerService` injetável; dev = console pretty / prod = silenciado exceto erro |
| Error tracking | Sentry nos dois lados (front + back), com `traceId` como tag |
| Métricas | Spring Actuator + Micrometer + Prometheus; RED por endpoint |
| Health check | `/actuator/health` com indicators custom por feature crítica |
| Tracing | W3C TraceContext (`traceparent`) propagado front → back; sampling 10% em prod |
| Alertas | Erro > 1% por 5min; latência p95 > 2x alvo por 5min |

## Acessibilidade

| NFR | Alvo |
|-----|------|
| Conformidade | WCAG 2.1 AA |
| Navegação por teclado | 100% dos fluxos críticos |
| Leitores de tela | Testado com NVDA e VoiceOver nos fluxos críticos |
| Contraste | Mínimo 4.5:1 para texto, 3:1 para ícones funcionais |

## Internacionalização

| NFR | Alvo |
|-----|------|
| Idiomas suportados | pt-BR (default), en-US |
| Datas e números | Formatação por locale do navegador |
| Strings | Externalizadas; nada hardcoded em componentes |

## Compatibilidade

| NFR | Alvo |
|-----|------|
| Navegadores | Últimas 2 versões de Chrome, Firefox, Safari, Edge |
| Resoluções | ≥ 360px de largura |
| Java/JVM | LTS atual em produção |

## Manutenibilidade

| NFR | Alvo |
|-----|------|
| Cobertura de testes | ≥ 70% em código novo (linhas + branches) |
| Tempo de build local | < 2min |
| Tempo de CI | < 10min até deploy de preview |
| Complexidade ciclomática | Função ≤ 10 |
