-- Create table for storing text entries
CREATE TABLE IF NOT EXISTS text_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create index on created_at for faster sorting
CREATE INDEX IF NOT EXISTS idx_text_entries_created_at ON text_entries(created_at DESC);
