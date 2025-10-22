-- =====================================================
-- INSERT EXERCISES SAFELY
-- =====================================================
-- This version checks for existing exercises before inserting
-- Works even without unique constraints
-- =====================================================

-- First, let's insert the comprehensive exercise list
-- We'll use a different approach without ON CONFLICT

DO $$
BEGIN
    -- CHEST EXERCISES
    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Bench Press (Barbell)' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Bench Press (Barbell)', 'Chest', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Bench Press (Dumbbell)' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Bench Press (Dumbbell)', 'Chest', 'Intermediate', 'Dumbbell', true, false, 'Exercises/default_exercise.gif');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Incline Bench Press (Barbell)' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Incline Bench Press (Barbell)', 'Chest', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Decline Bench Press (Barbell)' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Decline Bench Press (Barbell)', 'Chest', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Push Up' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Push Up', 'Chest', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif');
    END IF;

    -- BACK EXERCISES
    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Pull Up' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Pull Up', 'Back', 'Intermediate', 'Bodyweight', true, false, 'Exercises/default_exercise.gif');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Romanian Deadlift (Barbell)' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Romanian Deadlift (Barbell)', 'Back', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'T Bar Row' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('T Bar Row', 'Back', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif');
    END IF;

    -- LEGS EXERCISES
    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Front Squat (Barbell)' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Front Squat (Barbell)', 'Legs', 'Advanced', 'Barbell', true, false, 'Exercises/default_exercise.gif');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Walking Lunge' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Walking Lunge', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Standing Calf Raise' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Standing Calf Raise', 'Legs', 'Beginner', 'Bodyweight', true, false, 'Exercises/default_exercise.gif');
    END IF;

    -- ARMS EXERCISES
    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Hammer Curl (Dumbbell)' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Hammer Curl (Dumbbell)', 'Arms', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Skull Crusher (Barbell)' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Skull Crusher (Barbell)', 'Arms', 'Intermediate', 'Barbell', true, false, 'Exercises/default_exercise.gif');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Overhead Tricep Extension (Dumbbell)' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Overhead Tricep Extension (Dumbbell)', 'Arms', 'Beginner', 'Dumbbell', true, false, 'Exercises/default_exercise.gif');
    END IF;

    -- CORE EXERCISES
    IF NOT EXISTS (SELECT 1 FROM exercises WHERE name = 'Hanging Leg Raise' AND is_default = true) THEN
        INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, image_url)
        VALUES ('Hanging Leg Raise', 'Core', 'Advanced', 'Bodyweight', true, false, 'Exercises/default_exercise.gif');
    END IF;

    RAISE NOTICE 'Added missing exercises for Push/Pull/Legs program';
END $$;

-- Verify what we have
SELECT
    category,
    COUNT(*) as exercise_count,
    COUNT(*) FILTER (WHERE is_default = true) as default_count,
    COUNT(*) FILTER (WHERE is_custom = true) as custom_count
FROM exercises
GROUP BY category
ORDER BY category;
