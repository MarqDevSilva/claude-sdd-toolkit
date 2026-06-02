# Components, Pages & Routing

> Four buckets, by responsibility. Pages are **area-based** (in the app), not per-domain — a page
> may compose several domains.

## The four buckets

| Bucket | Location | Smart? | Talks to state/service? |
|--------|----------|--------|------------------------|
| **Pages** | `apps/*/pages/<area>/` | Smart | Yes — read `state`, call `service` |
| **Layouts** | `apps/*/layouts/` | Mostly dumb | Shell only (header/sidebar/router-outlet) |
| **App components** | `apps/*/components/` | Smart | Yes — app-specific |
| **Shared UI** | `libs/shared/ui/` | Dumb | No — only `input()/output()` |

Rule of thumb: **if it injects a `state`/`service`, it is smart and lives in the app**
(`pages` or `components`). If it only has inputs/outputs, it is dumb and **reusable** → `libs/shared/ui`.

## Pages — area-based, may mix domains

```typescript
// apps/admin/src/app/pages/orders/orders.page.ts
import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { OrderState, OrderService } from '@org/domains/order';
import { CustomerState } from '@org/domains/customer';   // same page, two domains
import { OrderTableComponent } from '@org/shared/ui';

@Component({
  selector: 'app-orders-page',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [OrderTableComponent],
  template: `
    <h1>Orders for {{ customers.itens().length }} customers</h1>
    <app-order-table
      [orders]="orders.itens()"
      [loading]="orders.carregando()"
      (rowClick)="orders.selecionado.set($event)" />
  `,
})
export class OrdersPage {
  protected readonly orders = inject(OrderState);
  protected readonly customers = inject(CustomerState);
  private readonly orderService = inject(OrderService);

  constructor() { this.orderService.listar().subscribe(); }
}
```

## Dumb component — reusable, signal inputs/outputs

```typescript
// libs/shared/ui/order-table/order-table.component.ts
import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { Order } from '@org/domains/order';

@Component({
  selector: 'app-order-table',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (loading()) { <p>Loading…</p> }
    @for (o of orders(); track o.id) {
      <button type="button" (click)="rowClick.emit(o)">{{ o.code }}</button>
    } @empty {
      <p>No orders.</p>
    }
  `,
})
export class OrderTableComponent {
  readonly orders = input.required<Order[]>();
  readonly loading = input(false);
  readonly rowClick = output<Order>();
}
```

> Dumb components never inject `state`/`service` and never call HTTP. They receive data via `input()`
> and report events via `output()`. That is what makes them reusable across apps.

## Layouts — the shell

```typescript
// apps/admin/src/app/layouts/main-layout.component.ts
@Component({
  selector: 'app-main-layout',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet, RouterLink],
  template: `
    <header>…</header>
    <nav><a routerLink="/dashboard">Dashboard</a></nav>
    <main><router-outlet /></main>
  `,
})
export class MainLayoutComponent {}
```

## Routing — lazy pages under a layout

```typescript
// apps/admin/src/app/app.routes.ts
import { Routes } from '@angular/router';
import { MainLayoutComponent } from './layouts/main-layout.component';

export const routes: Routes = [
  {
    path: '',
    component: MainLayoutComponent,
    children: [
      { path: 'dashboard', loadComponent: () =>
          import('./pages/dashboard/dashboard.page').then(m => m.DashboardPage) },
      { path: 'orders', loadComponent: () =>
          import('./pages/orders/orders.page').then(m => m.OrdersPage) },
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
    ],
  },
];
```

```typescript
// apps/admin/src/app/app.config.ts
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { routes } from './app.routes';
import { API_BASE_URL, errorInterceptor, traceIdInterceptor } from '@org/core';
import { environment } from '../environments/environment';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideHttpClient(withInterceptors([traceIdInterceptor, errorInterceptor])),
    { provide: API_BASE_URL, useValue: environment.apiUrl },   // domains read this token
  ],
};
```

## Conventions

- One component per file; `*.page.ts` for routed pages, `*.component.ts` otherwise.
- Selectors prefixed per app/lib (`app-`, or a lib prefix) — enforced by ESLint.
- Prefer the new control flow (`@if`, `@for`, `@switch`) over `*ngIf`/`*ngFor`.
- Keep templates inline for small components; split to `.html` when they grow.
