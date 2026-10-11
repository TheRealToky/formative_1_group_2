# sla_tracker

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Project & SLA Task Tracker

A Flutter mobile app for a small software development team to create tasks, assign them to team members, set priorities and deadlines, and see SLA-style feedback (On Track, At Risk, Overdue, Completed). Built for the Formative 1 group project.

Items marked [TODO] must be filled in by the group before submission.

Table of Contents
Features
Screens
SLA Status Rules
Project Structure
Data and Storage
Navigation
Validation and Error Handling
State Management
Getting Started
Team and Contributions
Git Workflow
Known Limitations
Challenges and Solutions
AI Usage Declaration
Features
Sign in by name (no real authentication; a new member is created if the name is new)
Create, edit, complete, and delete tasks
Assign each task to a team member, with a priority (Low, Medium, High) and a deadline
SLA status on every task, shown as a colored chip, with filtering on the task list
Team screen showing the signed-in user and each member's number of open tasks
Data persists after the app is closed and reopened
Screens
Screen	File	Purpose
Sign In	sign_in_screen.dart	Name and password form; finds or creates the member
Main shell	main_shell.dart	Bottom navigation between tabs
Task List	task_list_screen.dart	Filter chips, task cards, "+" button to create
Task Details	task_details_screen.dart	Full task info, edit, delete, mark complete
Create/Edit Task	create_edit_task_screen.dart	Form used for both creating and editing
Team & Profile	team_profile_screen.dart	Profile card, member cards with open task counts, sign out
Project Dashboard	[TODO]	The Home tab is currently a placeholder; the assignment requires a dashboard screen
SLA Status Rules

Status is calculated in lib/services/sla_service.dart by getSlaStatus(task) from the deadline and completion flag.

Status	Rule
Completed	isCompleted is true
Overdue	Not completed and the deadline has passed
At Risk	[TODO: write the group's exact rule, e.g. "not completed and due within the next N days"]
On Track	Not completed and not overdue or at risk

Status is never stored. It is recalculated whenever a task is displayed, so it stays correct as time passes.

Project Structure
lib/
  main.dart                     App entry point, theme, starts at SignInScreen
  models/
    task.dart                   Task class, Priority enum, toJson/fromJson
    team_member.dart            TeamMember class, toJson/fromJson
  screens/
    sign_in_screen.dart
    main_shell.dart             Bottom navigation (Home, Tasks, Team & Profile)
    task_list_screen.dart
    task_details_screen.dart
    create_edit_task_screen.dart
    team_profile_screen.dart
  services/
    storage_service.dart        Loads and saves tasks, members, current user
    sla_service.dart            SLA status logic
  utils/
    date_format.dart            Date formatting helper
  widgets/
    status_chip.dart            Reusable colored SLA status chip

The code is split by responsibility: models hold data, services hold logic and storage, screens hold UI, and widgets hold reusable pieces.

Data and Storage
Current approach on main: SharedPreferences, with tasks and members saved as JSON strings.
Why: the app stores a small amount of simple data, and Task.toJson() / Task.fromJson() make saving and loading straightforward without a database schema.
On first launch, two default members (Alice and Brian) are created so the assignee dropdown is never empty.
StorageService is the only class that touches storage, so screens never read or write storage directly.
[TODO] A teammate's pull request migrates StorageService to SQLite. Update this section to say which approach was finally merged and why.

Main StorageService methods: loadMembers, saveMembers, loadTasks, saveTasks, getCurrentUserId, setCurrentUserId.

Navigation
main.dart opens SignInScreen.
After sign in, Navigator.pushReplacement opens MainShell, so the back button doesn't return to sign in.
MainShell uses a Material 3 NavigationBar and an IndexedStack, which keeps each tab alive when switching.
Tasks tab: the "+" button uses Navigator.push to open CreateEditTaskScreen, which returns a Task with Navigator.pop(context, task). Tapping a task opens TaskDetailsScreen, whose edit button opens the same create/edit screen with the existing task.
Sign out uses pushReplacement back to SignInScreen.
Validation and Error Handling
Sign in: name is required and at least 2 characters; password is required and at least 4 characters. Storage errors are caught with try/catch and shown in a SnackBar.
Create/Edit task: title must be at least 3 characters; an assignee must be chosen; a deadline must be selected (a SnackBar explains if missing); the date picker blocks past dates.
Save button: disabled when there are no team members to assign.
All forms use Form, TextFormField, and a GlobalKey<FormState> with validator functions.
State Management

The app uses setState() only, as the assignment requires.

Screens load data in initState() and call setState() when it arrives.
loading flags show a CircularProgressIndicator until data is ready.
The create/edit screen holds form values (priority, deadline, assignee) as state variables and rebuilds when they change.
Data flow: UI, then StorageService, then local storage, and back again. Screens pass Task objects between each other with Navigator.
The Team screen refreshes its open-task counts by pulling down on the list.
Getting Started

Requirements: Flutter SDK (Dart 3 or newer) and an Android emulator or physical device.

bash
git clone https://github.com/TheRealToky/formative_1_group_2.git
cd formative_1_group_2
flutter pub get
flutter analyze
flutter run

Run on an emulator or a physical device, since the assignment requires a mobile run and browser-only runs are not graded.

Using the app:

Enter any name (2 or more characters) and a password (4 or more characters).
On the Tasks tab, press + to create a task.
Tap a task to see details, edit, complete, or delete it.
Open the Team tab to see members and their open task counts.
Team and Contributions
Member	Branch	Contribution
[TODO name]	feature/createand-edit-tasks+profile	Create/Edit Task screen, Team & Profile screen, wiring Team into MainShell, removing the placeholder Profile tab
[TODO name]	feature/queens-screen	[TODO]
[TODO name]	[TODO]	[TODO]

Group contribution tracker: [TODO link]

Git Workflow
Each member works on their own feature branch and merges to main through a pull request.
Another member reviews and approves before merging.
Shared files (such as main_shell.dart) are changed in small, separate pull requests and announced to the group first.
Auto-generated platform files (linux/, macos/, windows/ plugin registrants) are not committed.

Pull requests so far ([TODO: complete this list from GitHub]):

#3 Improve Create/Edit Task and Team Profile Screens
Connect Team tab to TeamProfileScreen in MainShell
Remove placeholder Profile tab (Team & Profile is one page)
Known Limitations
Home / Dashboard: the Home tab is a placeholder. The assignment requires a Project Dashboard with overall progress. [TODO]
Roles: the design shows roles such as "Developer", but TeamMember has no role field, so the Team screen shows "Team member".
Authentication: sign in is simulated. The password is validated but not checked against anything.
Deleted members: if a member were removed, editing one of their tasks resets the assignee to the first member.
Short windows: on a very short window the pinned Save and Cancel buttons on the Create screen cover part of the form. The form still scrolls.
Old data: if the Task model changes after data was saved, old saved data may fail to load. Clear the app data if this happens.
Open task counts: the Team screen loads data once, so counts update only after a restart or a pull-to-refresh. [TODO: update if fixed]
Challenges and Solutions
Edit button did nothing. The details screen showed "Edit screen coming soon." It now opens CreateEditTaskScreen with the existing task and saves the returned task through StorageService.
Shared file conflicts. main_shell.dart is used by everyone, so changes to it went through small separate pull requests, and the Team screen was called with const TeamProfileScreen() to match the version on main.
Pull request missing a file. The first pull request merged without the main_shell.dart change, so the Team tab still showed a placeholder. It was caught by checking main after the merge and fixed with a follow-up pull request.
Unrelated files in commits. Flutter regenerates platform plugin files whenever the app runs. Files are now added by name with git add <file> instead of git add ..
Matching the design. The Create/Edit and Team screens were rebuilt to match the provided mockups, using one color set and shared helper methods for consistent styling.
AI Usage Declaration

[TODO: the whole group must review and edit this section so it is true for every member.]

AI (Claude) was used by one member to:

Review the Create/Edit and Team & Profile code and suggest improvements and a redesign to match the mockups
Identify a bug (the assignee name not updating after an edit)
Explain Git, branching, and pull request steps
Help diagnose a pull request that merged without a file

How it was verified: the code was run on a device, checked with flutter analyze (no issues), and tested by creating, editing, and reloading tasks. The group is responsible for understanding every line and must be able to explain it and change it live in the demo. [TODO: describe what was changed or rewritten by hand, and list any AI use by other members.]

Demo Checklist
Sign in, then create a task, edit it, and complete it
Show each SLA status (On Track, At Risk, Overdue, Completed) and explain the At Risk rule
Show data persisting after closing and reopening the app
Show validation errors on the sign-in and create task forms
Explain navigation, setState(), and the storage choice
Each member explains and can modify their own files live
