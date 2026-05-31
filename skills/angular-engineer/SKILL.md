---
name: angular-engineer
description: Generates Angular 18+ applications in a native Angular CLI monorepo (apps + libs), organized by bounded-context domains with signal-based state and facades, area-based smart pages/layouts/components, a generated OpenAPI client library, and standardized ESLint/Prettier + Jasmine/TestBed testing. Use when building Angular monorepo apps; invoke for project structure, signal state management, facades, consuming a generated API client, lint/format setup, or component/unit testing.
license: MIT
metadata:
  version: "1.0.0"
  domain: frontend
  triggers: Angular, Angular monorepo, signals, signal store, facade, standalone components, OpenAPI client, ESLint, Prettier, TestBed
  role: specialist
  scope: implementation
  output-format: code
  related-skills: api-contract-sync, spring-boot-engineer
---

# Angular Engineer

Angular 18+, **standalone components**, **signals**, native **Angular CLI workspace** (multi-project
monorepo). No NgModules, no Nx.

## Core Workflow

1. **Analyze** — Identify domains (mirror the backend bounded contexts), route areas (pages, which
   may mix domains), and reusable UI. Confirm the map before coding
2. **Structure** — Place code by responsibility (see Project Structure): domain logic in
   `libs/domains`, pages/layouts/components in the app, reusable dumb UI in `libs/shared`, the
   generated API client in `libs/api-client`, singletons in `libs/core`
3. **Implement** — One `state` (signals) + `facade` (async orchestration) per domain. Smart
   components read `state` directly and trigger use-cases via `facade` (see Quick Start)
4. **Lint & format** — `ng lint` (ESLint flat config) + Prettier; fix before proceeding
5. **Test** — `.spec.ts` with `TestBed`; mock facade/state signals; run `ng test` and confirm green

## Project Structure

Native Angular CLI workspace: thin **apps** consume shared **libs**. Domains mirror the backend
bounded contexts.

```
workspace/
├── apps/
│   ├── admin/src/app/
│   │   ├── pages/          # routed pages — compose 1..N domains (areas, NOT per-domain)
│   │   │   ├── dashboard/
│   │   │   └── orders/
│   │   ├── layouts/        # shell: header, sidebar, auth layout
│   │   ├── components/     # app-specific smart components (read state, call facade)
│   │   └── app.routes.ts
│   └── portal/src/app/ ...
└── libs/
    ├── core/               # singletons: interceptors, guards, app config/providers (imported once)
    ├── shared/
    │   ├── ui/             # reusable DUMB components, directives, pipes
    │   └── util/           # pure helpers, types, RxJS operators
    ├── api-client/         # GENERATED OpenAPI client (api-contract-sync) — never edited by hand
    └── domains/            # single lib, one folder per bounded context
        ├── product/
        │   ├── product.state.ts    # signal store: readonly signals + simple mutations
        │   ├── product.facade.ts   # async use-cases: api-client → .pipe → update state
        │   ├── product.models.ts   # ViewModels + mappers from api-client types
        │   └── index.ts            # barrel: exports state, facade, models
        └── order/ ...
```

**Dependency rule** (enforce in reviews):
`app → domains` (state + facade) and `app → shared`/`core`. `domains.facade → api-client`.
`state` never imports `api-client`. `shared`/`core` never import `domains`. `domains` never imports `app`.

**Read vs command**: components inject `state` directly to **read** signals; they call the `facade`
to **trigger async use-cases**. The facade is not a mandatory pass-through for reads.

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| State & Facades | `references/state-management.md` | Signal state, facade orchestration, loading/error flags |
| Components & Pages | `references/components.md` | Pages, layouts, smart vs dumb components, routing |
| API Client | `references/api-client.md` | Consuming the generated client, `.pipe`, interceptors |
| Lint & Format | `references/lint-format.md` | ESLint flat config, Prettier, npm scripts |
| Testing | `references/testing.md` | `.spec.ts`, TestBed, mocking facade/state signals |

## Quick Start — A Domain + A Page

### Domain state — `libs/domains/product/product.state.ts`

```typescript
import { Injectable, computed, signal } from '@angular/core';
import { ProductVm } from './product.models';

@Injectable({ providedIn: 'root' })
export class ProductState {
  private readonly _items = signal<ProductVm[]>([]);
  private readonly _loading = signal(false);

  // Components read these directly:
  readonly items = this._items.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly count = computed(() => this._items().length);

  // Simple mutations (called by the facade):
  setItems(items: ProductVm[]): void { this._items.set(items); }
  setLoading(value: boolean): void { this._loading.set(value); }
}
```

### Domain facade — `libs/domains/product/product.facade.ts`

```typescript
import { Injectable, inject } from '@angular/core';
import { finalize, map } from 'rxjs';
import { ProductsApi } from '@org/api-client';          // generated client
import { ProductState } from './product.state';
import { toProductVm } from './product.models';

@Injectable({ providedIn: 'root' })
export class ProductFacade {
  private readonly api = inject(ProductsApi);
  private readonly state = inject(ProductState);

  load(name = ''): void {
    this.state.setLoading(true);
    this.api.search(name).pipe(
      map(list => list.map(toProductVm)),               // DTO → ViewModel
      finalize(() => this.state.setLoading(false)),
    ).subscribe(items => this.state.setItems(items));
  }
}
```

### Models — `libs/domains/product/product.models.ts`

```typescript
import { ProductResponse } from '@org/api-client';

export interface ProductVm { id: number; name: string; price: number; }

export const toProductVm = (p: ProductResponse): ProductVm => ({
  id: p.id!, name: p.name!, price: p.price!,
});
```

### Barrel — `libs/domains/product/index.ts`

```typescript
export * from './product.state';
export * from './product.facade';
export * from './product.models';
```

### Page (mixes domains) — `apps/admin/src/app/pages/dashboard/dashboard.page.ts`

```typescript
import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { ProductState, ProductFacade } from '@org/domains/product';
import { OrderState, OrderFacade } from '@org/domains/order';
import { ProductListComponent } from '@org/shared/ui';

@Component({
  selector: 'app-dashboard-page',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ProductListComponent],
  template: `
    <app-product-list [items]="products.items()" [loading]="products.loading()" />
    <p>Orders: {{ orders.count() }}</p>
  `,
})
export class DashboardPage {
  protected readonly products = inject(ProductState);   // read state directly
  protected readonly orders = inject(OrderState);
  private readonly productFacade = inject(ProductFacade);
  private readonly orderFacade = inject(OrderFacade);

  constructor() {
    this.productFacade.load();                          // trigger use-cases via facade
    this.orderFacade.load();
  }
}
```

### Dumb component — `libs/shared/ui/product-list/product-list.component.ts`

```typescript
import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { ProductVm } from '@org/domains/product';

@Component({
  selector: 'app-product-list',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (loading()) { <p>Loading…</p> }
    @for (p of items(); track p.id) { <div>{{ p.name }} — {{ p.price }}</div> }
  `,
})
export class ProductListComponent {
  readonly items = input.required<ProductVm[]>();
  readonly loading = input(false);
}
```

## Constraints

### MUST DO

| Rule | Correct Pattern |
|------|----------------|
| Standalone + OnPush | `standalone: true`, `changeDetection: ChangeDetectionStrategy.OnPush` |
| Signals for state | `signal()` / `computed()`; expose `asReadonly()` from `state` |
| `inject()` over constructor params | `private readonly x = inject(X)` |
| Inputs/outputs as signals | `input.required<T>()`, `input<T>()`, `output<T>()` |
| Read state directly | Components inject `state` and read signals; no forced facade pass-through |
| Async via facade | API calls + `.pipe` + state updates live in the `facade`, not in components |
| Pages by area | Routed pages live in `apps/*/pages` grouped by area; a page may compose several domains |
| Dumb UI is reusable | Presentational components with only `input()/output()` go in `libs/shared/ui` |

### MUST NOT DO

- Use NgModules — everything is standalone
- Call the generated `api-client` from a component — only facades touch it
- Import `api-client` into `state` — `state` stays free of HTTP concerns
- Mutate a signal that a component received as input — inputs are read-only
- Put domain/business logic in `apps/*` — it belongs in `libs/domains`
- Create circular deps — `shared`/`core` must not import `domains`
- Edit files under `libs/api-client` — they are generated (regenerate via `api-contract-sync`)
- Group pages by domain when a page needs more than one domain — keep pages in the app, by area
