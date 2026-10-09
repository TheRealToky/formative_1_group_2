// GENERATED from docs/schema.sql - keep both in sync.
const int kDbVersion = 2;

const List<String> kSchemaStatements = [
  r'''
CREATE TABLE team_members (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  email TEXT UNIQUE,
  avatar_color TEXT NOT NULL DEFAULT '#1D4ED8',
  password_hash TEXT,
  password_salt TEXT,
  created_at INTEGER NOT NULL
)
''',
  r'''
CREATE TABLE projects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1)),
  created_at INTEGER NOT NULL
)
''',
  r'''
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  assignee_id INTEGER REFERENCES team_members(id) ON DELETE SET NULL,
  created_by INTEGER REFERENCES team_members(id) ON DELETE SET NULL,
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done')),
  due_at INTEGER,
  sla_due_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  completed_at INTEGER
)
''',
  r'''
CREATE TABLE task_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  changed_by INTEGER REFERENCES team_members(id) ON DELETE SET NULL,
  field TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT,
  changed_at INTEGER NOT NULL
)
''',
  r'''
CREATE TABLE session (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  member_id INTEGER NOT NULL REFERENCES team_members(id) ON DELETE CASCADE,
  signed_in_at INTEGER NOT NULL
)
''',
  r'''
CREATE INDEX idx_tasks_project_status ON tasks(project_id, status)
''',
  r'''
CREATE INDEX idx_tasks_assignee ON tasks(assignee_id)
''',
  r'''
CREATE INDEX idx_tasks_due ON tasks(due_at)
''',
  r'''
CREATE INDEX idx_tasks_sla ON tasks(sla_due_at)
''',
  r'''
CREATE INDEX idx_history_task ON task_history(task_id)
''',
  r'''
CREATE UNIQUE INDEX idx_members_email ON team_members(lower(email))
''',
  r'''
CREATE VIEW v_tasks_detailed AS
SELECT t.*, m.name AS assignee_name, m.avatar_color AS assignee_color
FROM tasks t
LEFT JOIN team_members m ON m.id = t.assignee_id
''',
];
