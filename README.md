# Project & SLA Task Tracker

> A Flutter mobile application for small software development teams to manage tasks, assign team members, configure priorities and deadlines, and receive real-time SLA status feedback (**On Track**, **At Risk**, **Overdue**, and **Completed**).  
> Built for the **Formative 1** group project.

> [!NOTE]
> Items marked `[TODO]` must be finalized by the group prior to final submission.

---

## Table of Contents

- [Features](#features)
- [Screens](#screens)
- [SLA Status Rules](#sla-status-rules)
- [Project Structure](#project-structure)
- [Data and Storage](#data-and-storage)
- [Navigation](#navigation)
- [Validation and Error Handling](#validation-and-error-handling)
- [State Management](#state-management)
- [Getting Started](#getting-started)
- [Team and Contributions](#team-and-contributions)
- [Git Workflow](#git-workflow)
- [Known Limitations](#known-limitations)
- [Challenges and Solutions](#challenges-and-solutions)
- [AI Usage Declaration](#ai-usage-declaration)
- [Demo Checklist](#demo-checklist)

---

## Features

- **Authentication & Sessions**: Sign in and registration with persistent local user sessions.
- **Task CRUD**: Create, edit, toggle completion, and delete tasks.
- **Assignment & Prioritization**: Assign tasks to team members with explicit priority levels (`Low`, `Medium`, `High`) and strict deadlines.
- **Dynamic SLA Feedback**: Real-time SLA tracking displayed as color-coded status chips, with filter chips on the task list.
- **Team Overview**: Dedicated team screen showing member profiles, active users, and open task workloads.
- **Offline Persistence**: SQLite database ensuring data is preserved across app reboots.

---

## Screens

| Screen | File | Purpose |
| :--- | :--- | :--- |
| **Sign In** | `sign_in_screen.dart` | Sign in form with user authentication |
| **Sign Up** | `sign_up_screen.dart` | New account registration (name, role, email, password) |
| **Main Shell** | `main_shell.dart` | Root shell providing Material 3 bottom navigation bar |
| **Dashboard** | `dashboard_screen.dart` | Project health metrics, SLA stats, and "Needs Attention" tasks |
| **Task List** | `task_list_screen.dart` | SLA filter chips, search bar, task cards, and "+" create button |
| **Task Details** | `task_details_screen.dart` | Full task details, history audit log, edit, delete, and status toggle |
| **Task Edit** | `task_edit_screen.dart` / `create_edit_task_screen.dart` | Form for creating and updating tasks |
| **Team & Profile** | `team_profile_screen.dart` | User profile card, member cards with open task counts, and sign out |

---

## SLA Status Rules

Status is dynamically evaluated in `lib/data/models/models.dart` (and `lib/services/sla_service.dart`) using the deadline timestamp, priority SLA threshold window, and completion status.

| Status | Rule |
| :--- | :--- |
| **Completed** | `isCompleted` is `true` (or status == `done`) |
| **Overdue** | Not completed and the deadline has already passed |
| **At Risk** | Not completed and remaining time is within the priority window: <br>• **High**: within 72 hours<br>• **Medium**: within 48 hours<br>• **Low**: within 24 hours |
| **On Track** | Not completed with comfortable time remaining before the deadline |

> **Note:** SLA status is evaluated dynamically whenever tasks are queried or rendered. It is never stored statically, ensuring that real-time accuracy is maintained.

---

## Project Structure

```text
lib/
├── main.dart                     # App entry point, theme setup, auth router
├── data/
│   ├── auth/                     # Auth repository and password hashing
│   ├── db/                       # SQLite AppDatabase singleton, schema, demo seeding
│   ├── models/                   # Database models (Task, TeamMember, Project, TaskHistory)
│   └── repositories/             # TaskRepository, MemberRepository, ProjectRepository
├── models/
│   ├── task.dart                 # Task model class
│   └── team_member.dart          # TeamMember model class
├── screens/
│   ├── sign_in_screen.dart       # User authentication screen
│   ├── sign_up_screen.dart       # User registration screen
│   ├── main_shell.dart           # App shell with bottom navigation
│   ├── dashboard_screen.dart     # Overview metrics and urgent tasks
│   ├── task_list_screen.dart     # Filterable and searchable task list
│   ├── task_details_screen.dart  # Detailed task view with audit history
│   ├── task_edit_screen.dart     # Form to create or modify tasks
│   └── team_profile_screen.dart  # Member list and user profile
├── services/
│   ├── storage_service.dart      # Database-backed storage abstraction
│   └── sla_service.dart          # Dynamic SLA status calculation logic
├── utils/
│   ├── date_format.dart          # Date and timestamp formatting helpers
│   └── dummy_data.dart           # Initial sample tasks and seed data
└── widgets/
    └── status_chip.dart          # Reusable StatusChip, PriorityChip, SlaStatusChip
```

The codebase follows a separation-of-concerns pattern:
- **Models**: Structured data representation.
- **Services & Repositories**: Business logic and SQLite persistence.
- **Screens**: Presentation layer and screen-level state.
- **Widgets**: Reusable UI components.

---

## Data and Storage

- **Implementation**: Relational SQLite database using `sqflite` (on mobile) and `sqflite_common_ffi` (for desktop development).
- **Rationale**: Relational tables enforce foreign key integrity, fast query filtering/sorting, an audit trail (`task_history`), and persistent user session management (`session` table) with salted and hashed passwords.
- **Automatic Seeding**: On initial launch, demo data (team members, projects, and diverse SLA-state tasks) is seeded automatically.
- **Access Architecture**: Operations pass through `AppDatabase`, specialized repositories (`TaskRepository`, `MemberRepository`, `ProjectRepository`, `AuthRepository`), and `StorageService`.
- **Primary `StorageService` Methods**:
  - `loadMembers()`, `saveMembers()`
  - `loadTasks()`, `saveTasks()`
  - `getCurrentUserId()`, `setCurrentUserId()`, `clearSession()`

---

## Navigation

- **Entry Point**: `main.dart` initializes dependencies and directs to `SignInScreen` (or `MainShell` if an active session exists).
- **Post-Sign-In**: Uses `Navigator.pushReplacement` into `MainShell` to prevent navigating back to the authentication screen with the back button.
- **Bottom Navigation**: `MainShell` uses Material 3 `NavigationBar` with `IndexedStack` to preserve state across tab changes.
- **Task Transitions**:
  - On the **Tasks** tab, the `+` button opens `TaskEditScreen` via `Navigator.push`.
  - Tapping a task opens `TaskDetailsScreen`.
  - The Edit action inside `TaskDetailsScreen` opens the edit screen prepopulated with the existing task.
- **Sign Out**: Clears session data and uses `pushReplacement` back to `SignInScreen`.

---

## Validation and Error Handling

- **Authentication Forms**:
  - Name is required (minimum 2 characters).
  - Password is required (minimum 4 characters).
  - Storage/auth exceptions are caught in `try`/`catch` blocks and presented via `SnackBar` alerts.
- **Task Form**:
  - Title must be at least 3 characters.
  - An assignee must be selected.
  - A deadline must be chosen (past dates are blocked in the date picker).
  - The Save button is disabled if no team members are available to assign.
- **Form Architecture**: Validations use Flutter's built-in `Form`, `TextFormField`, and `GlobalKey<FormState>` validator callbacks.

---

## State Management

The application strictly adheres to the project guidelines by using **`setState()` exclusively** without external state libraries.

- **Initialization**: Screens load data in `initState()` and invoke `setState()` once asynchronous queries resolve.
- **Loading States**: Flags (`isLoading`) display `CircularProgressIndicator` during data fetching.
- **Form State**: Edit forms track local fields (priority, deadline, assignee) and trigger rebuilds on change.
- **Data Flow**: `UI` ➔ `StorageService` / `Repositories` ➔ `SQLite` ➔ `UI`.
- **Inter-Screen Data Passing**: Screens pass `Task` objects directly via `Navigator` routes and result callbacks.
- **Refresh Flow**: Pull-to-refresh (`RefreshIndicator`) recalculates member workloads and re-queries task lists.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 3.0 or higher)
- Android Studio / Android Emulator or a connected physical Android device

### Setup & Run

```bash
git clone https://github.com/TheRealToky/formative_1_group_2.git
cd formative_1_group_2
flutter pub get
flutter analyze
flutter run
```

> [!TIP]
> Run the application on an Android emulator or a physical device, as the project assignment requires mobile execution.

### App Usage Walkthrough

1. **Sign In**: Enter a username (2+ characters) and a password (4+ characters).
2. **Create Tasks**: Under the **Tasks** tab, tap `+` to create a task with a title, priority, assignee, and deadline.
3. **Inspect & Edit**: Tap any task card to view details, inspect change history, edit fields, or mark complete.
4. **Monitor SLA & Team**: Review SLA chips on the **Dashboard** and view member workloads on the **Team** tab.

---

## Team and Contributions

| Member | Branch | Contribution |
| :--- | :--- | :--- |
| `[TODO name]` | `feature/createand-edit-tasks+profile` | Create/Edit Task screen, Team & Profile screen, MainShell integration |
| `[TODO name]` | `feature/queens-screen` | `[TODO]` |
| `[TODO name]` | `[TODO]` | `[TODO]` |

- **Group Contribution Tracker**: `[TODO link]`

---

## Git Workflow

- **Feature Branching**: Each team member works on an isolated feature branch and merges to `main` via Pull Requests.
- **Peer Review**: Each PR requires code review and approval before merging.
- **Shared Files Coordination**: Edits to shared files (e.g., `main_shell.dart`) are planned in minimal, separate PRs and communicated to the team beforehand.
- **Clean Repository**: Auto-generated platform files (e.g., `linux/`, `macos/`, `windows/` plugin registrants) are excluded from commits.

### Pull Requests Summary
- `#3 Improve Create/Edit Task and Team Profile Screens`
  - Connected Team tab to `TeamProfileScreen` in `MainShell`
  - Consolidated profile and team into a unified view
- `[TODO: complete this list from GitHub]`

---

## Known Limitations

- **Home / Dashboard**: Dashboard includes SLA metrics and "Needs Attention" tasks; review against the final assignment requirements before submission. `[TODO]`
- **Roles**: Visual mockups display roles (e.g., "Developer"), but when unassigned, screens fall back to default role labels.
- **Authentication**: Authentication validates credentials and maintains local sessions; remote identity verification is out of scope.
- **Deleted Members**: If a member were deleted, editing their existing tasks defaults the assignee dropdown to the first available member.
- **Compact Displays**: On very short screens, bottom action buttons may overlap scrollable form content (the form remains scrollable).
- **Schema Changes**: If database columns change without a migration, clearing app storage or reinstalling may be required.
- **Task Counters**: Team screen calculates counts upon loading or when refreshed via pull-to-refresh.

---

## Challenges and Solutions

- **Edit Button Inactive**:
  - *Challenge*: The task details screen originally showed a placeholder alert.
  - *Solution*: Routed the action to `TaskEditScreen` / `CreateEditTaskScreen`, passing the existing task and saving returned changes through `StorageService`.
- **Shared File Merge Conflicts**:
  - *Challenge*: Multiple developers modified `main_shell.dart` concurrently.
  - *Solution*: Coordinated smaller PRs and aligned widget constructors (`const TeamProfileScreen()`) with the version on `main`.
- **PR Missing File**:
  - *Challenge*: A PR merged without `main_shell.dart`, leaving the placeholder tab active.
  - *Solution*: Detected immediately on `main` and addressed with an expedited follow-up PR.
- **Unintended Platform Plugin Commits**:
  - *Challenge*: Running Flutter on desktop regenerated native plugin files.
  - *Solution*: Staged changes selectively by file path (`git add <file>`) instead of bulk additions.
- **Design System Consistency**:
  - *Challenge*: Inconsistent styling across independently developed screens.
  - *Solution*: Unified color palette, card styling, and reusable status chip components.

---

## AI Usage Declaration

**AI (Claude / Gemini) was used for:**
- Reviewing Create/Edit and Team & Profile screens to recommend UI alignment with mockups.
- Diagnosing an edge case where the assignee name was not refreshing after an edit.
- Clarifying Git branching and pull request troubleshooting procedures.
- Diagnosing a pull request that merged without an essential file.

**Verification Process:**
All code was executed on devices/emulators, checked cleanly with `flutter analyze` (0 issues), and tested across task creation, editing, and persistence flows. The group understands the codebase and is capable of explaining and modifying code live during the project demonstration.  

---

## Demo Checklist

- [ ] **Authentication**: Sign in, demonstrate registration, and show validation rules.
- [ ] **Task Workflow**: Create a task, edit its properties, and toggle its completion state.
- [ ] **SLA Status Feedback**: Showcase all four SLA states (**On Track**, **At Risk**, **Overdue**, **Completed**) and explain the dynamic threshold window.
- [ ] **Data Persistence**: Close the application completely, relaunch it, and demonstrate that data and sessions persist.
- [ ] **Input Validation**: Show form validation triggers on empty or invalid inputs.
- [ ] **Technical Defense**: Explain navigation flow, `setState()` architecture, and SQLite relational schema.
- [ ] **Live Modification**: Ensure each group member is prepared to explain their files and make live code changes.
