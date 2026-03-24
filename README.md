# Flodo Task Management App - Track A (Full-Stack Builder)

## 🚀 Track & Stretch Goals
Built exactly as required for **Track A (FastAPI + Flutter + PostgreSQL)** and includes **ALL 3 Strategic Stretch Goals**:
1. **Debounced Autocomplete Search**: Interactive search with instant feedback and title highlighting.
2. **Recurring Tasks Logic**: Support for Daily/Weekly tasks (logic on backend, UI on frontend).
3. **Persistent Drag-and-Drop**: Reorder your tasks dynamically; priority persists in the database.

---

## 🛠️ Getting Started

### 1. Prerequisites
- **Docker Desktop** (installed and running)
- **Flutter SDK** (installed)

### 2. Backend Setup (Docker)
The backend is completely containerized. Start the API and Database with:
```bash
docker compose up --build -d
```
The FastAPI instance exposes its Swagger documentation at **http://localhost:8000/docs**.

---

## 📱 Running the Flutter App

Navigate to the `frontend` directory first:
```bash
cd frontend
flutter pub get
```

### Run on Web (Recommended for quick testing)
```bash
flutter run -d chrome
```

### Run on macOS Desktop
*Requires Xcode to be installed.*
```bash
flutter run -d macos
```

### Run on Android
*Ensure you have an Emulator running or a Device connected.*
```bash
flutter run -d android
```

### Run on iOS
*Requires Xcode and an iOS Simulator/iPhone connected.*
```bash
flutter run -d ios
```

---

## 📝 Key Features Implementation Details
- **CRUD Operations**: All standard task management operations.
- **2-Second Delay**: Simulated on Create/Update to show high-quality loading states.
- **Draft Recovery**: Uses `shared_preferences`. If you exit the new task screen mid-creation, your progress is saved locally.
- **Self-referential Blocking**: Tasks can be blocked by other tasks. Blocked tasks are visually distinct (lower opacity) and interactions are disabled until the blocker is marked as "Done".

---

## 📖 Journey: Prompts & Problem Solving

### 1. Initial Prompts
- **Goal**: Build a full-stack Task App using **Track A** (FastAPI, Flutter, PostgreSQL).
- **Instruction**: Implement ALL 3 stretch goals (Debounced Search, Recurring Logic, Drag-and-Drop).
- **Environment**: Containerize the backend services for seamless local development.

### 2. Problems Faced & Solutions

| Problem | Root Cause | Solution |
| :--- | :--- | :--- |
| **Backend Crash (Docker)** | API tried to connect before DB was fully ready. | Added a **retry loop** (5 attempts, 2s sleep) in `main.py` lifespan context. |
| **Network Error: Failed to fetch** | CORS issues & Browser security restrictions on `127.0.0.1`. | Switched `baseUrl` to `localhost` and relaxed CORS `allow_credentials` policy. |
| **TypeError on Task Creation** | Redundant `order_index` field provided during model creation. | Refined the `create_task` endpoint using Pydantic's `exclude={"order_index"}` during model dumping. |
| **307 Redirect Loops** | FastAPI redirects `/tasks` to `/tasks/`, causing CORS instability in Web. | Updated the Flutter client to request the URL with an **explicit trailing slash** (`/tasks/`). |
| **Stale Code in Docker** | Docker's build cache wasn't picking up host-side file edits. | Used `docker compose build --no-cache` to force a clean build state. |

---

## 🤖 AI Usage Report
Created using **Antigravity (Google Deepmind)**.
- **Highlights**: Provided robust SQLAlchemy async models and a comprehensive Riverpod state management system.
- **Refinement**: Self-corrected multiple cross-platform connectivity issues (CORS, URLs, Docker race conditions).