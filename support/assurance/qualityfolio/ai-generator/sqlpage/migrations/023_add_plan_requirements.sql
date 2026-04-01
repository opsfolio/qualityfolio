-- Migration 023: Add requirements fields to plans table

-- Add requirement_id column
ALTER TABLE plans ADD COLUMN requirement_id TEXT;

-- Add requirement_title column
ALTER TABLE plans ADD COLUMN requirement_title TEXT;

-- Add requirement_description column  
ALTER TABLE plans ADD COLUMN requirement_description TEXT;

-- Add requirement_scope column
ALTER TABLE plans ADD COLUMN requirement_scope TEXT;

-- Add functional_requirements column (stored as markdown bullet list with checkboxes)
ALTER TABLE plans ADD COLUMN functional_requirements TEXT;

-- Add acceptance_criteria column (stored as markdown bullet list with checkboxes)
ALTER TABLE plans ADD COLUMN acceptance_criteria TEXT;

-- Index for requirement ID lookup
CREATE INDEX IF NOT EXISTS idx_plans_requirement_id ON plans(requirement_id);
