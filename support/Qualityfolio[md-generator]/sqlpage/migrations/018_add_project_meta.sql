-- Migration 018: Add schema_level and requirement_text to projects
ALTER TABLE projects ADD COLUMN schema_level TEXT;
ALTER TABLE projects ADD COLUMN requirement_text TEXT;
