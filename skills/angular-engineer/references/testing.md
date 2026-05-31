# Testing — `.spec.ts` with TestBed

> Plain Angular `.spec.ts` (Jasmine + `TestBed`) is enough for unit and component tests. The default
> native CLI runner works — no extra test framework needed. Run with `ng test`.

## What to test where

| Target | How |
|--------|-----|
| `state` (signal store) | Pure unit — call methods, assert signal values |
| `facade` | Mock `api-client` with `of(...)`, assert it updates the injected `state` |
| Dumb component | `TestBed` + `componentRef.setInput()`, assert rendered DOM |
| Smart page/component | `TestBed` with a fake `state`/`facade` provided |

## State (signal store) — pure unit

```typescript
import { ProductState } from './product.state';

describe('ProductState', () => {
  let state: ProductState;
  beforeEach(() => { state = new ProductState(); });

  it('exposes items and count after setItems', () => {
    state.setItems([{ id: 1, name: 'Mouse', price: 79.9 }]);
    expect(state.items().length).toBe(1);
    expect(state.count()).toBe(1);
  });

  it('upsert replaces an existing item', () => {
    state.setItems([{ id: 1, name: 'Mouse', price: 79.9 }]);
    state.upsert({ id: 1, name: 'Mouse Pro', price: 99 });
    expect(state.items()[0].name).toBe('Mouse Pro');
    expect(state.count()).toBe(1);
  });
});
```

## Facade — mock the generated client

```typescript
import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { ProductsApi } from '@org/api-client';
import { ProductFacade } from './product.facade';
import { ProductState } from './product.state';

describe('ProductFacade', () => {
  let facade: ProductFacade;
  let state: ProductState;
  const api = { search: jasmine.createSpy('search') };

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        ProductFacade,
        ProductState,
        { provide: ProductsApi, useValue: api },
      ],
    });
    facade = TestBed.inject(ProductFacade);
    state = TestBed.inject(ProductState);
  });

  it('load() maps DTOs into state and clears loading', () => {
    api.search.and.returnValue(of([{ id: 1, name: 'Mouse', price: 79.9 }]));

    facade.load();

    expect(state.items()).toEqual([{ id: 1, name: 'Mouse', price: 79.9 }]);
    expect(state.loading()).toBeFalse();
  });
});
```

## Dumb component — set inputs, assert DOM

```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ProductListComponent } from './product-list.component';

describe('ProductListComponent', () => {
  let fixture: ComponentFixture<ProductListComponent>;

  beforeEach(() => {
    TestBed.configureTestingModule({ imports: [ProductListComponent] });
    fixture = TestBed.createComponent(ProductListComponent);
  });

  it('renders one row per item', () => {
    fixture.componentRef.setInput('items', [
      { id: 1, name: 'Mouse', price: 79.9 },
      { id: 2, name: 'Keyboard', price: 199 },
    ]);
    fixture.detectChanges();

    const rows = fixture.nativeElement.querySelectorAll('div');
    expect(rows.length).toBe(2);
  });
});
```

## Smart page — fake state + facade

```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { ProductState, ProductFacade } from '@org/domains/product';
import { DashboardPage } from './dashboard.page';

describe('DashboardPage', () => {
  let fixture: ComponentFixture<DashboardPage>;
  const facade = { load: jasmine.createSpy('load') };
  const fakeState = {
    items: signal([{ id: 1, name: 'Mouse', price: 79.9 }]),
    loading: signal(false),
    count: signal(1),
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [DashboardPage],
      providers: [
        { provide: ProductState, useValue: fakeState },
        { provide: ProductFacade, useValue: facade },
      ],
    });
    fixture = TestBed.createComponent(DashboardPage);
    fixture.detectChanges();
  });

  it('loads on init', () => {
    expect(facade.load).toHaveBeenCalled();
  });
});
```

> Faking signals is trivial: a fake `state` is just an object whose fields are `signal(...)`. The
> component reads them the same way (`state.items()`), so the test needs no real store.

## Running

```bash
ng test                 # all projects (watch)
ng test admin           # one project
ng test --watch=false   # single run (CI)
```

## Conventions

- One `.spec.ts` next to the unit under test.
- Test behavior, not implementation: assert rendered output / resulting signal values, not internals.
- Mock the `api-client` and the `facade` at the boundary; never hit a real network in unit tests.
- Keep `state` tests dependency-free (plain `new State()`), no `TestBed` needed.
