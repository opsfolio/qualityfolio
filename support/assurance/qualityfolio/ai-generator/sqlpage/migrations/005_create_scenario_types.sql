-- Migration 005: Create scenario types table

CREATE TABLE IF NOT EXISTS scenario_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default scenario types
INSERT OR IGNORE INTO scenario_types (name, description) VALUES
    ('Happy Path', 'Standard positive execution flow'),
    ('Negative', 'Testing invalid inputs or error conditions'),
    ('Boundary', 'Testing boundary values'),
    ('Edge Case', 'Testing extreme or rare conditions');
