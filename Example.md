# Commit Message Examples for Microservices

## ✓ Adding New Features

```
payment: add | stripe: refund endpoint

Add endpoint for refund requests
Customers can request refunds up to 30 days after purchase
```

```
auth: add | oauth: google login provider

Support Google OAuth login
Users can sign in with their Google account
```

```
notification: add | email: template engine

Dynamic email template system
Support for custom variables and conditional logic
```

---

## ✓ Bug Fixes

```
inventory: fix | stock: incorrect reservation logic

Fix stock calculation issue during concurrent reservations
Add lock to prevent race conditions
```

```
order: fix | payment: race condition in checkout

Fix double payment issue in checkout
Add idempotency key for duplicate request handling
```

```
auth: fix | jwt: token expiration validation

Fix expired token detection issue
Add more precise timestamp validation
```

---

## ✓ Optimizations

```
notification: optimize | sms: reduce provider latency

Optimize SMS sending with batch processing
Reduce latency from 2 seconds to 200 milliseconds
```

```
payment: optimize | cache: store exchange rates

Cache exchange rates for 1 hour
Reduce API calls to exchange rate service
```

```
gateway: optimize | routing: connection pooling

Use connection pool for better throughput
Reduce overhead of new connections
```

---

## ✓ Security Changes

```
auth: secure | jwt: rotate refresh token strategy

Change refresh token rotation strategy
Automatically rotates every 7 days
```

```
user: secure | password: add rate limiting

Add rate limiting for login attempts
Maximum 5 attempts per 15 minutes
```

```
gateway: secure | cors: restrict origins

Restrict CORS to allowed domains
Remove wildcard origin for better security
```

---

## ✓ Refactoring

```
order: refactor | domain: isolate event handlers

Separate event handlers from business logic
Improve testability and maintainability
```

```
payment: refactor | repository: split query methods

Split repository into query and command
Better separation of concerns
```

```
inventory: refactor | service: extract validation logic

Extract validation logic to separate service
Reduce complexity in main service
```

---

## ✓ API Updates

```
gateway: update | routing: add v2 endpoints

Add v2 endpoints for API
Support v1 for backward compatibility
```

```
auth: update | jwt: rotate access token lifetime

Change access token lifetime from 1 hour to 30 minutes
Improve security and reduce token theft risk
```

```
payment: contract | api: update refund response schema

Update response schema for refund endpoint
Add refund_id and new status fields
```

---

## ✓ Event-Driven Changes

```
order: event | publisher: emit OrderCreatedV2

Publish new event for created orders
Include more detailed information and metadata
```

```
inventory: event | subscriber: handle StockReserved

Consume StockReserved event from inventory service
Update stock in order service
```

```
notification: event | listener: process UserRegistered

Listen for user registration event
Send welcome email automatically
```

---

## ✓ Infrastructure Changes

```
user: infra | docker: add alpine base image

Change base image to Alpine Linux
Reduce image size from 500MB to 150MB
```

```
payment: infra | k8s: add resource limits

Define CPU and memory limits for pods
Prevent resource starvation
```

```
gateway: infra | nginx: configure rate limiting

Configure rate limiting in Nginx
Limit requests to 1000 req/min
```

---

## ✓ Database Changes

```
billing: migration | db: split invoices table

Split invoices table into invoice and invoice_items
Improve query performance and normalization
```

```
order: migration | schema: add order_status index

Add index on order_status column
Improve speed of filtered queries
```

```
user: migration | db: encrypt sensitive fields

Encrypt sensitive fields like SSN
Improve compliance and data security
```

---

## ✓ Documentation

```
auth: docs | api: update login flow schema

Update login flow documentation
Add request/response examples
```

```
payment: docs | webhook: document retry policy

Document webhook retry policy
Explain exponential backoff strategy
```

```
gateway: docs | routing: add service discovery guide

Add service discovery guide for team
How to add new services
```

---

## ✓ Dependencies

```
auth: deps | jwt: upgrade to v9.0.0

Upgrade JWT library to version 9.0.0
Includes security and performance improvements
```

```
payment: deps | stripe: add v12 sdk

Add Stripe SDK v12
Support for new Stripe features
```

```
notification: deps | nodemailer: remove deprecated package

Remove nodemailer (deprecated)
Use nodemailer-express-handlebars instead
```

---

## ✓ Testing & Tooling

```
order: test | integration: add payment flow tests

Add integration tests for payment flow
Coverage increased from 65% to 82%
```

```
auth: tooling | lint: add pre-commit hooks

Add pre-commit hooks for linting
Prevent committing improper code
```

```
inventory: test | unit: improve stock calculation coverage

Improve unit tests for stock calculation
Coverage increased from 70% to 95%
```

---

## ✓ Stabilization

```
inventory: stabilize | stock: prevent negative syncing loop

Fix sync loop causing negative stock
Add validation and circuit breaker
```

```
gateway: stabilize | circuit-breaker: handle service failures

Implement circuit breaker pattern
Prevent cascade failures
```

```
notification: stabilize | queue: add dead letter handling

Add dead letter queue for failed messages
Improve reliability and observability
```

---

## 💡 Custom Change Types

```
payment: reconcile | ledger: sync failed transactions

reconcile = reconcile and synchronize
Use for syncing failed transactions
```

```
inventory: recount | stock: manual inventory audit

recount = recount
Use for manual audit and verification
```

```
order: cancel | fulfillment: handle customer request

cancel = cancel
Use for order cancellations
```

---

## 🌍 Project-Level Changes (Using `root`)

### Infrastructure & Configuration

```
root: infra | docker-compose: add services configuration

Add Docker Compose file for local development
Includes auth, payment, notification, and gateway services
```

```
root: config | env: add environment variables template

Add .env.example file for environment setup
Document required variables for all services
```

```
root: config | gitignore: exclude build artifacts

Add .gitignore for common artifacts
Exclude node_modules, .env, build files, and IDE configs
```

### CI/CD & Automation

```
root: infra | ci-cd: add github actions workflow

Add GitHub Actions for automated testing and deployment
Runs tests on every push and deploys on main branch
```

```
root: tooling | makefile: add development commands

Add Makefile with common development tasks
Includes build, test, lint, and run commands
```

### Documentation & Setup

```
root: docs | contributing: add contribution guidelines

Add CONTRIBUTING.md for team guidelines
Document code style, commit conventions, and PR process
```

```
root: docs | setup: add local development guide

Add setup instructions for new developers
Include Docker, environment variables, and database setup
```

### Dependencies & Versions

```
root: deps | package: add shared dependencies

Add package.json with shared dependencies
Includes linting, testing, and build tools
```

```
root: config | docker: add base image configuration

Add Dockerfile for base image
Shared across all microservices
```
