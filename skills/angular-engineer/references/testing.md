# Testing — `.spec.ts` with TestBed

> Plain Angular `.spec.ts` (Jasmine + `TestBed`) is enough for unit and component tests. The default
> native CLI runner works — no extra test framework needed. Run with `ng test`.

## What to test where

| Target | How |
|--------|-----|
| `state` (signals container) | Pure unit — set signals, assert values (rarely needs its own spec) |
| `service` | `HttpTestingController` — call the method, flush the response, assert it updated `state` |
| Dumb component | `TestBed` + `componentRef.setInput()`, assert rendered DOM |
| Smart page/component | `TestBed` with a fake `state`/`service` provided |

The **service** is where the logic lives, so it carries the bulk of the coverage. `api-contract-sync`
scaffolds a `*.service.spec.ts` per domain with this shape.

## Service — `HttpTestingController`

Provide the real `HttpClient` testing backend and the `API_BASE_URL` token; assert both the request
(method/URL/body) and the resulting state.

```typescript
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { API_BASE_URL } from '@org/core';
import { ProblemDetails } from '@org/shared/util';
import { ProductService } from './product.service';
import { ProductState } from './product.state';

const BASE = 'http://localhost:8080/products';

describe('ProductService', () => {
  let service: ProductService;
  let state: ProductState;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: API_BASE_URL, useValue: 'http://localhost:8080' },
      ],
    });
    service = TestBed.inject(ProductService);
    state = TestBed.inject(ProductState);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('listar() GETs /products and feeds the itens signal', () => {
    const itens = [{ id: '1', nome: 'Mouse', preco: 79.9 }];

    service.listar().subscribe();
    const req = http.expectOne(BASE);
    expect(req.request.method).toBe('GET');
    req.flush(itens);

    expect(state.itens()).toEqual(itens);
    expect(state.carregando()).toBeFalse();
    expect(state.erro()).toBeNull();
  });

  it('marks carregando during the request', () => {
    service.listar().subscribe();
    expect(state.carregando()).toBeTrue();
    http.expectOne(BASE).flush([]);
    expect(state.carregando()).toBeFalse();
  });

  it('maps an HTTP error to ProblemDetails in the erro signal', () => {
    let capturado: ProblemDetails | undefined;
    service.listar().subscribe({ error: (e: ProblemDetails) => (capturado = e) });

    http.expectOne(BASE).flush(
      { type: 'about:blank', title: 'Erro interno', status: 500, detail: 'Boom' },
      { status: 500, statusText: 'Internal Server Error' },
    );

    expect(capturado?.status).toBe(500);
    expect(state.erro()?.status).toBe(500);
    expect(state.carregando()).toBeFalse();
  });
});
```

## State — pure unit (only when it has computed logic)

A bare signals container needs no spec. Add one only when the state has `computed` worth asserting:

```typescript
import { ProductState } from './product.state';

it('itens signal holds what was set', () => {
  const state = new ProductState();
  state.itens.set([{ id: '1', nome: 'Mouse', preco: 79.9 }]);
  expect(state.itens().length).toBe(1);
});
```

## Dumb component — set inputs, assert DOM

```typescript
import { TestBed } from '@angular/core/testing';
import { ProductListComponent } from './product-list.component';

it('renders one row per item', () => {
  TestBed.configureTestingModule({ imports: [ProductListComponent] });
  const fixture = TestBed.createComponent(ProductListComponent);
  fixture.componentRef.setInput('items', [
    { id: '1', nome: 'Mouse', preco: 79.9 },
    { id: '2', nome: 'Keyboard', preco: 199 },
  ]);
  fixture.detectChanges();

  expect(fixture.nativeElement.querySelectorAll('div').length).toBe(2);
});
```

## Smart page — fake state + service

Faking signals is trivial: a fake `state` is just an object whose fields are `signal(...)`, and the
`service` is a spy whose methods return `of(...)`.

```typescript
import { TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { of } from 'rxjs';
import { ProductState, ProductService } from '@org/domains/product';
import { DashboardPage } from './dashboard.page';

describe('DashboardPage', () => {
  const service = { listar: jasmine.createSpy('listar').and.returnValue(of([])) };
  const fakeState = {
    itens: signal([{ id: '1', nome: 'Mouse', preco: 79.9 }]),
    carregando: signal(false),
    erro: signal(null),
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [DashboardPage],
      providers: [
        { provide: ProductState, useValue: fakeState },
        { provide: ProductService, useValue: service },
      ],
    });
    TestBed.createComponent(DashboardPage).detectChanges();
  });

  it('loads on init', () => {
    expect(service.listar).toHaveBeenCalled();
  });
});
```

## Running

```bash
ng test                 # all projects (watch)
ng test admin           # one project
ng test --watch=false   # single run (CI)
```

## Conventions

- One `.spec.ts` next to the unit under test (`*.service.spec.ts` is the main one per domain).
- Test behavior, not implementation: assert the request made and the resulting signal values.
- Use `HttpTestingController` for services; never hit a real network. `http.verify()` in `afterEach`.
- Fake the `service` (spy returning `of(...)`) and the `state` (object of `signal(...)`) for pages.
