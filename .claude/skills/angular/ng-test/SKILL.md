---
name: ng-test
description: Escreve testes Angular (Jest ou Karma+Jasmine) cobrindo componentes standalone, services, signal stores e pipes seguindo padrões do projeto.
---

# ng-test

Use quando o usuário pedir pra **escrever testes**, **cobrir testes**, **gerar suíte de teste** para código Angular existente.

## Pré-requisitos

- Identificar runner do projeto: olhar `package.json` por `jest` ou `karma`.
- Convenções de naming em `.spec/memory/conventions.md`.

## O que faz

1. Pergunta (ou detecta) qual arquivo testar.
2. Lê o arquivo + dependências diretas.
3. Cria/atualiza o arquivo `<arquivo>.spec.ts` no mesmo diretório.
4. Estrutura testes em blocos `describe` por responsabilidade.

## Padrões por tipo

### Componente standalone

```typescript
describe('UserCardComponent', () => {
  let component: UserCardComponent;
  let fixture: ComponentFixture<UserCardComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserCardComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(UserCardComponent);
    component = fixture.componentInstance;
  });

  it('emite changed quando o usuário clica em editar', () => {
    fixture.componentRef.setInput('user', { id: '1', name: 'Ana' });
    const spy = jest.fn();
    component.changed.subscribe(spy);
    fixture.detectChanges();

    fixture.nativeElement.querySelector('[data-testid=edit]').click();

    expect(spy).toHaveBeenCalledWith('1');
  });
});
```

### Service com HttpClient

- Usa `HttpTestingController` (`provideHttpClientTesting()`).
- Verifica método, URL, body e responde com `req.flush(...)`.

### Signal store

- Testa **comportamento** do estado, não a implementação dos signals.
- Cada teste: arranja estado → executa ação → assert no `computed` ou `signal()` exposto.

### Pipe

- Testa direto: `expect(new MeuPipe().transform(input)).toBe(output)`.

## Heurísticas

- **Não mocke o que está sendo testado.** Em teste de componente, mocke services; em teste de service, mocke HTTP.
- **Cobre erros**, não só happy path.
- **Sem `fakeAsync` se `await` resolver** — Angular moderno tem APIs nativas, prefira-as.
- Sem `done()` callback — use `async`/`await`.
- Use `data-testid` no template pra selecionar elementos em vez de classes CSS.

## Como invocar

```
/ng-test
/ng-test src/app/features/users/services/user.service.ts
```

## Saída

- Arquivo `.spec.ts` criado/atualizado.
- Resumo dos casos cobertos (lista do `it`).
- Sugestão se algum caminho importante ficou descoberto.
