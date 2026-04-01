-- Migration: Add full_docs_json column to projects table
-- This stores the complete AI-generated hierarchical documentation structure

ALTER TABLE projects ADD COLUMN full_docs_json TEXT;
