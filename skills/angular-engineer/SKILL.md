---
name: angular-engineer
description: Generates Angular 18+ applications in a native Angular CLI monorepo (apps + libs), organized by bounded-context domains with signal-based state and smart services that call HttpClient and sync state directly, area-based smart pages/layouts/components, RFC 7807 (ProblemDetails) error handling, and standardized ESLint/Prettier + Jasmine/TestBed testing. Use when building Angular monorepo apps; invoke for project structure, signal state management, smart domain services over HttpClient, ProblemDetails error handling, lint/format setup, or component/unit testing.
license: MIT
metadata:
  version: "2.0.0"
  domain: frontend
  triggers: Angular, Angular monorepo, signals, signal store, smart service, HttpClient, ProblemDetails, standalone components, ESLint, Prettier, TestBed
  role: specialist
  scope: implementation
  output-format: code
  related-skills: api-contract-sync, spring-boot-engineer
---

# Angular Engineer

Angular 18+, **standalone components**, **signals**, native **Angular CLI workspace** (multi-project
monorepo). No NgModules, no Nx. No generated API client — each domain owns a **smart service** that
talks to `HttpClient` directly and syncs its signal `state`.

## Core Workflow

1. **Analyze** — Identify domains (mirror the backend bounded contexts), route areas (pages, which
   may mix domains), and reusable UI. Confirm the map before coding
2. **Structure** — Place code by responsibility (see Project Structure): domain logic in
   `libs/domains`, pages/layouts/components in the app, reusable dumb UI in `libs/shared/ui`,
   shared types/helpers (e.g. `ProblemDetails`) in `libs/shared/util`, singletons (interceptors,
   `ToastService`, the `API_BASE_URL` token) in `libs/core`
3. **Implement** — Per domain: a `state` (a plain container of signals) + a `service` (injects
   `HttpClient`, calls the backend over `environment`/`API_BASE_URL`, and mutates the state inside
   `.pipe(tap(...), catchError(...))`). Smart components read `state` directly and trigger use-cases
   via the `service` (see Quick Start)
4. **Lint & format** — `ng lint` (ESLint flat config) + Prettier; fix before proceeding
5. **Test** — `.spec.ts` with `TestBed`; test the service with `HttpTestingController`; run
   `ng test` and confirm green

## Project Structure

Native Angular CLI workspace: thin **apps** consume shared **libs**. Domains mirror the backend
bounded contexts. There is **no `api-client` lib** — domains call `HttpClient` directly.

```
workspace/
├── apps/
│   ├── admin/src/app/
│   │   ├── pages/          # routed pages — compose 1..N domains (areas, NOT per-domain)
│   │   │   ├── dashboard/
│   │   │   └── orders/
│   │   ├── layouts/        # shell: header, sidebar, auth layout
│   │   ├── components/     # app-specific smart components (read state, call service)
│   │   └── app.routes.ts
│   │   └── app.config.ts   # provides API_BASE_URL from this app's environment
│   ├── admin/src/environments/   # environment.ts (dev) + .hom.ts + .prod.ts — apiUrl per env
│   └── portal/src/app/ ...
└── libs/
    ├── core/               # singletons: interceptors, guards, ToastService, API_BASE_URL token
    ├── shared/
    │   ├── ui/             # reusable DUMB components, directives, pipes
    │   └── util/           # pure helpers + types: ProblemDetails, toProblemDetails, RxJS ops
    └── domains/            # single lib, one folder per bounded context
        ├── product/
        │   ├── product.state.ts     # signals container (writable signals, mutated by the service)
        │   ├── product.service.ts    # HttpClient + async use-cases → tap/catchError → state
        │   ├── product.model.ts      # interfaces 1:1 with the backend schemas (no ViewModel/mapper)
        │   ├── product.service.spec.ts  # HttpTestingController coverage of the service
        │   └── index.ts             # barrel: exports model, service, state
        └── order/ ...
```

**Dependency rule** (enforce in reviews):
`app → domains` (state + service) and `app → shared`/`core`. `domains.service → HttpClient` +
`API_BASE_URL` (from `core`) + `ProblemDetails` (from `shared/util`). `state` imports **only** its
own model — never `HttpClient`. `shared`/`core` never import `domains`. `domains` never import
`app` (so a domain reads the base URL via the `API_BASE_URL` token, not an app's `environment`).

**Read vs command**: components inject `state` directly to **read** signals; they call the `service`
to **trigger async use-cases**. The service is not a mandatory pass-through for reads.

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| State & Services | `references/state-management.md` | Signals container, service orchestration, loading/error signals |
| Components & Pages | `references/components.md` | Pages, layouts, smart vs dumb components, routing |
| HTTP & Services | `references/http-services.md` | `HttpClient`, `API_BASE_URL`, `ProblemDetails`, interceptors |
| Lint & Format | `references/lint-format.md` | ESLint flat config, Prettier, npm scripts |
| Testing | `references/testing.md` | `.spec.ts`, TestBed, `HttpTestingController`, faking state |

## Quick Start — A Domain + A Page

### Domain state — `libs/domains/product/product.state.ts`

The state is a **plain container of signals**. Signals are public and writable; the **service** is
the only writer (mutating them inside its `.pipe`). Components read them directly.

```typescript
import { Injectable, signal } from '@angular/core';
import { ProblemDetails } from '@org/shared/util';
import { Product } from './product.model';

@Injectable({ providedIn: 'root' })
export class ProductState {
  readonly itens = signal<Product[]>([]);
  readonly selecionado = signal<Product | null>(null);
  readonly carregando = signal(false);
  readonly erro = signal<ProblemDetails | null>(null);
}
```

### Domain service — `libs/domains/product/product.service.ts`

```typescript
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Observable, catchError, tap, throwError } from 'rxjs';
import { API_BASE_URL } from '@org/core';
import { toProblemDetails } from '@org/shared/util';
import { Product, CriarProductRequest } from './product.model';
import { ProductState } from './product.state';

@Injectable({ providedIn: 'root' })
export class ProductService {
  private readonly http = inject(HttpClient);
  private readonly state = inject(ProductState);
  private readonly baseUrl = `${inject(API_BASE_URL)}/products`;

  listar(): Observable<Product[]> {
    this.iniciarCarregamento();
    return this.http.get<Product[]>(this.baseUrl).pipe(
      tap((itens) => {
        this.state.itens.set(itens);
        this.state.carregando.set(false);
      }),
      catchError((err: HttpErrorResponse) => this.handleError(err)),
    );
  }

  criar(request: CriarProductRequest): Observable<Product> {
    this.iniciarCarregamento();
    return this.http.post<Product>(this.baseUrl, request).pipe(
      tap((novo) => {
        this.state.itens.update((atual) => [...atual, novo]);
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

### Models — `libs/domains/product/product.model.ts`

Interfaces map **1:1** to the backend schemas (no ViewModel, no mapper). `api-contract-sync`
regenerates this file from the OpenAPI spec.

```typescript
export interface Product {
  id: string;
  nome: string;
  preco: number;
}

export interface CriarProductRequest {
  nome: string;
  preco: number;
}
```

### Barrel — `libs/domains/product/index.ts`

```typescript
export * from './product.model';
export * from './product.service';
export * from './product.state';
```

### Page (mixes domains) — `apps/admin/src/app/pages/dashboard/dashboard.page.ts`

```typescript
import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { ProductState, ProductService } from '@org/domains/product';
import { OrderState, OrderService } from '@org/domains/order';
import { ProductListComponent } from '@org/shared/ui';

@Component({
  selector: 'app-dashboard-page',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ProductListComponent],
  template: `
    <app-product-list [items]="products.itens()" [loading]="products.carregando()" />
    <p>Orders: {{ orders.itens().length }}</p>
  `,
})
export class DashboardPage {
  protected readonly products = inject(ProductState);   // read state directly
  protected readonly orders = inject(OrderState);
  private readonly productService = inject(ProductService);
  private readonly orderService = inject(OrderService);

  constructor() {
    this.productService.listar().subscribe();           // trigger use-cases via service
    this.orderService.listar().subscribe();
  }
}
```

### Dumb component — `libs/shared/ui/product-list/product-list.component.ts`

```typescript
import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { Product } from '@org/domains/product';

@Component({
  selector: 'app-product-list',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (loading()) { <p>Loading…</p> }
    @for (p of items(); track p.id) { <div>{{ p.nome }} — {{ p.preco }}</div> }
  `,
})
export class ProductListComponent {
  readonly items = input.required<Product[]>();
  readonly loading = input(false);
}
```

## Constraints

### MUST DO

| Rule | Correct Pattern |
|------|----------------|
| Standalone + OnPush | `standalone: true`, `changeDetection: ChangeDetectionStrategy.OnPush` |
| Signals for state | `signal()` / `computed()` inside the domain `state` |
| `inject()` over constructor params | `private readonly x = inject(X)` |
| Inputs/outputs as signals | `input.required<T>()`, `input<T>()`, `output<T>()` |
| Read state directly | Components inject `state` and read signals; no forced service pass-through |
| Async via service | HTTP calls + `.pipe` + state mutations live in the `service`, not in components |
| Service is the only writer | The `service` mutates state inside `tap`; on error sets `state.erro` via `handleError` |
| Base URL via token | Domains read `API_BASE_URL` (from `core`), never import an app's `environment` |
| Errors as ProblemDetails | Map `HttpErrorResponse` → `ProblemDetails` (RFC 7807) into `state.erro` |
| Pages by area | Routed pages live in `apps/*/pages` grouped by area; a page may compose several domains |
| Dumb UI is reusable | Presentational components with only `input()/output()` go in `libs/shared/ui` |

### MUST NOT DO

- Use NgModules — everything is standalone
- Call `HttpClient` from a component — only the domain `service` touches it
- Inject `HttpClient` into `state` — `state` is a pure signals container, no HTTP concerns
- Import an app's `environment` into a `libs/domains` service — read the base URL via `API_BASE_URL`
- Add a ViewModel/mapper layer — models are 1:1 with the backend schemas (regenerated by `api-contract-sync`)
- Mutate a signal that a component received as input — inputs are read-only
- Put domain/business logic in `apps/*` — it belongs in `libs/domains`
- Create circular deps — `shared`/`core` must not import `domains`
- Hand-edit `*.model.ts` — they are regenerated from the OpenAPI spec via `api-contract-sync`
- Group pages by domain when a page needs more than one domain — keep pages in the app, by area
