-- Migration 011: Football pivot enum types

CREATE TYPE team_level AS ENUM ('varsity', 'jv', 'freshman');
CREATE TYPE home_or_away AS ENUM ('home', 'away', 'neutral');
CREATE TYPE game_result_status AS ENUM ('scheduled', 'final', 'cancelled', 'postponed', 'tbd');
CREATE TYPE coach_role_category AS ENUM ('head', 'coordinator', 'position_coach', 'trainer', 'staff');
CREATE TYPE resource_section AS ENUM ('registration_forms', 'communications', 'resources', 'stadiums', 'other');
