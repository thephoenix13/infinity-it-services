-- ============================================================
-- 017_phase5_settings.sql
-- Phase 5: Branch & Settings Completeness
-- - working_hours JSONB on branches
-- - holidays JSONB array on branches
-- ============================================================

ALTER TABLE branches
  ADD COLUMN IF NOT EXISTS working_hours jsonb DEFAULT '{
    "mon": {"open": true,  "from": "09:00", "to": "19:00"},
    "tue": {"open": true,  "from": "09:00", "to": "19:00"},
    "wed": {"open": true,  "from": "09:00", "to": "19:00"},
    "thu": {"open": true,  "from": "09:00", "to": "19:00"},
    "fri": {"open": true,  "from": "09:00", "to": "19:00"},
    "sat": {"open": true,  "from": "09:00", "to": "17:00"},
    "sun": {"open": false, "from": "09:00", "to": "17:00"}
  }',
  ADD COLUMN IF NOT EXISTS holidays jsonb DEFAULT '[]';
