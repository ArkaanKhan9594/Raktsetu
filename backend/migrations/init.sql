-- ============================================================================
-- RaktSetu Production PostgreSQL Schema & Initial Migration
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Donors Table
CREATE TABLE IF NOT EXISTS donors (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    blood_group VARCHAR(10) NOT NULL,
    city VARCHAR(100) NOT NULL,
    dob DATE NOT NULL,
    gender VARCHAR(20) NOT NULL DEFAULT 'Male',
    last_donation_date TIMESTAMP WITH TIME ZONE,
    is_verified BOOLEAN DEFAULT FALSE,
    is_admin BOOLEAN DEFAULT FALSE,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    referral_code VARCHAR(32) NOT NULL UNIQUE,
    referred_by_code VARCHAR(32),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_donors_phone ON donors(phone);
CREATE INDEX IF NOT EXISTS idx_donors_blood_group ON donors(blood_group);
CREATE INDEX IF NOT EXISTS idx_donors_city ON donors(city);
CREATE INDEX IF NOT EXISTS idx_donors_referral_code ON donors(referral_code);

-- 2. Blood Events Table
CREATE TABLE IF NOT EXISTS blood_events (
    id VARCHAR(64) PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    organizer VARCHAR(150) NOT NULL,
    venue VARCHAR(255) NOT NULL,
    start_date_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date_time TIMESTAMP WITH TIME ZONE NOT NULL,
    capacity INTEGER NOT NULL DEFAULT 50,
    registered_donor_ids TEXT[] DEFAULT '{}',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_events_start ON blood_events(start_date_time);

-- 3. Blood Requests Table
CREATE TABLE IF NOT EXISTS blood_requests (
    id VARCHAR(64) PRIMARY KEY,
    requester_name VARCHAR(120) NOT NULL,
    requester_phone VARCHAR(20) NOT NULL,
    patient_name VARCHAR(120),
    medical_reason VARCHAR(255),
    blood_group VARCHAR(10) NOT NULL,
    units_needed INTEGER NOT NULL DEFAULT 1 CHECK (units_needed >= 1 AND units_needed <= 20),
    hospital VARCHAR(200) NOT NULL,
    city VARCHAR(100) NOT NULL,
    urgency VARCHAR(20) NOT NULL DEFAULT 'urgent',
    status VARCHAR(20) NOT NULL DEFAULT 'open',
    matched_donor_ids TEXT[] DEFAULT '{}',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_requests_blood_group ON blood_requests(blood_group);
CREATE INDEX IF NOT EXISTS idx_requests_status ON blood_requests(status);

-- 4. Donation History Records Table
CREATE TABLE IF NOT EXISTS donation_records (
    id VARCHAR(64) PRIMARY KEY,
    donor_id VARCHAR(64) NOT NULL REFERENCES donors(id) ON DELETE CASCADE,
    event_id VARCHAR(64) REFERENCES blood_events(id) ON DELETE SET NULL,
    donation_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    units_ml INTEGER NOT NULL DEFAULT 450,
    verified_by VARCHAR(120) NOT NULL DEFAULT 'Self-reported',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_records_donor_id ON donation_records(donor_id);

-- 5. Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id VARCHAR(64) PRIMARY KEY,
    recipient_donor_id VARCHAR(64) NOT NULL REFERENCES donors(id) ON DELETE CASCADE,
    type VARCHAR(40) NOT NULL,
    title VARCHAR(150) NOT NULL,
    body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_donor_id);
