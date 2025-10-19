-- Insert ALL 380+ default exercises into the exercises table (COMPLETE VERSION)
-- These will be available to all users (is_default = true, is_custom = false)
-- Run this in your Supabase SQL Editor

-- NOTE: Run the first file (insert_default_exercises.sql) first for Chest, Back, Shoulders, and Arms
-- This file contains the remaining exercises: Legs, Core, Cardio, and Other

INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url) VALUES

-- Legs - Quadriceps (Complete)
('Squat (Band)', 'Legs', 'Beginner', 'Band', true, false, 'Exercises/default_exercise.gif'),
('Squat (Bodyweight)', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Squat (Dumbbell)', 'Legs', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Squat (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Squat (Smith Machine)', 'Legs', 'Intermediate', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Squat (Suspension)', 'Legs', 'Beginner', 'Suspension', true, false, 'Exercises/default_exercise.gif'),
('Box Squat (Barbell)', 'Legs', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Overhead Squat', 'Legs', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Pause Squat (Barbell)', 'Legs', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Full Squat', 'Legs', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Sumo Squat', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Sumo Squat (Barbell)', 'Legs', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Sumo Squat (Dumbbell)', 'Legs', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Sumo Squat (Kettlebell)', 'Legs', 'Beginner', 'Kettlebell', true, false, 'Exercises/default_exercise.gif'),
('Assisted Pistol Squats', 'Legs', 'Intermediate', 'Assisted', true, false, 'Exercises/default_exercise.gif'),
('Sissy Squat (Weighted)', 'Legs', 'Advanced', 'Weighted', true, false, 'Exercises/default_exercise.gif'),
('Zercher Squat', 'Legs', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Hack Squat', 'Legs', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Pendulum Squat (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Leg Press Horizontal (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Single Leg Press (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Lunge', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Lunge (Barbell)', 'Legs', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Reverse Lunge', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Reverse Lunge (Barbell)', 'Legs', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Reverse Lunge (Dumbbell)', 'Legs', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Lateral Lunge', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Jumping Lunge', 'Legs', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Curtsy Lunge (Dumbbell)', 'Legs', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Split Squat (Dumbbell)', 'Legs', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Step Up', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Dumbbell Step Up', 'Legs', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Lateral Box Jump', 'Legs', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),

-- Legs - Hamstrings (Additional)
('Nordic Hamstrings Curls', 'Legs', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Glute Ham Raise', 'Legs', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),

-- Legs - Glutes (Additional)
('Hip Thrust', 'Legs', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Hip Thrust (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Single Leg Hip Thrust', 'Legs', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Single Leg Hip Thrust (Dumbbell)', 'Legs', 'Intermediate', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Glute Kickback on Floor', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Frog Pumps (Dumbbell)', 'Legs', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Hip Abduction (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Hip Adduction (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Clamshell', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Lateral Band Walks', 'Legs', 'Beginner', 'Band', true, false, 'Exercises/default_exercise.gif'),
('Bird Dog', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Frog Jumps', 'Legs', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),

-- Legs - Calves (Additional)
('Standing Calf Raise', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Standing Calf Raise (Barbell)', 'Legs', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Standing Calf Raise (Dumbbell)', 'Legs', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Standing Calf Raise (Smith)', 'Legs', 'Intermediate', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Single Leg Standing Calf Raise', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Single Leg Standing Calf Raise (Barbell)', 'Legs', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Single Leg Standing Calf Raise (Dumbbell)', 'Legs', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Single Leg Standing Calf Raise (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Calf Extension (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),

-- Core/Abs Exercises (Additional)
('Reverse Plank', 'Core', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Crunch (Machine)', 'Core', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Crunch (Weighted)', 'Core', 'Intermediate', 'Weighted', true, false, 'Exercises/default_exercise.gif'),
('Reverse Crunch', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Decline Crunch', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Decline Crunch (Weighted)', 'Core', 'Intermediate', 'Weighted', true, false, 'Exercises/default_exercise.gif'),
('Oblique Crunch', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Bicycle Crunch Raised Legs', 'Core', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Sit Up', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Jackknife Sit Up', 'Core', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Russian Twist (Bodyweight)', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Cable Twist (Down to up)', 'Core', 'Beginner', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('Cable Twist (Up to down)', 'Core', 'Beginner', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('Landmine 180', 'Core', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Hanging Knee Raise', 'Core', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Knee Raise Parallel Bars', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Lying Leg Raise', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Lying Knee Raise', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Toes to Bar', 'Core', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Flutter Kicks', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Ab Scissors', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Heel Taps', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Elbow to Knee', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Side Bend', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Side Bend (Dumbbell)', 'Core', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Cable Core Palloff Press', 'Core', 'Intermediate', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('L-Sit Hold', 'Core', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Jack Knife (Suspension)', 'Core', 'Advanced', 'Suspension', true, false, 'Exercises/default_exercise.gif'),

-- Cardio Exercises (Additional)
('Air Bike', 'Cardio', 'Intermediate', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Stair Machine (Floors)', 'Cardio', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Stair Machine (Steps)', 'Cardio', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('High Knees', 'Cardio', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('High Knee Skips', 'Cardio', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),

-- Olympic Lifts & Full Body (Additional)
('Clean', 'Other', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Clean Pull', 'Other', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Hang Clean', 'Other', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Hang Snatch', 'Other', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Split Jerk', 'Other', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Dumbbell Snatch', 'Other', 'Advanced', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Kettlebell Clean', 'Other', 'Intermediate', 'Kettlebell', true, false, 'Exercises/default_exercise.gif'),
('Kettlebell Turkish Get Up', 'Other', 'Advanced', 'Kettlebell', true, false, 'Exercises/default_exercise.gif'),
('Thruster (Kettlebell)', 'Other', 'Intermediate', 'Kettlebell', true, false, 'Exercises/default_exercise.gif'),
('Squat Row', 'Other', 'Intermediate', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Landmine Squat and Press', 'Other', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Muscle Up', 'Other', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Front Lever Hold', 'Other', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Front Lever Raise', 'Other', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Downward Dog', 'Other', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),

-- Neck Exercises
('Lying Neck Curls (Weighted)', 'Other', 'Beginner', 'Weighted', true, false, 'Exercises/default_exercise.gif'),
('Lying Neck Extension (Weighted)', 'Other', 'Beginner', 'Weighted', true, false, 'Exercises/default_exercise.gif');

-- Successfully inserted all remaining exercises!
-- Combined with the first file, you now have 380+ exercises in your database.
