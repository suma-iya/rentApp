<div align="center">

<br/>

### GoRent : Intelligent Property Rental Management

<br/>

[![Version](https://img.shields.io/badge/version-1.0.0-0ea5e9?style=for-the-badge&logo=semanticrelease&logoColor=white)](https://github.com/suma-iya/GoRent)
[![Flutter](https://img.shields.io/badge/Flutter-3.1.4+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Go](https://img.shields.io/badge/Go-1.20+-00ADD8?style=for-the-badge&logo=go&logoColor=white)](https://golang.org)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://mysql.com)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
[![License](https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge)](LICENSE)

<br/>

> **Rule-based property management** — automated payment tracking, transparent tenant risk assessment,  
> real-time push notifications, and a cross-platform mobile app in English & Bengali.

<br/>

[**Features**](#-key-features) · [**Screenshots**](#-screenshots) · [**Tech Stack**](#-tech-stack) · [**Installation**](#-installation) · [**API Docs**](#-api-documentation)

<br/>

---

</div>

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Usage](#-usage)
- [API Documentation](#-api-documentation)
- [Project Structure](#-project-structure)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

GoRent is a comprehensive property rental management system that combines traditional property management with **transparent, rule-based tenant risk assessment**. Built for landlords and tenants alike, it streamlines manual administration through smart automation and real-time intelligence.

<br/>

<div align="center">

| 🔍 Transparent Risk Analysis | 🔔 Real-Time Notifications | 📱 Cross-Platform | 🌐 Multi-Language |
|:-------------------:|:---------------------------:|:-----------------:|:-----------------:|
| Deterministic tenant scoring based on payment behavior | Firebase Cloud Messaging push alerts | Android & iOS via Flutter | English & Bengali (বাংলা) |

</div>

<br/>

> **Streamlined workflow** through automation and transparent analytics.

---

## ✨ Key Features

<details>
<summary><b>🔐 User Management & Authentication</b></summary>
<br/>

- Secure **JWT-based** authentication system
- **Role-based access control** — Manager & Tenant roles
- User registration via email and phone number
- Password security with **Bcrypt** hashing

</details>

<details>
<summary><b>🏢 Property & Tenant Management</b></summary>
<br/>

- Add and manage multiple properties with photo uploads
- Floor/unit management with rent amount configuration
- Occupancy status tracking — vacant, occupied, pending
- Send/accept/reject tenant requests via phone number
- View tenant profiles and complete payment history

</details>

<details>
<summary><b>💰 Payment & Advance Payment System</b></summary>
<br/>

- Record and track rental payments with full timestamps
- **Late payment detection** and tracking
- Export payment history to **CSV**
- Request, accept, reject, or cancel advance payments
- Deduct advance payments from future rent automatically

</details>

<details open>
<summary><b>🤖 Rule-Based Conversational Interface</b></summary>
<br/>

The conversational interface provides natural language access to tenant analytics and payment data.

**Supported Intents**

| Intent | Example Query |
|--------|--------------|
| `EXPLAIN_RISK` | *"Why is 01712345678 high risk?"* |
| `RECOMMEND_ACTION` | *"What should I do for tenant 01712345678?"* |
| `LIST_HIGH_RISK` | *"List all high risk tenants"* |
| `MONTHLY_SUMMARY` | *"Show monthly summary"* |
| `COMPARE_TENANTS` | *"Compare 01712345678 and 01712345679"* |



**Risk Calculation Algorithm**

The system uses a deterministic, transparent scoring formula based on observable payment behavior:
```
Risk Score = f(delay_rate, avg_delay, severity_factor, partial_payments, trend, inconsistency)

  ● Critical Risk  ≥ 0.85  🔴
  ● High Risk      0.65 – 0.84  🟠
  ● Medium Risk    0.35 – 0.64  🟡
  ● Low Risk       < 0.35  🟢
```

**Enhanced Risk Factors (matching Figure 2 in paper):**
- **Delay Rate (DR)** — 30% weight — Proportion of late payments
- **Average Delay (D)** — 25% weight — How late payments typically are
- **Severity Factor (SF)** — 15% weight — Weighted late payment impact (frequency × magnitude)
- **Partial Payments (PP)** — 15% weight — Frequency of incomplete payments
- **Trend (TR)** — 10% weight — Payment behavior trajectory (improving vs worsening)
- **Inconsistency (IC)** — 10% weight — Payment pattern volatility

**Interface Features:**
- Extracts and normalizes **Bangladeshi phone numbers** automatically
- **Markdown-rendered** rich responses with suggested follow-ups
- Persistent **chat history** (last 100 messages)
- **Rule-based intent detection** using pattern matching
- **Template-based response generation** for consistent, auditable results

</details>

<details>
<summary><b>🔔 Notification System</b></summary>
<br/>

- **Firebase Cloud Messaging** push notifications
- In-app notification center with read/unread tracking
- Accept/reject actions directly from notification banners
- Automated **monthly payment reminders** via Cron jobs
- Notification types: tenant requests, payment confirmations, advance payment alerts, system messages

</details>

---

## 📸 Screenshots

### Authentication

| Login | Registration |
|:-----:|:-----------:|
| ![Login](screenshots/login.jpg) | ![Register](screenshots/register.jpg) |

### Property Management

| Properties List | Add Property | Add Floor | Update Floor |
|:--------------:|:------------:|:---------:|:------------:|
| ![Properties](screenshots/propertyDetails.jpg) | ![Add Property](screenshots/add_property.jpg) | ![Add Floor](screenshots/addFloor.jpg) | ![Update Floor](screenshots/updateFloor.jpg) |

### Payment Management

 | Payment History |
|:--------------:|
| ![Payment History](screenshots/paymentHistory.jpg) |

### Conversational Interface

| Chat Interface | Risk Analysis | Monthly Summary |
|:-------------:|:------------:|:---------------:|
| ![Chat](screenshots/chat.jpg) | ![Risk Analysis](screenshots/risk_analysis.jpg) | ![Monthly Summary](screenshots/monthly_summary.jpg) |

### Notifications

| Notifications List | Push Notification | Accepted |
|:-----------------:|:-----------------:|:--------:|
| ![Notifications](screenshots/notification_action.jpg) | ![Push Notification](screenshots/pushNotification.jpg) | ![Accepted](screenshots/notification_accepted.jpg) |

### Settings & Localization

| Settings | Bengali UI |
|:--------:|:---------:|
| ![Settings](screenshots/hamburgerMenu.jpg) | ![Bengali](screenshots/bengali_ui.jpg) |

---

## 🛠 Tech Stack

<div align="center">

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile** | Flutter 3.1.4+ | Cross-platform Android & iOS |
| **State** | Provider | Application state management |
| **Notifications** | Firebase Cloud Messaging | Real-time push notifications |
| **Backend** | Go (Golang) 1.20+ | REST API & business logic |
| **Router** | Gorilla Mux | HTTP routing |
| **Database** | MySQL 8.0 | Persistent data storage |
| **Auth** | JWT + Bcrypt | Secure authentication |
| **Scheduler** | Cron | Automated background tasks |
| **DevOps** | Docker & Compose | Containerized deployment |

</div>

---

## 🏗 Architecture

The system follows a clean **three-tier architecture**:
```
┌──────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                  │
│           Flutter Mobile App  (Android / iOS)        │
│      UI Components  ·  Provider  ·  API Services     │
└─────────────────────────┬────────────────────────────┘
                          │  HTTP / REST
┌─────────────────────────▼────────────────────────────┐
│                 APPLICATION LAYER                    │
│                  Go Backend Server                   │
│  REST Endpoints  ·  Auth  ·  Risk Engine  ·  FCM    │
└─────────────────────────┬────────────────────────────┘
                          │  SQL
┌─────────────────────────▼────────────────────────────┐
│                    DATA LAYER                        │
│                   MySQL Database                     │
│   Users  ·  Properties  ·  Payments  ·  Notifications│
└──────────────────────────────────────────────────────┘
```

### Module Breakdown

**Backend (Go)**
```
handlers/    — HTTP request handlers per domain
middleware/  — JWT auth, CORS, rate limiting
models/      — Data structures
config/      — Database & env configuration
utils/       — JWT helpers, ID generation, CSRF
scheduler/   — Cron-based background tasks
```

**Frontend (Flutter)**
```
lib/screens/   — All UI screens
lib/services/  — API & Firebase notification services
lib/providers/ — State management
lib/models/    — Data models
lib/utils/     — Utility helpers & localization
```

---

## 📦 Installation

### Prerequisites

| Tool | Version |
|------|---------|
| Go | 1.20+ |
| Flutter | 3.1.4+ |
| MySQL | 8.0+ |
| Docker & Compose | Latest *(optional)* |
| Firebase Account | — *(for push notifications)* |

---

### 🔧 Backend Setup
```bash
# 1. Clone the repository
git clone https://github.com/suma-iya/GoRent.git
cd GoRent

# 2. Start MySQL (Docker)
docker-compose up -d mysql
# — OR — configure a local MySQL instance and create the 'rent' database

# 3. Set environment variables
export DB_HOST=localhost
export DB_PORT=3306
export DB_USER=your_username
export DB_PASSWORD=your_password
export DB_NAME=rent

# 4. Run database migrations
mysql -u your_user -p rent < create_user_table.sql
# (run additional migration files as needed)

# 5. Install Go dependencies
go mod download

# 6. Start the server
go run main.go
# Server runs at → http://localhost:8080
```

---

### 📱 Frontend Setup
```bash
# 1. Navigate to the Flutter project
cd go_rent_frontend

# 2. Install dependencies
flutter pub get

# 3. Add Firebase config files
#    Android → android/app/google-services.json
#    iOS     → ios/Runner/GoogleService-Info.plist

# 4. Set the API base URL in lib/services/api_service.dart
#    Android Emulator : http://10.0.2.2:8081
#    Physical Device  : http://YOUR_LOCAL_IP:8081

# 5. Run the app
flutter run           # Android
flutter run -d ios    # iOS (macOS only)
```

---

### 🐳 Docker — Full Stack
```bash
# Start everything
docker-compose up -d

# Tail logs
docker-compose logs -f

# Tear down
docker-compose down
```

---

## 🚀 Usage

### For Property Managers

1. **Register / Login** — Create an account or sign in
2. **Add Properties** — Upload photos, configure units and floors
3. **Invite Tenants** — Send rental requests via phone number
4. **Record Payments** — Log rent payments and view full history
5. **Advance Payments** — Request, approve, or cancel advance payments
6. **Query Risk Analysis** — Use conversational interface for tenant risk insights
7. **Notifications** — Manage requests and payment alerts in real time

### For Tenants

1. **Register / Login** — Create your tenant account
2. **View Properties** — See all properties you're assigned to
3. **Respond to Requests** — Accept or reject rental invitations
4. **Payment History** — Review all your recorded payments
5. **Advance Payments** — Approve or decline advance payment requests
6. **Notifications** — Receive real-time updates from your manager

---

## 📚 API Documentation

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/login` | User login |
| `POST` | `/register` | User registration |

### Properties
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/properties` | List user properties |
| `GET` | `/property/{id}` | Get property details |
| `POST` | `/property` | Create property |
| `GET` | `/property/{id}/floor` | List floors |
| `POST` | `/property/{id}/floor` | Add floor |
| `PUT` | `/property/{id}/floor/{floor_id}` | Update floor |

### Payments
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/property/{id}/floor/{floor_id}/payment` | Record payment |
| `GET` | `/floor/{floor_id}/payment-history` | Get payment history |
| `POST` | `/property/{id}/floor/{floor_id}/advance-payment` | Request advance |

### Notifications
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/notifications` | Get notifications |
| `POST` | `/notifications/action` | Handle action |
| `POST` | `/notifications/mark-read` | Mark as read |

### Conversational Interface
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/chat` | Send message |
| `GET` | `/chat/health` | Health check |



## 📁 Project Structure
```
GoRent/
├── config/                     # DB config & Firebase credentials
│   ├── database.go
│   └── firebase-service-account.json
│
├── handlers/                   # HTTP request handlers
│   ├── chatbot.go              # Rule-based conversational engine
│   ├── login.go
│   ├── register.go
│   ├── property.go
│   └── notification.go
│
├── middleware/
│   └── auth.go                 # JWT authentication
│
├── models/
│   └── user.go
│
├── scheduler/
│   └── scheduler.go            # Cron jobs (payment reminders)
│
├── utils/
│   ├── jwt.go
│   ├── id.go
│   └── csrf.go
│
├── go_rent_frontend/           # Flutter mobile application
│   ├── lib/
│   │   ├── screens/            # All UI screens
│   │   ├── services/           # API & FCM services
│   │   ├── providers/          # State management
│   │   ├── models/             # Data models
│   │   └── utils/              # Helpers & localization
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── main.go                     # Backend entry point
├── go.mod
├── docker-compose.yml
├── Dockerfile
└── README.md
```

---

## 🤝 Contributing

Contributions are very welcome! Here's how to get started:
```bash
# Fork → clone → branch
git checkout -b feature/your-feature-name

# Make your changes, then commit
git commit -m "feat: add amazing feature"

# Push and open a Pull Request
git push origin feature/your-feature-name
```

**Guidelines**
- Follow idiomatic Go and Flutter conventions
- Write clear, descriptive commit messages
- Comment complex logic
- Update documentation alongside code changes
- Test your changes before submitting

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Authors

**Sumaiya Rahim Suma & Abdullah Al Shafi**
- GitHub: [@suma-iya](https://github.com/suma-iya)
- Email: sumaiya.rahim234@gmail.com

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) team for the incredible cross-platform framework
- The [Go](https://golang.org) community for excellent libraries and tooling
- [Firebase](https://firebase.google.com) for seamless push notification infrastructure
- Every contributor and user who has supported this project

---

## 📖 Citation

If you use GoRent in your research, please cite:
```bibtex
@software{gorent2026,
  author = {Sumaiya Rahim Suma and Abdullah Al Shafi},
  title = {GoRent: Open-source software for transparent rule-based rental risk assessment},
  year = {2026},
  url = {https://github.com/suma-iya/GoRent},
  version = {1.0.0}
}
```

---

<div align="center">

<br/>

**If GoRent helped your research or project, please ⭐ the repository!**

<br/>

*Made with ❤️ using Flutter & Go*

</div>
