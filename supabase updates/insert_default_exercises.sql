-- Insert default exercises into the exercises table
-- These will be available to all users (is_default = true, is_custom = false)
-- Run this in your Supabase SQL Editor

INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url) VALUES
-- Chest Exercises
('Bench Press (Barbell)', 'Chest', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Bench Press (Dumbbell)', 'Chest', 'Intermediate', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Cable Fly Crossovers', 'Chest', 'Beginner', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('Incline Bench Press (Dumbbell)', 'Chest', 'Intermediate', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Chest Dip', 'Chest', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Chest Dip (Assisted)', 'Chest', 'Beginner', 'Assisted', true, false, 'Exercises/default_exercise.gif'),
('Chest Fly (Dumbbell)', 'Chest', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Chest Fly (Machine)', 'Chest', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Chest Press (Machine)', 'Chest', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Decline Bench Press (Barbell)', 'Chest', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Decline Bench Press (Dumbbell)', 'Chest', 'Intermediate', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Incline Bench Press (Barbell)', 'Chest', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Push Up', 'Chest', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Diamond Push Up', 'Chest', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Decline Push Up', 'Chest', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Incline Push Ups', 'Chest', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),

-- Back Exercises
('Bent Over Row (Barbell)', 'Back', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Deadlift (Barbell)', 'Back', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Lat Pulldown (Cable)', 'Back', 'Beginner', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('Seated Cable Row - V Grip (Cable)', 'Back', 'Beginner', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('Pull Up', 'Back', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Pull Up (Assisted)', 'Back', 'Beginner', 'Assisted', true, false, 'Exercises/default_exercise.gif'),
('Pull Up (Weighted)', 'Back', 'Advanced', 'Weighted', true, false, 'Exercises/default_exercise.gif'),
('Chin Up', 'Back', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Bent Over Row (Dumbbell)', 'Back', 'Intermediate', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('T Bar Row', 'Back', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Inverted Row', 'Back', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Face Pull', 'Back', 'Beginner', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('Romanian Deadlift (Barbell)', 'Back', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Sumo Deadlift', 'Back', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif'),

-- Legs Exercises
('Squat (Barbell)', 'Legs', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Leg Press (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Leg Extension (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Lying Leg Curl (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Seated Leg Curl (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Lunge (Dumbbell)', 'Legs', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Bulgarian Split Squat', 'Legs', 'Intermediate', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Front Squat', 'Legs', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Goblet Squat', 'Legs', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Hack Squat (Machine)', 'Legs', 'Intermediate', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Walking Lunge (Dumbbell)', 'Legs', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Box Jump', 'Legs', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Jump Squat', 'Legs', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Pistol Squat', 'Legs', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Wall Sit', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),

-- Glutes Exercises
('Hip Thrust (Barbell)', 'Legs', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Glute Bridge', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Glute Kickback (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Cable Pull Through', 'Legs', 'Beginner', 'Cable', true, false, 'Exercises/default_exercise.gif'),

-- Calves Exercises
('Standing Calf Raise (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Seated Calf Raise', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Calf Press (Machine)', 'Legs', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),

-- Shoulders Exercises
('Shoulder Press (Dumbbell)', 'Shoulders', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Overhead Press (Barbell)', 'Shoulders', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Lateral Raise (Dumbbell)', 'Shoulders', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Front Raise (Dumbbell)', 'Shoulders', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Rear Delt Reverse Fly (Dumbbell)', 'Shoulders', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Arnold Press (Dumbbell)', 'Shoulders', 'Intermediate', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Upright Row (Barbell)', 'Shoulders', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Pike Pushup', 'Shoulders', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Handstand Push Up', 'Shoulders', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Seated Overhead Press (Dumbbell)', 'Shoulders', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),

-- Arms - Biceps
('Bicep Curl (Dumbbell)', 'Arms', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Hammer Curl (Dumbbell)', 'Arms', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Bicep Curl (Barbell)', 'Arms', 'Beginner', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Bicep Curl (Cable)', 'Arms', 'Beginner', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('Preacher Curl (Barbell)', 'Arms', 'Beginner', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Preacher Curl (Dumbbell)', 'Arms', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Concentration Curl', 'Arms', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('EZ Bar Biceps Curl', 'Arms', 'Beginner', 'Barbell', true, false, 'Exercises/default_exercise.gif'),

-- Arms - Triceps
('Triceps Pushdown', 'Arms', 'Beginner', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('Triceps Rope Pushdown', 'Arms', 'Beginner', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('Triceps Dip', 'Arms', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Triceps Dip (Assisted)', 'Arms', 'Beginner', 'Assisted', true, false, 'Exercises/default_exercise.gif'),
('Skullcrusher (Barbell)', 'Arms', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Triceps Extension (Dumbbell)', 'Arms', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Triceps Kickback (Dumbbell)', 'Arms', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Bench Press - Close Grip (Barbell)', 'Arms', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif'),

-- Core/Abs Exercises
('Plank', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Crunch', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Bicycle Crunch', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Russian Twist (Weighted)', 'Core', 'Beginner', 'Weighted', true, false, 'Exercises/default_exercise.gif'),
('Hanging Leg Raise', 'Core', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Leg Raise Parallel Bars', 'Core', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Cable Crunch', 'Core', 'Beginner', 'Cable', true, false, 'Exercises/default_exercise.gif'),
('Ab Wheel', 'Core', 'Advanced', 'Ab Wheel', true, false, 'Exercises/default_exercise.gif'),
('Mountain Climber', 'Core', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Side Plank', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Dead Bug', 'Core', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Hollow Rock', 'Core', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('V Up', 'Core', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),

-- Cardio Exercises
('Running', 'Cardio', 'Beginner', 'None', true, false, 'Exercises/default_exercise.gif'),
('Jump Rope', 'Cardio', 'Intermediate', 'Jump Rope', true, false, 'Exercises/default_exercise.gif'),
('Burpee', 'Cardio', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),
('Rowing Machine', 'Cardio', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Treadmill', 'Cardio', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Elliptical Trainer', 'Cardio', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Spinning', 'Cardio', 'Beginner', 'Machine', true, false, 'Exercises/default_exercise.gif'),
('Battle Ropes', 'Cardio', 'Intermediate', 'Battle Ropes', true, false, 'Exercises/default_exercise.gif'),
('Boxing', 'Cardio', 'Intermediate', 'None', true, false, 'Exercises/default_exercise.gif'),
('Jumping Jack', 'Cardio', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif'),

-- Full Body / Olympic Lifts
('Clean and Jerk', 'Other', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Snatch', 'Other', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Power Clean', 'Other', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif'),
('Kettlebell Swing', 'Other', 'Intermediate', 'Kettlebell', true, false, 'Exercises/default_exercise.gif'),
('Farmers Walk', 'Other', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif'),
('Sled Push', 'Other', 'Intermediate', 'Sled', true, false, 'Exercises/default_exercise.gif'),
('Wall Ball', 'Other', 'Intermediate', 'Medicine Ball', true, false, 'Exercises/default_exercise.gif'),
('Ball Slams', 'Other', 'Intermediate', 'Medicine Ball', true, false, 'Exercises/default_exercise.gif');

-- Note: This inserts the most common/popular exercises from the list.
-- You can add more by following the same pattern.
-- All exercises use the default GIF image path you set up.
