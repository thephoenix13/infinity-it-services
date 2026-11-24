-- ============================================================
-- 001_enums.sql
-- All enum types used across the platform
-- ============================================================

CREATE TYPE user_role AS ENUM (
  'admin',        -- full org access, user management, all branches
  'manager',      -- full access to assigned branch(es), can reassign jobs
  'technician',   -- assigned jobs only, status updates, photo uploads
  'front_desk'    -- intake, payment, job closure at assigned branch
);

CREATE TYPE job_status AS ENUM (
  'received',       -- job created, item received at branch
  'inspection',     -- technician has opened inspection
  'estimate_sent',  -- estimate shared with customer
  'approved',       -- customer approved the estimate
  'parts',          -- awaiting parts (optional stage)
  'in_service',     -- technician actively working
  'ready',          -- work complete, ready for pickup
  'delivered'       -- item handed over, job closed
);

CREATE TYPE photo_type AS ENUM (
  'inspection',   -- photos taken during inspection (damage, issue)
  'post_service'  -- photos taken after service (fixed parts)
);

CREATE TYPE payment_mode AS ENUM (
  'cash',
  'upi',
  'card',
  'neft',
  'other'
);

CREATE TYPE notification_channel AS ENUM (
  'whatsapp',
  'sms'
);

CREATE TYPE notification_status AS ENUM (
  'sent',
  'failed',
  'pending'
);
