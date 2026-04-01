-- Migration 002: Create master data tables for categories and tags

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tags table
CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    color TEXT DEFAULT '#3B82F6',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on category name for faster lookups
CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name);

-- Create index on tag name for faster lookups
CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name);

-- Insert some default categories
INSERT OR IGNORE INTO categories (name, description) VALUES
    ('General', 'General purpose entries'),
    ('Documentation', 'Documentation and guides'),
    ('Notes', 'Personal notes and reminders');

-- Insert some default tags
INSERT OR IGNORE INTO tags (name, color) VALUES
    ('Important', '#EF4444'),
    ('Draft', '#F59E0B'),
    ('Completed', '#10B981');
