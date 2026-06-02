# HTTP & Services — HttpClient, API_BASE_URL, ProblemDetails

> There is **no generated API client**. Each domain owns a smart `service` that injects `HttpClient`
> and talks to the backend directly. Models are interfaces 1:1 with the OpenAPI schemas, regenerated
> by the **`api-contract-sync`** skill (which reads the springdoc spec and scaffolds the domain).

## Who may import HttpClient

**Only domain services** inject `HttpClient`. Components, pages, and `state` must not.

```
component / page  →  service  →  HttpClient → backend
                        │
                      state  (signals only, no HttpClient)
```

## Base URL — the `API_BASE_URL` token (monorepo)

A domain lives in `libs/domains` and must **not** import an app's `environment` (that would make a
lib depend on an app). Instead, `libs/core` exposes an injection token; each app provides it from its
own `environment`.

```typescript
// libs/core/tokens/api-base-url.token.ts
import { InjectionToken } from '@angular/core';
export const API_BASE_URL = new InjectionToken<string>('API_BASE_URL');
```

```typescript
// apps/admin/src/app/app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { API_BASE_URL, errorInterceptor, traceIdInterceptor } from '@org/core';
import { environment } from '../environments/environment';

export const appConfig: ApplicationConfig = {
  providers: [
    { provide: API_BASE_URL, useValue: environment.apiUrl },
    provideHttpClient(withInterceptors([traceIdInterceptor, errorInterceptor])),
    // ...
  ],
};
```

```typescript
// libs/domains/product/product.service.ts
private readonly baseUrl = `${inject(API_BASE_URL)}/products`;
```

> The OpenAPI server URL and the per-environment `apiUrl` are owned by `api-contract-sync`, which
> ensures `environment.ts` (dev), `environment.hom.ts`, and `environment.prod.ts` each carry the
> right `apiUrl` and that `API_BASE_URL` is wired in `app.config.ts`.

## Transform & error in the service, never in the component

The service returns `Observable<Dto>`, mutates state via `tap`, and funnels failures through a
single `handleError`. Models are used as-is (no mapper) — the response type **is** the model.

```typescript
listar(): Observable<Product[]> {
  this.iniciarCarregamento();
  return this.http.get<Product[]>(this.baseUrl).pipe(
    tap((itens) => { this.state.itens.set(itens); this.state.carregando.set(false); }),
    catchError((err: HttpErrorResponse) => this.handleError(err)),
  );
}

private handleError(err: HttpErrorResponse): Observable<never> {
  const problem = toProblemDetails(err);
  this.state.erro.set(problem);
  this.state.carregando.set(false);
  return throwError(() => problem);
}
```

## ProblemDetails — RFC 7807 (libs/shared/util)

The backend returns RFC 7807 problem responses. `libs/shared/util` carries the type and a converter
that survives non-conforming error bodies. Keep this in sync with the Spring error contract.

```typescript
// libs/shared/util/problem-details.ts
import { HttpErrorResponse } from '@angular/common/http';

export interface ProblemDetails {
  type: string;
  title: string;
  status: number;
  detail: string;
  instance?: string;
  path?: string;
  method?: string;
  timestamp?: string;
  erros?: Record<string, string>;   // field validation errors
  errorId?: string;
}

export function toProblemDetails(err: HttpErrorResponse): ProblemDetails {
  const body: unknown = err.error;
  if (isProblemDetails(body)) return body;
  return {
    type: 'about:blank',
    title: err.statusText || 'Erro',
    status: err.status ?? 0,
    detail: typeof body === 'string' ? body : err.message,
  };
}

function isProblemDetails(value: unknown): value is ProblemDetails {
  if (typeof value !== 'object' || value === null) return false;
  const c = value as Record<string, unknown>;
  return typeof c['title'] === 'string'
    && typeof c['status'] === 'number'
    && typeof c['detail'] === 'string';
}
```

## Cross-cutting concerns → interceptors (libs/core)

Write these once; they apply to every request.

```typescript
// libs/core/interceptors/error.interceptor.ts — global handling (toast, 401 redirect)
import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { ToastService } from '../toast/toast.service';
import { toProblemDetails } from '@org/shared/util';

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const toast = inject(ToastService);
  return next(req).pipe(
    catchError((err: HttpErrorResponse) => {
      const problem = toProblemDetails(err);
      if (problem.status >= 500) toast.error(problem.title, problem.detail);
      // route 401 → login, etc.
      return throwError(() => err);
    }),
  );
};
```

```typescript
// libs/core/interceptors/trace-id.interceptor.ts
import { HttpInterceptorFn } from '@angular/common/http';

export const traceIdInterceptor: HttpInterceptorFn = (req, next) => {
  const traceId = crypto.randomUUID().replace(/-/g, '');
  return next(req.clone({ setHeaders: {
    traceparent: `00-${traceId}${traceId.slice(0, 16)}-${traceId.slice(0, 16)}-01`,
    'X-Request-Id': traceId,
  }}));
};
```

> The backend reads `traceparent`/`X-Request-Id` into its logs (MDC), correlating front and back.
> Per-screen errors are handled by the service (`state.erro`); the interceptor handles only
> cross-cutting concerns (global toast, auth redirect) so the two don't double-report.

## ToastService (libs/core)

A singleton signal-based toast service lives in `libs/core` and is consumed by interceptors and
smart components for transient notifications (`success`/`error`/`info`/`warning`).

## Handoff

| Concern | Owner |
|---------|-------|
| Produce the OpenAPI spec (springdoc, annotations, error contract) | `spring-boot-engineer/references/openapi.md` |
| Read the spec, scaffold/sync domains (model + state + service + spec), wire environments | `api-contract-sync` |
| Consume it (service, `.pipe`, state, interceptors) | this skill |
