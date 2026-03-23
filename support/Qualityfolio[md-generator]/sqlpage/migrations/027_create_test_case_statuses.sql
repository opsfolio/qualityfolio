-- Migration 027: Create test case statuses table

CREATE TABLE IF NOT EXISTS test_case_statuses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default test case statuses
INSERT OR IGNORE INTO test_case_statuses (name, description) VALUES
    ('Open', 'Test case is open and awaiting execution'),
    ('In Progress', 'Test case execution is currently in progress'),
    ('Passed', 'Test case has been executed and passed'),
    ('Failed', 'Test case has been executed and failed'),
    ('Pending', 'Test case is pending execution'),
    ('Reopen', 'Test case has been reopened after a previous closure'),
    ('Closed', 'Test case has been closed');
