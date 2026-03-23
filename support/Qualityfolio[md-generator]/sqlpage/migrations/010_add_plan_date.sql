-- Migration 010: Add plan_date to plans table
ALTER TABLE plans ADD COLUMN plan_date DATE;

-- Index for plan date lookup
CREATE INDEX IF NOT EXISTS idx_plans_date ON plans(plan_date);
