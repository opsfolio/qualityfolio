-- Migration 006: Create execution types table

CREATE TABLE IF NOT EXISTS execution_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default execution types
INSERT OR IGNORE INTO execution_types (name, description) VALUES
    ('Manual', 'Executed manually by a tester'),
    ('Automated', 'Executed automatically by a script'),
    ('Hybrid', 'Combination of manual and automated execution');
