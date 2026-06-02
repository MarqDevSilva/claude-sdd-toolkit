# State & Services — Signals Container + Smart Service

> Per domain: a **`state`** (a plain container of signals, read directly by components) and a
> **`service`** (async use-cases that call `HttpClient` and mutate the state). The service is **not**
> a mandatory pass-through for reads — components inject `state` and read its signals directly.

## Responsibilities

| File | Knows about | Role |
|------|-------------|------|
| `<domain>.state.ts` | signals + its own model | Source of truth: public writable signals + `computed` |
| `<domain>.service.ts` | state + `HttpClient` + `API_BASE_URL` + `ProblemDetails` | Async use-cases: call the API, `.pipe(tap/catchError)`, mutate state |
| `<domain>.model.ts` | nothing | Interfaces 1:1 with the backend schemas (no ViewModel/mapper) |

`state` has **no** HTTP dependency. All async lives in the `service`. The `service` is the **only**
writer of the state.

## State (signals container)

Signals are **public and writable**. There is no `asReadonly()` / named-mutation indirection — the
service is the only writer by convention (enforced in review), and components only read.

```typescript
import { Injectable, signal } from '@angular/core';
import { ProblemDetails } from '@org/shared/util';
import { Categoria } from './categoria.model';

@Injectable({ providedIn: 'root' })
export class CategoriaState {
  readonly raizes = signal<Categoria[]>([]);
  readonly filhosPorPath = signal<Record<string, Categoria[]>>({});
  readonly selecionada = signal<Categoria | null>(null);
  readonly carregando = signal(false);
  readonly erro = signal<ProblemDetails | null>(null);
}
```

> Need derived values? Add `computed(...)` here (e.g. `readonly total = computed(() =>
> this.raizes().length)`). Keep them in the state, alongside the signals they derive from.

## Service (async orchestration over HttpClient)

The service injects `HttpClient`, builds its `baseUrl` from `API_BASE_URL`, and mutates the state
inside `tap`. Every call funnels failures through a single `handleError` that writes `state.erro`.

```typescript
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable, catchError, of, tap, throwError } from 'rxjs';
import { API_BASE_URL } from '@org/core';
import { toProblemDetails } from '@org/shared/util';
import { Categoria, CriarCategoriaRequest } from './categoria.model';
import { CategoriaState } from './categoria.state';

@Injectable({ providedIn: 'root' })
export class CategoriaService {
  private readonly http = inject(HttpClient);
  private readonly state = inject(CategoriaState);
  private readonly baseUrl = `${inject(API_BASE_URL)}/categorias`;

  listarRaizes(): Observable<Categoria[]> {
    this.iniciarCarregamento();
    return this.http.get<Categoria[]>(`${this.baseUrl}/main`).pipe(
      tap((raizes) => {
        this.state.raizes.set(raizes);
        this.state.carregando.set(false);
      }),
      catchError((err: HttpErrorResponse) => this.handleError(err)),
    );
  }

  // Cache, optimistic updates, cascade invalidation — domain logic lives here, hand-written.
  listarFilhos(path: string): Observable<Categoria[]> {
    const cache = this.state.filhosPorPath()[path];
    if (cache) {
      return of(cache);
    }
    this.iniciarCarregamento();
    return this.http.get<Categoria[]>(`${this.baseUrl}/children/${path}`).pipe(
      tap((filhos) => {
        this.state.filhosPorPath.update((atual) => ({ ...atual, [path]: filhos }));
        this.state.carregando.set(false);
      }),
      catchError((err: HttpErrorResponse) => this.handleError(err)),
    );
  }

  criar(request: CriarCategoriaRequest): Observable<Categoria> {
    this.iniciarCarregamento();
    return this.http.post<Categoria>(this.baseUrl, request).pipe(
      tap((nova) => {
        this.state.raizes.update((atual) => [...atual, nova]);
        this.state.carregando.set(false);
      }),
      catchError((err: HttpErrorResponse) => this.handleError(err)),
    );
  }

  private iniciarCarregamento(): void {
    this.state.carregando.set(true);
    this.state.erro.set(null);
  }

  private handleError(err: HttpErrorResponse): Observable<never> {
    const problem = toProblemDetails(err);
    this.state.erro.set(problem);
    this.state.carregando.set(false);
    return throwError(() => problem);
  }
}
```

> Service methods **return the Observable** (and mutate state via `tap`). Callers `subscribe()` when
> they want to react to completion/error; the page usually just calls `service.listar().subscribe()`
> and reads `state` for the result. This is what makes the service unit-testable with
> `HttpTestingController` (see `references/testing.md`).

## How components consume

```typescript
export class CategoriasPage {
  protected readonly state = inject(CategoriaState);   // read
  private readonly service = inject(CategoriaService); // command

  constructor() { this.service.listarRaizes().subscribe(); }

  // template: state.raizes(), state.carregando(), state.erro()
  selecionar(c: Categoria) { this.state.selecionada.set(c); }   // trivial UI-local read/select
}
```

- **Read** → `state.raizes()`, `state.carregando()`, `state.erro()` (signals, great with OnPush).
- **Command** → `service.listarRaizes()`, `service.criar()` (async, side-effecting, mutate state).

> Trivial UI-local selection (`state.selecionada.set(...)`) directly from a component is fine — it is
> not an async use-case. Anything that touches the network goes through the service.

## Cross-domain composition

A page that mixes domains injects each `state`/`service` independently — no domain depends on another:

```typescript
protected readonly products = inject(ProductState);
protected readonly orders = inject(OrderState);
```

If two domains genuinely need to react to each other, do it in the **service** layer (one service
calls another), never by having one `state` import another.

## Error handling

- **Per-screen** errors → the service's `handleError` writes a `ProblemDetails` into `state.erro`,
  rendered by the component (e.g. `@if (state.erro(); as e) { <app-alert [problem]="e" /> }`).
- **Cross-cutting** errors (auth/401 redirect, global toast, retries) → an HTTP interceptor in
  `libs/core`, written once. See `references/http-services.md`.

`ProblemDetails` / `toProblemDetails` live in `libs/shared/util` and follow RFC 7807, matching the
Spring backend error contract.

## When to reach for @ngrx/signals

Plain signal containers cover most domains. Consider `@ngrx/signals` (`signalStore`) only when a
domain needs many entities with normalized updates, computed pipelines, or shared store features
(`withEntities`). The component contract (read signals, call the service) stays the same.
