-- Migration 019: Create a standard metadata table for projects
-- This avoids the need for resilient redirects and allows storing large text safely

CREATE TABLE IF NOT EXISTS project_metadata (
    project_id INTEGER PRIMARY KEY,
    schema_level TEXT,
    requirement_text TEXT,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- Index for lookup
CREATE INDEX IF NOT EXISTS idx_project_metadata_project_id ON project_metadata(project_id);
