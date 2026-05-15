-- Migration 001: Extensions and enum types

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE user_role AS ENUM ('super_admin', 'content_admin', 'readonly_admin');

CREATE TYPE post_status AS ENUM ('draft', 'published');

CREATE TYPE event_status AS ENUM ('draft', 'published', 'cancelled');

CREATE TYPE committee_cadence AS ENUM ('ongoing', 'seasonal', 'one_time');

CREATE TYPE document_type AS ENUM ('governance', 'financial', 'minutes', 'sponsor_flyer', 'other');

CREATE TYPE payment_method_type AS ENUM ('stripe', 'cash', 'check', 'zero_dollar', 'other');
CREATE TYPE payment_purpose AS ENUM ('membership', 'donation', 'sponsorship');
CREATE TYPE payment_status AS ENUM ('pending', 'succeeded', 'failed', 'canceled', 'refunded');
