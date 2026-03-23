-- Migration: Add objectives and risks columns to projects table
-- This allows storing AI-generated objectives and risks for each project

ALTER TABLE projects ADD COLUMN objectives TEXT;
ALTER TABLE projects ADD COLUMN risks TEXT;
