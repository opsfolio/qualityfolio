-- Migration 022: Add objectives, risks, and cycle_goals to plans table

-- Add objectives column
ALTER TABLE plans ADD COLUMN objectives TEXT;

-- Add risks column
ALTER TABLE plans ADD COLUMN risks TEXT;

-- Add cycle_goals column
ALTER TABLE plans ADD COLUMN cycle_goals TEXT;
