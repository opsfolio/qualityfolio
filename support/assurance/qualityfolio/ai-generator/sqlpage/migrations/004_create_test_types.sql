-- Migration 004: Create test types table

CREATE TABLE IF NOT EXISTS test_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default test types
INSERT OR IGNORE INTO test_types (name, description) VALUES
    ('Functional', 'Testing specific functions or features'),
    ('Integration', 'Testing combined parts of the application'),
    ('Regression', 'Testing to ensure changes did not break existing functionality'),
    ('Performance', 'Testing system performance under load'),
    ('Security', 'Testing for vulnerabilities');
