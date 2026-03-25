# Flodo Task Management App

## 📌 Track & Stretch Goals Chosen

**Track A: The Full-Stack Builder**
- **Frontend**: Flutter & Dart
- **Backend**: Python (FastAPI)
- **Database**: PostgreSQL

**All 3 Stretch Goals Implemented:**
1. ✅ **Debounced Autocomplete Search** — 300ms debounce with live title highlighting in results.
2. ✅ **Recurring Tasks Logic** — Daily/Weekly toggle. On marking "Done", the backend auto-generates the next occurrence with a pushed-forward due date.
3. ✅ **Persistent Drag-and-Drop** — Drag to reorder tasks; `order_index` is saved to PostgreSQL and persists on app restart.

---

## 🛠️ Step-by-Step Setup Instructions

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (installed and running)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.x+)
- A browser (Chrome recommended for web)

---

### Step 1: Clone the Repository
```bash
git clone https://github.com/jatin-jatin42/flodo-app.git
cd flodo-app
```

### Step 2: Start the Backend (Docker)
This starts both FastAPI and PostgreSQL in containers:
```bash
docker compose up --build -d
```
- API is available at: **http://localhost:8000**
- Swagger docs at: **http://localhost:8000/docs**

### Step 3: Run the Flutter Frontend
```bash
cd frontend
flutter pub get
```

#### ▶️ Web (Chrome) — Recommended
```bash
flutter run -d chrome
```

#### ▶️ macOS Desktop
*Requires Xcode to be installed.*
```bash
flutter run -d macos
```

#### ▶️ Android Emulator
*Start an emulator in Android Studio first, then:*
```bash
flutter run
```
> The app automatically uses `10.0.2.2` as the backend host on Android.

#### ▶️ iOS Simulator
*Requires Xcode and an active iOS Simulator.*
```bash
flutter run -d ios
```

### Step 4: Stop the Backend
```bash
docker compose down
```

---

## 📝 Core Features Implemented

| Feature | Details |
|---|---|
| **CRUD** | Create, Read, Update, Delete tasks via REST API |
| **Task Fields** | Title, Description, Due Date, Status (To-Do / In Progress / Done) |
| **Blocked By** | Self-referential dependency — blocked tasks are greyed out and unclickable |
| **Draft Recovery** | Unfinished task creation is saved to `SharedPreferences` and restored |
| **Search** | Debounced (300ms) live search with yellow highlighting on matching text |
| **Filter by Status** | Dropdown in AppBar to filter All / To-Do / In Progress / Done |
| **2-Second Delay** | Simulated on Create & Update; loading spinner shown, Save button disabled |
| **Drag & Drop** | Persistent reorder; new `order_index` sent to backend on drop |
| **Recurring Tasks** | Daily/Weekly toggle; backend auto-creates next occurrence when marked Done |

---

## 🤖 AI Usage Report

**AI Tool Used**: Antigravity (powered by Google Deepmind)

### Prompts That Gave the Most Helpful Code

1. **"Build a FastAPI backend with SQLAlchemy async models for a Task with self-referential blocked_by relationship and UUID primary keys."**
   — Generated the full `models.py` with correct PostgreSQL UUID type, async session setup, and the self-referential foreign key in one shot.

2. **"Implement Riverpod state management in Flutter for CRUD operations against a REST API, with loading states and error handling."**
   — Scaffolded the full `task_provider.dart` with `AsyncNotifier`, `ref.invalidate()` for cache busting, and proper error propagation to the UI.

3. **"Add debounced search with 300ms delay and highlight the matching text in the task title using RichText and TextSpan."**
   — Implemented the `Debouncer` utility class and the `RichText` highlighting logic with `TextSpan` in a single response.

### Example of AI Giving Bad/Incorrect Code & How I Fixed It

**Problem**: The AI generated the `create_task` endpoint as:
```python
task = Task(**task_in.model_dump(), order_index=new_order)
```
But `order_index` was already included inside `model_dump()`, so Python raised:
```
TypeError: Task() got multiple values for keyword argument 'order_index'
```

**AI Hallucination**: The AI then suggested fixing it by doing a manual `.pop()` on the dict, but also left the `exclude` parameter in the wrong spot, producing the same error on retry.

**How I Fixed It**: I used Pydantic's built-in `exclude` parameter directly in `model_dump()`:
```python
task = Task(**task_in.model_dump(exclude={"order_index"}), order_index=new_order)
```
This is the correct, idiomatic Pydantic v2 way — cleaner and not prone to the dict-mutation race condition the AI's approach had.

---

## 📖 Problems Faced & Solutions

| Problem | Root Cause | Solution |
|---|---|---|
| **Backend container crashed on startup** | FastAPI tried to connect to PostgreSQL before it was ready | Added a 5-retry loop with 2s sleep in the `lifespan` context manager |
| **"Failed to fetch" on Web** | Browser CORS + `127.0.0.1` security restrictions | Switched `baseUrl` to `localhost`, set `allow_credentials=False` in CORS |
| **TypeError on Task Creation** | `order_index` passed twice to the Task model | Used `model_dump(exclude={"order_index"})` in Pydantic |
| **Double-slash in API URLs** | `baseUrl` ended with `/` and paths also started with `/` | Removed extra leading slashes in all API calls (`$baseUrl$id` not `$baseUrl/$id`) |
| **Delete failed with FK Violation** | Deleting a task that another task's `blocked_by_id` pointed to | Backend now clears all `blocked_by_id` references before deletion |
| **Stale code running in Docker** | Build cache not picking up changes | Used `docker compose build --no-cache` |
| **Form pre-filled after task creation** | Draft was re-saved in `dispose()` even after successful submit | Added `_submitted` flag to skip draft-save after a successful create |