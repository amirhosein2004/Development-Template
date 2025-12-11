# 🔥 Commit Message Convention for Microservices

## 📋 Structure

```
<service>: <change-type> | <module/domain>: <summary>

<body (optional)>
```

**Example:**
```
auth: secure | jwt: rotate signing keys

Add rotation strategy for refresh tokens
Automatically rotates every 7 days
```

---

## ⚠️ Important Rules

### 🔤 Single Word Rule
- **Service** must be **one word** (e.g., `auth` not `auth-service`)
- **Change Type** must be **one word** (e.g., `add` not `add-feature`)
- **Module/Domain** must be **one word** (e.g., `jwt` not `jwt-handler`)

### 💡 If No Matching Change Type
If none of the predefined change-types fit your change, add **one meaningful word**:

```
payment: reconcile | ledger: sync failed transactions
inventory: recount | stock: manual inventory audit
order: cancel | fulfillment: handle customer request
```

### 💡 If No Service
For project-level files like env,ci/cdm,.. (not specific to any service), use `root`

### 📝 Body (Optional)
If the first line isn't enough, add more details:
- Why this change was necessary
- What problem it solves
- Side effects or important notes

---

## 🧩 Commit Components

### 1️⃣ Service (Microservice) - One Word
The exact name of the microservice:
- `auth` - Authentication
- `payment` - Payment Processing
- `notification` - Notifications
- `gateway` - API Gateway
- `inventory` - Inventory Management
- `order` - Order Management

**For project-level files (not specific to any service), use `root`:**
- `root` - Project-level configuration, infrastructure, or setup files
  - Docker Compose, .gitignore, .env files
  - CI/CD pipelines, Makefiles, scripts
  - Project-wide documentation

### 2️⃣ Change Type (Type of Change) - One Word

#### 📝 Development
| Type | Usage |
|------|-------|
| `add` | Adding new feature, endpoint, or file |
| `update` | Regular changes, updating part of behavior |
| `refactor` | Changing internal structure without changing external behavior |
| `remove` | Removing code, feature, file, or endpoint |

#### 🎯 Quality & Stability
| Type | Usage |
|------|-------|
| `fix` | Bug fix |
| `improve` | Improving quality or readability |
| `optimize` | Optimizing speed and performance |
| `stabilize` | Increasing reliability, preventing crashes |

#### 🏗️ Architecture & Infrastructure
| Type | Usage |
|------|-------|
| `infra` | Infrastructure changes (Docker, K8s, CI/CD) |
| `config` | Configuration, environment, or secrets changes |
| `migration` | Database schema or migration changes |
| `deps` | Adding/removing/updating dependencies |

#### 🔐 Security
| Type | Usage |
|------|-------|
| `secure` | Security patches, hardening |
| `audit` | Security logging, audit trail |

#### 🔗 Service Communication
| Type | Usage |
|------|-------|
| `contract` | API contract, DTO, or schema changes |
| `event` | Event, topic, or pub/sub changes |
| `integration` | Integration with external or internal services |

#### 🛠️ Developer Experience
| Type | Usage |
|------|-------|
| `docs` | Documentation changes |
| `test` | Adding or updating tests |
| `tooling` | Linters, formatters, git hooks, dev tools |

### 3️⃣ Module/Domain (Component) - One Word
**The important part that changed.** This can be:

- **Technical layers:** `jwt`, `cache`, `queue`, `repository`
- **External services:** `stripe`, `twilio`, `sendgrid`
- **Business entities:** `stock`, `invoice`, `order`, `user`
- **Architecture components:** `api`, `worker`, `scheduler`, `webhook`
- **Project-level components (when using `root`):** `docker-compose`, `env`, `gitignore`, `makefile`, `ci-cd`

**Examples:**
- `auth: update | jwt: rotate access token lifetime` → JWT changed
- `payment: add | stripe: refund endpoint` → Stripe integration changed
- `inventory: fix | stock: incorrect reservation logic` → Stock logic changed
- `order: refactor | repository: split query methods` → Repository pattern changed
- `notification: optimize | sms: reduce provider latency` → SMS provider changed
- `root: infra | docker-compose: add services configuration` → Docker Compose added
- `root: config | env: add environment variables template` → .env template added
- `root: config | gitignore: exclude build artifacts` → .gitignore added

### 4️⃣ Summary (Description) - 5-7 Words
Clear, concise, no extra explanation, simple language.

---

## 🎁 Golden Rule

**The first line of the commit must be 100% sufficient.**

A team lead reading only the first line should understand:
- ✅ Which service
- ✅ What type of change
- ✅ Which component
- ✅ What nature of change

---

## 📚 Real Examples

See **[Example.md](./Example.md)** for complete examples with body content.
