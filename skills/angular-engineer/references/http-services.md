# API Client — Consuming the Generated OpenAPI Client

> The typed client is **generated** from the backend OpenAPI spec and lives in `libs/api-client`.
> It is **never edited by hand** — regenerate it via the **`api-contract-sync`** skill. The backend
> produces the spec via springdoc (see `spring-boot-engineer/references/openapi.md`).

## Where it lives

```
libs/api-client/            # generated typescript-angular client (a normal lib)
├── src/
│   ├── api/                # one service per backend @Tag (e.g. ProductsApi)
│   ├── model/              # one interface per schema (ProductRequest, ProductResponse, ...)
│   ├── configuration.ts
│   └── index.ts            # public-api → exported as @org/api-client
```

Generation is owned by `api-contract-sync`, e.g.:

```bash
npx @openapitools/openapi-generator-cli generate \
  -i http://localhost:8080/v3/api-docs \
  -g typescript-angular \
  -o libs/api-client/src
```

Commit the generated output so contract diffs surface in PR review. Never put business logic here.

## Who may import it

**Only domain facades** import `@org/api-client`. Components, pages, and `state` must not.

```
component / page  →  facade  →  @org/api-client
                       │
                     state  (no api-client import)
```

## Configure the base path

```typescript
// apps/admin/src/app/app.config.ts
import { BASE_PATH } from '@org/api-client';
import { environment } from '../environments/environment';

providers: [
  // ...
  { provide: BASE_PATH, useValue: environment.apiUrl },
];
```

## Transform in the facade, not in the generated client

The generated service returns raw `Observable<Dto>`. Map to a ViewModel and handle failures in the
facade — never edit the generated file.

```typescript
load(name = ''): void {
  this.state.setLoading(true);
  this.api.search(name).pipe(
    map(list => list.map(toProductVm)),                 // DTO → VM (models.ts)
    catchError(() => { this.state.setError('Failed'); return of([]); }),
    finalize(() => this.state.setLoading(false)),
  ).subscribe(items => this.state.setItems(items));
}
```

## Cross-cutting concerns → interceptors (libs/core)

Write these once; they apply to every request, including the generated client.

```typescript
// libs/core/interceptors/error.interceptor.ts
import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { catchError, throwError } from 'rxjs';

export const errorInterceptor: HttpInterceptorFn = (req, next) =>
  next(req).pipe(
    catchError((err: HttpErrorResponse) => {
      const code = err.error?.code;          // stable contract from the backend ErrorCode
      // route global handling by `code` (toast, redirect on 401, ...)
      return throwError(() => err);
    }),
  );
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
> The `code` field is the contract the frontend branches on — not the human-readable `detail`.

## Optional typed error codes

Mirror the backend `ErrorCode` enum as a TS union so global handling is type-checked. Keep the names
in sync with the backend (they are part of the contract); generate or maintain alongside the client.

## Handoff

| Concern | Owner |
|---------|-------|
| Produce the OpenAPI spec (springdoc, annotations) | `spring-boot-engineer/references/openapi.md` |
| Regenerate the TS client, detect drift/breaking changes | `api-contract-sync` |
| Consume it (facade, `.pipe`, interceptors) | this skill |
