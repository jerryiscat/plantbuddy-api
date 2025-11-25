-- PlantBuddy Database Seed Data
-- This file populates the database with realistic mock data for testing
-- Run this after migrations: psql -d plantbuddy_db -f 02_seeds.sql

-- ============================================================================
-- PLANTS
-- ============================================================================

-- 1. Monstera (Living Room)
INSERT INTO api_plant (user_id, name, species, perenual_id, care_level, image_url, care_tips, is_dead, created_at, updated_at)
SELECT 
    u.id,
    'Monstera',
    'Monstera Deliciosa',
    NULL,
    'easy',
    NULL,
    'Water when top inch of soil is dry. Prefers bright, indirect light.',
    false,
    CURRENT_TIMESTAMP - INTERVAL '30 days',
    CURRENT_TIMESTAMP
FROM api_user u
WHERE u.username = 'zjasmine.2002'
LIMIT 1;

-- 2. Snake Plant (Bedroom)
INSERT INTO api_plant (user_id, name, species, perenual_id, care_level, image_url, care_tips, is_dead, created_at, updated_at)
SELECT 
    u.id,
    'Snake Plant',
    'Sansevieria Trifasciata',
    NULL,
    'easy',
    NULL,
    'Very low maintenance. Water every 2-3 weeks. Thrives in low light.',
    false,
    CURRENT_TIMESTAMP - INTERVAL '25 days',
    CURRENT_TIMESTAMP
FROM api_user u
WHERE u.username = 'zjasmine.2002'
LIMIT 1;

-- 3. Fiddle Leaf Fig (Office)
INSERT INTO api_plant (user_id, name, species, perenual_id, care_level, image_url, care_tips, is_dead, created_at, updated_at)
SELECT 
    u.id,
    'Fiddle Leaf Fig',
    'Ficus Lyrata',
    NULL,
    'moderate',
    NULL,
    'Needs consistent watering. Keep away from drafts. Bright, indirect light.',
    false,
    CURRENT_TIMESTAMP - INTERVAL '20 days',
    CURRENT_TIMESTAMP
FROM api_user u
WHERE u.username = 'zjasmine.2002'
LIMIT 1;

-- 4. Peace Lily (DEAD - for Graveyard testing)
INSERT INTO api_plant (user_id, name, species, perenual_id, care_level, image_url, care_tips, is_dead, created_at, updated_at)
SELECT 
    u.id,
    'Peace Lily',
    'Spathiphyllum',
    NULL,
    'easy',
    NULL,
    'Prefers moist soil. Low to medium light. Drooping leaves indicate need for water.',
    true,
    CURRENT_TIMESTAMP - INTERVAL '60 days',
    CURRENT_TIMESTAMP
FROM api_user u
WHERE u.username = 'zjasmine.2002'
LIMIT 1;

-- 5. Pothos (with perenual_id)
INSERT INTO api_plant (user_id, name, species, perenual_id, care_level, image_url, care_tips, is_dead, created_at, updated_at)
SELECT 
    u.id,
    'Pothos',
    'Epipremnum Aureum',
    300,
    'easy',
    NULL,
    'Very easy to care for. Water when soil is dry. Can tolerate low light.',
    false,
    CURRENT_TIMESTAMP - INTERVAL '15 days',
    CURRENT_TIMESTAMP
FROM api_user u
WHERE u.username = 'zjasmine.2002'
LIMIT 1;

-- ============================================================================
-- SCHEDULES
-- ============================================================================

-- Monstera: WATER every 7 days, Due Tomorrow
INSERT INTO api_schedule (plant_id, task_type, frequency_days, next_due_date, is_active, created_at, updated_at)
SELECT 
    p.id,
    'WATER',
    7,
    CURRENT_DATE + INTERVAL '1 day',  -- Due Tomorrow
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM api_plant p
INNER JOIN api_user u ON p.user_id = u.id
WHERE u.username = 'zjasmine.2002' AND p.name = 'Monstera'
LIMIT 1;

-- Snake Plant: WATER every 14 days, Due Today
INSERT INTO api_schedule (plant_id, task_type, frequency_days, next_due_date, is_active, created_at, updated_at)
SELECT 
    p.id,
    'WATER',
    14,
    CURRENT_DATE,  -- Due Today
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM api_plant p
INNER JOIN api_user u ON p.user_id = u.id
WHERE u.username = 'zjasmine.2002' AND p.name = 'Snake Plant'
LIMIT 1;

-- Fiddle Leaf Fig: WATER every 7 days, Overdue by 2 days
INSERT INTO api_schedule (plant_id, task_type, frequency_days, next_due_date, is_active, created_at, updated_at)
SELECT 
    p.id,
    'WATER',
    7,
    CURRENT_DATE - INTERVAL '2 days',  -- Overdue by 2 days
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM api_plant p
INNER JOIN api_user u ON p.user_id = u.id
WHERE u.username = 'zjasmine.2002' AND p.name = 'Fiddle Leaf Fig'
LIMIT 1;

-- Pothos: FERTILIZE every 30 days
INSERT INTO api_schedule (plant_id, task_type, frequency_days, next_due_date, is_active, created_at, updated_at)
SELECT 
    p.id,
    'FERTILIZE',
    30,
    CURRENT_DATE + INTERVAL '15 days',  -- Due in 15 days
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM api_plant p
INNER JOIN api_user u ON p.user_id = u.id
WHERE u.username = 'zjasmine.2002' AND p.name = 'Pothos'
LIMIT 1;

-- ============================================================================
-- ACTIVITY LOGS
-- ============================================================================

-- Monstera: 3 WATER logs from the past month
INSERT INTO api_activitylog (plant_id, schedule_id, action_type, action_date, notes, previous_due_date, created_at)
SELECT 
    p.id,
    s.id,
    'WATER',
    CURRENT_TIMESTAMP - INTERVAL '7 days',
    'Watered thoroughly',
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '7 days'
FROM api_plant p
INNER JOIN api_user u ON p.user_id = u.id
INNER JOIN api_schedule s ON s.plant_id = p.id AND s.task_type = 'WATER'
WHERE u.username = 'zjasmine.2002' AND p.name = 'Monstera'
LIMIT 1;

INSERT INTO api_activitylog (plant_id, schedule_id, action_type, action_date, notes, previous_due_date, created_at)
SELECT 
    p.id,
    s.id,
    'WATER',
    CURRENT_TIMESTAMP - INTERVAL '14 days',
    'Regular watering',
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '14 days'
FROM api_plant p
INNER JOIN api_user u ON p.user_id = u.id
INNER JOIN api_schedule s ON s.plant_id = p.id AND s.task_type = 'WATER'
WHERE u.username = 'zjasmine.2002' AND p.name = 'Monstera'
LIMIT 1;

INSERT INTO api_activitylog (plant_id, schedule_id, action_type, action_date, notes, previous_due_date, created_at)
SELECT 
    p.id,
    s.id,
    'WATER',
    CURRENT_TIMESTAMP - INTERVAL '21 days',
    'First watering after purchase',
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '21 days'
FROM api_plant p
INNER JOIN api_user u ON p.user_id = u.id
INNER JOIN api_schedule s ON s.plant_id = p.id AND s.task_type = 'WATER'
WHERE u.username = 'zjasmine.2002' AND p.name = 'Monstera'
LIMIT 1;

-- Fiddle Leaf Fig: SNOOZE log
INSERT INTO api_activitylog (plant_id, schedule_id, action_type, action_date, notes, previous_due_date, created_at)
SELECT 
    p.id,
    s.id,
    'SNOOZE',
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    'Delayed watering by one day',
    CURRENT_DATE - INTERVAL '3 days',
    CURRENT_TIMESTAMP - INTERVAL '1 day'
FROM api_plant p
INNER JOIN api_user u ON p.user_id = u.id
INNER JOIN api_schedule s ON s.plant_id = p.id AND s.task_type = 'WATER'
WHERE u.username = 'zjasmine.2002' AND p.name = 'Fiddle Leaf Fig'
LIMIT 1;

-- Peace Lily: NOTE log (before it died)
INSERT INTO api_activitylog (plant_id, schedule_id, action_type, action_date, notes, previous_due_date, created_at)
SELECT 
    p.id,
    NULL,  -- NOTE doesn't have a schedule
    'NOTE',
    CURRENT_TIMESTAMP - INTERVAL '45 days',
    'Leaves turning brown.',
    NULL,
    CURRENT_TIMESTAMP - INTERVAL '45 days'
FROM api_plant p
INNER JOIN api_user u ON p.user_id = u.id
WHERE u.username = 'zjasmine.2002' AND p.name = 'Peace Lily'
LIMIT 1;

-- ============================================================================
-- VERIFICATION QUERIES (Optional - uncomment to verify data)
-- ============================================================================

-- SELECT 'Plants created:' as info, COUNT(*) as count FROM api_plant WHERE user_id = (SELECT id FROM api_user WHERE username = 'zjasmine.2002');
-- SELECT 'Schedules created:' as info, COUNT(*) as count FROM api_schedule WHERE plant_id IN (SELECT id FROM api_plant WHERE user_id = (SELECT id FROM api_user WHERE username = 'zjasmine.2002'));
-- SELECT 'Activity logs created:' as info, COUNT(*) as count FROM api_activitylog WHERE plant_id IN (SELECT id FROM api_plant WHERE user_id = (SELECT id FROM api_user WHERE username = 'zjasmine.2002'));

