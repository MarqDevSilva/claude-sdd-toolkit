# State & Facades — Signal Store + Orchestration

> Per domain: a **`state`** (signal store, read directly by components) and a **`facade`**
> (async use-cases that call the API client and update the state). The facade is **not** a
> mandatory pass-through for reads — components inject `state` and read its signals directly.

## Responsibilities

| File | Knows about | Role |
|------|-------------|------|
| `<domain>.state.ts` | signals + models | Source of truth: readonly signals, computed, simple mutations |
| `<domain>.facade.ts` | state + api-client | Async use-cases: call API, `.pipe`/map, update state |
| `<domain>.models.ts` | api-client types | ViewModels + mappers (DTO → VM) |

`state` has **no** HTTP/api-client dependency. All async lives in the `facade`.

## State (signal store)

```typescript
import { Injectable, computed, signal } from '@angular/core';
import { ProductVm } from './product.models';

@Injectable({ providedIn: 'root' })
export class ProductState {
  private readonly _items = signal<ProductVm[]>([]);
  private readonly _selectedId = signal<number | null>(null);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  // Read surface — components consume these directly:
  readonly items = this._items.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();
  readonly count = computed(() => this._items().length);
  readonly selected = computed(() =>
    this._items().find(p => p.id === this._selectedId()) ?? null);

  // Mutations — called by the facade (or trivial UI-local updates):
  setItems(items: ProductVm[]): void { this._items.set(items); }
  upsert(item: ProductVm): void {
    this._items.update(list => {
      const i = list.findIndex(p => p.id === item.id);
      return i === -1 ? [...list, item] : list.map(p => p.id === item.id ? item : p);
    });
  }
  select(id: number | null): void { this._selectedId.set(id); }
  setLoading(value: boolean): void { this._loading.set(value); }
  setError(message: string | null): void { this._error.set(message); }
}
```

> Keep the writable signals **private**; expose only `asReadonly()` / `computed()`. Components can
> read freely but cannot mutate state out of band — mutations go through the named methods.

## Facade (async orchestration)

```typescript
import { Injectable, inject } from '@angular/core';
import { catchError, finalize, map, of } from 'rxjs';
import { ProductsApi } from '@org/api-client';
import { ProductState } from './product.state';
import { toProductVm } from './product.models';

@Injectable({ providedIn: 'root' })
export class ProductFacade {
  private readonly api = inject(ProductsApi);
  private readonly state = inject(ProductState);

  load(name = ''): void {
    this.state.setLoading(true);
    this.state.setError(null);
    this.api.search(name).pipe(
      map(list => list.map(toProductVm)),
      catchError(() => { this.state.setError('Failed to load products'); return of([]); }),
      finalize(() => this.state.setLoading(false)),
    ).subscribe(items => this.state.setItems(items));
  }

  create(name: string, price: number): void {
    this.api.create({ name, price }).pipe(
      map(toProductVm),
    ).subscribe(vm => this.state.upsert(vm));
  }
}
```

## How components consume

```typescript
export class ProductsPage {
  protected readonly state = inject(ProductState);   // read
  private readonly facade = inject(ProductFacade);   // command

  constructor() { this.facade.load(); }

  // template: state.items(), state.loading(), state.error()
  refresh(name: string) { this.facade.load(name); }
}
```

- **Read** → `state.items()`, `state.count()`, `state.selected()` (signals, work great with OnPush).
- **Command** → `facade.load()`, `facade.create()` (async, side-effecting).

## Cross-domain composition

A page that mixes domains injects each `state`/`facade` independently — no domain depends on another:

```typescript
protected readonly products = inject(ProductState);
protected readonly orders = inject(OrderState);
```

If two domains genuinely need to react to each other, do it in the **facade** layer (one facade
calls another), never by having one `state` import another.

## Error handling

- **Per-screen** errors (a failed load on this page) → `state.setError(...)` in the facade's
  `catchError`, rendered by the component.
- **Cross-cutting** errors (auth, the backend `code` contract, retries) → an HTTP interceptor in
  `libs/core`, written once. See `references/api-client.md`.

## When to reach for @ngrx/signals

Plain signal stores cover most domains. Consider `@ngrx/signals` (`signalStore`) only when a domain
needs many entities with normalized updates, computed pipelines, or shared store features
(`withEntities`, custom features). The component contract (read signals, call methods) stays the same.
