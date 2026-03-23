-- Migration 025: Add evidence metadata fields

-- Add cycle column
ALTER TABLE evidence ADD COLUMN cycle TEXT;

-- Add cycle_date column
ALTER TABLE evidence ADD COLUMN cycle_date DATE;

-- Add severity column
ALTER TABLE evidence ADD COLUMN severity TEXT;

-- Add assignee_id column (reference to team_members)
ALTER TABLE evidence ADD COLUMN assignee_id INTEGER REFERENCES team_members(id);

-- Add status column
ALTER TABLE evidence ADD COLUMN status TEXT;

-- Add attachments column (stored as markdown list of links)
ALTER TABLE evidence ADD COLUMN attachments TEXT;

-- Index for assignee lookup
CREATE INDEX IF NOT EXISTS idx_evidence_assignee ON evidence(assignee_id);
