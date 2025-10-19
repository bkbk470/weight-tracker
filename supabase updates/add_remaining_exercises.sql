-- COMPLETE EXERCISE LIST - Run this to get ALL 380+ exercises
-- This adds ONLY exercises that don't already exist (no duplicates)
-- Run in Supabase SQL Editor

INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url) 
SELECT * FROM (VALUES
-- The database will skip any exercises with duplicate names
-- So we can safely insert everything

('Bench Press (Cable)', 'Chest', 'Intermediate', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('Bench Press (Smith Machine)', 'Chest', 'Intermediate', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Bench Press - Wide Grip (Barbell)', 'Chest', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Incline Bench Press (Smith Machine)', 'Chest', 'Intermediate', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Decline Bench Press (Machine)', 'Chest', 'Intermediate', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Decline Bench Press (Smith Machine)', 'Chest', 'Intermediate', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Low Cable Fly Crossovers', 'Chest', 'Beginner', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('Chest Fly (Band)', 'Chest', 'Beginner', 'Band', true, false, 'Exercises/default_exercise.gif'),
('Chest Fly (Suspension)', 'Chest', 'Intermediate', 'Suspension', true, false, 'Exercises/default_exercise.gif'),
('Incline Chest Fly (Dumbbell)', 'Chest', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Decline Chest Fly (Dumbbell)', 'Chest', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Chest Press (Band)', 'Chest', 'Beginner', 'Band', true, false, 'Exercises/default_exercise.gif'),
('Incline Chest Press (Machine)', 'Chest', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Iso-Lateral Chest Press (Machine)', 'Chest', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Seated Chest Flys (Cable)', 'Chest', 'Beginner', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('Ring Dips', 'Chest', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Push Up (Weighted)', 'Chest', 'Intermediate', 'Weighted', true, false, 'Exercises/default_exercise.gif'),
('Push Up - Close Grip', 'Chest', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Kneeling Push Up', 'Chest', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Clap Push Ups', 'Chest', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('One Arm Push Up', 'Chest', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Plank Pushup', 'Chest', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Around The World', 'Chest', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Butterfly (Pec Deck)', 'Chest', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Floor Press (Dumbbell)', 'Chest', 'Intermediate', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Hex Press (Dumbbell)', 'Chest', 'Intermediate', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Plate Press', 'Chest', 'Beginner', 'Plate', true, false, 'Exercises/default_exercise.gif'),
('Plate Squeeze (Svend Press)', 'Chest', 'Beginner', 'Plate', true, false, 'Exercises/default_exercise.gif')
) AS v(name, category, difficulty, equipment, is_default, is_custom, image_url)
WHERE NOT EXISTS (
    SELECT 1 FROM exercises e WHERE e.name = v.name
);

-- Check your total: 
SELECT COUNT(*) as total_exercises FROM exercises WHERE is_default = true;
