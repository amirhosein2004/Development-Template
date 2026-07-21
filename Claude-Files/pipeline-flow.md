# Soradis Delivery Flow

```mermaid
flowchart TD
    B0(["0 · Business"])
    B0S["Name, Domain, Logo"]
    B1(["1 · Features"])
    B2(["2 · System Design"])
    B2S["Architecture, Repositories"]
    B3(["3 · Tech Docs  and  ✎ Claude Docs"])
    B4(["4 · UI/UX"])
    B5(["5 · PRD-TDD"])
    B5a["1 Backend"]
    B5b["2 Frontend"]
    B5c["3 Infrastructure"]
    B6(["6 · Code"])
    B6a["1 Backend"]
    B6b["2 Infrastructure"]
    B6c["3 Frontend"]
    B7(["7 · Tests"])
    B7S["Backend / Frontend"]
    R["Databases → Code → NGINX → Monitoring → E2E Tests → Debugging → Deployment"]

    B0 --> B0S
    B0 --> B1 --> B2
    B2 --> B2S
    B2 --> B3 --> B4 --> B5
    B5 --> B5a
    B5 --> B5b
    B5 --> B5c
    B5 --> B6
    B6 --> B6a
    B6 --> B6b
    B6 --> B6c
    B6 --> B7
    B7 --> B7S
    B7 --> R

    classDef stage fill:#0b2a4a,stroke:#58a6ff,color:#e6edf3,stroke-width:1.5px
    classDef side  fill:#161b22,stroke:#30363d,color:#8b949e
    classDef sub   fill:#1c2230,stroke:#30363d,color:#adbac7
    classDef run   fill:#2a1e3a,stroke:#d2a8ff,color:#e6edf3

    class B0,B1,B2,B3,B4,B5,B6,B7 stage
    class B0S,B2S,B7S side
    class B5a,B5b,B5c,B6a,B6b,B6c sub
    class R run
```

---

## Fallback (plain text)

```
[0]  Business          →  Name, Domain, Logo
                       ↓
[1]  Features
                       ↓
[2]  System Design     →  Architecture, Repositories
                       ↓
[3]  Tech Docs    and    ✎ Claude Docs
                       ↓
[4]  UI/UX
                       ↓
[5]  PRD-TDD
        ├─ 1 Backend
        ├─ 2 Frontend
        └─ 3 Infrastructure
                       ↓
[6]  Code              →  1 Backend
                          2 Infrastructure
                          3 Frontend
                       ↓
[7]  Tests             →  Backend / Frontend
                       ↓
  Databases  →  Code  →  NGINX  →  Monitoring
             →  E2E Tests  →  Debugging  →  Deployment
```

---

# Backend Library Evolution Flow

روال ساخت + تکامل `backend-shared-logic` و هماهنگی آن با هفت service. جدا از delivery flow بالا — این ریزتر است و روی «بنویس → کد بزن → library inline رشد کن» تمرکز دارد. **PRD-TDD authoritative است — drift/refactor موازی نیاز نیست.**

```mermaid
flowchart TD
    A0(["فاز A · Docs"])
    A1["A1 · PRD-TDD هفت service<br/>/hp-docs prd-tdd-backend &lt;repo&gt; ::overwrite"]
    A2["A2 · PRD-TDD library<br/>/hp-docs prd-tdd-library ::overwrite<br/>(کل feature catalog + هفت sibling PRD-TDD کامل)"]

    B0(["فاز B · Code library MVP"])
    B1["B1 · کد library MVP<br/>/hp-implement backend-library<br/>(ماژول‌های locked-in: Jalali · exception · JWT verify · DbAction · adapter ها · OTel · Kavenegar)"]
    B2["B2 · انسان: git tag v0.1.0"]

    C0(["فاز C · Code services (inline library growth)"])
    C1["C1 · کد service<br/>/hp-implement backend-service &lt;repo&gt;<br/>(کل PRD-TDD library + کل src/ library را می‌خواند)"]
    C2["C2 · Library promotion inline<br/>هر جا standard الزام می‌کند یا cross-service worthy است<br/>→ همان run در tech/backend-shared-logic هم می‌نویسد<br/>→ §17 note در PRD-TDD service"]
    C3["C3 · انسان: git tag library bump (اگر promotion شد)"]

    D0(["فاز D · Loop"])
    D1["D1 · تغییر PRD-TDD service → دوباره backend-service<br/>تغییر PRD-TDD library → دوباره backend-library با ::gap یا ::patch=&lt;module&gt;"]

    A0 --> A1 --> A2
    A2 --> B0
    B0 --> B1 --> B2
    B2 --> C0
    C0 --> C1
    C1 --> C2
    C2 --> C3
    C3 --> D0
    D0 --> D1
    D1 -.->|همیشه| C1

    classDef phase   fill:#2a1e3a,stroke:#d2a8ff,color:#e6edf3,stroke-width:1.5px
    classDef step    fill:#0b2a4a,stroke:#58a6ff,color:#e6edf3
    classDef human   fill:#3a2a1e,stroke:#f0b429,color:#e6edf3

    class A0,B0,C0,D0 phase
    class A1,A2,B1,C1,C2,D1 step
    class B2,C3 human
```

## Fallback (plain text)

```
[A · Docs]
  A1  PRD-TDD هفت service   →  /hp-docs prd-tdd-backend <repo> ::overwrite   (×7)
  A2  PRD-TDD library        →  /hp-docs prd-tdd-library ::overwrite
                                (کل feature catalog + هفت sibling PRD-TDD کامل)
              ↓
[B · Code library MVP]
  B1  کد library MVP         →  /hp-implement backend-library
                                (ماژول‌های locked-in فقط: Jalali · exception ·
                                 JWT verify · DbAction · MinIO/Kafka/Redis adapter ·
                                 OTel · Kavenegar)
  B2  انسان                  →  git tag v0.1.0 && git push origin v0.1.0
              ↓
[C · Code services (library rises inline)]
  C1  کد service             →  /hp-implement backend-service <repo>   (هر بار)
                                کل PRD-TDD library + کل src/ library را می‌خواند
  C2  Library promotion       (به‌طور خودکار داخل C1)
      inline decision tree (اولین match wins):
        1. Standard مجبور می‌کند library (Jalali · JWT · DbAction · adapter · …)
           → همان run در tech/backend-shared-logic هم می‌نویسد
           → §17 note: promoted → backend-shared-logic:<module>.<symbol>
        2. Cross-service utility + foundational + stable
           → همان کار
        3. Cross-service ولی worthy نیست (domain-carrying · service-specific)
           → local بمان
           → §17 note: considered for library, rejected: <reason>
        4. One-off service-local
           → local
        5. Rare: تنها این service ولی plausible
           → local + §17 note برای future
  C3  انسان                  →  اگر C2 در library نوشت:
                                  git tag v0.1.1 (یا bump مناسب) روی
                                  tech/backend-shared-logic روی main
              ↓
[D · Loop]
  D1  هر تغییر در PRD-TDD    →  دوباره backend-service (برای هر repo تغییری)
                                یا backend-library ::gap (ماژول جدید در PRD-TDD)
                                یا backend-library ::patch=<module> (هر تغییر
                                                                       روی ماژول موجود)
```

## چرا drift/refactor phase جدا نیاز نیست

PRD-TDD کارِ authoritative است. `backend-service` هر بار PRD-TDD service + کل library را fresh می‌خواند. اگر standard الزام کند یا cross-service worthy باشد، همان‌جا در library هم می‌نویسد. Drift زمانی وجود دارد که reality از paper جلو بزند — اگر هر تغییر در paper سپس regenerate از paper، drift نمی‌سازد.

