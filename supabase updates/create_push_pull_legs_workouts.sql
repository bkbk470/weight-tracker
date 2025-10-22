-- =====================================================
-- CREATE PUSH/PULL/LEGS WORKOUT PROGRAM
-- =====================================================
-- This script creates a 7-day Push/Pull/Legs workout program
-- for user@example.com
-- Run this in your Supabase SQL Editor after the main schema

-- =====================================================
-- STEP 1: Get the user ID for user@example.com
-- =====================================================
DO $$
DECLARE
    v_user_id UUID;
    v_workout_day1_id UUID;
    v_workout_day2_id UUID;
    v_workout_day3_id UUID;
    v_workout_day5_id UUID;
    v_workout_day6_id UUID;
    v_workout_day7_id UUID;
BEGIN
    -- Get user ID
    SELECT id INTO v_user_id FROM auth.users WHERE email = 'user@example.com';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User user@example.com not found. Please create the user first.';
    END IF;

    -- =====================================================
    -- STEP 2: Create Workout Templates
    -- =====================================================

    -- Day 1: Push (Chest, Shoulders, Triceps, Abs)
    INSERT INTO public.workouts (user_id, name, description, difficulty, estimated_duration_minutes)
    VALUES (
        v_user_id,
        'Day 1 - Push (Chest, Shoulders, Triceps)',
        'Push workout focusing on chest, shoulders, and triceps with core work',
        'Intermediate',
        75
    )
    RETURNING id INTO v_workout_day1_id;

    -- Day 2: Pull (Back, Biceps, Rear Delts, Abs)
    INSERT INTO public.workouts (user_id, name, description, difficulty, estimated_duration_minutes)
    VALUES (
        v_user_id,
        'Day 2 - Pull (Back, Biceps, Rear Delts)',
        'Pull workout focusing on back, biceps, and rear delts with core work',
        'Intermediate',
        75
    )
    RETURNING id INTO v_workout_day2_id;

    -- Day 3: Legs (Quads, Hamstrings, Glutes, Calves)
    INSERT INTO public.workouts (user_id, name, description, difficulty, estimated_duration_minutes)
    VALUES (
        v_user_id,
        'Day 3 - Legs (Quads, Hamstrings, Glutes)',
        'Leg workout focusing on quads, hamstrings, glutes, and calves',
        'Intermediate',
        80
    )
    RETURNING id INTO v_workout_day3_id;

    -- Day 5: Push (Chest, Shoulders, Triceps) - Variation
    INSERT INTO public.workouts (user_id, name, description, difficulty, estimated_duration_minutes)
    VALUES (
        v_user_id,
        'Day 5 - Push (Chest, Shoulders, Triceps) V2',
        'Push workout variation with different exercise selection',
        'Intermediate',
        75
    )
    RETURNING id INTO v_workout_day5_id;

    -- Day 6: Pull (Back, Biceps, Rear Delts) - Variation
    INSERT INTO public.workouts (user_id, name, description, difficulty, estimated_duration_minutes)
    VALUES (
        v_user_id,
        'Day 6 - Pull (Back, Biceps, Rear Delts) V2',
        'Pull workout variation with different exercise selection',
        'Intermediate',
        75
    )
    RETURNING id INTO v_workout_day6_id;

    -- Day 7: Legs (Quads, Glutes, Hamstrings) - Variation
    INSERT INTO public.workouts (user_id, name, description, difficulty, estimated_duration_minutes)
    VALUES (
        v_user_id,
        'Day 7 - Legs (Quads, Glutes, Hamstrings) V2',
        'Leg workout variation with different exercise selection',
        'Intermediate',
        80
    )
    RETURNING id INTO v_workout_day7_id;

    -- =====================================================
    -- STEP 3: Add Exercises to Day 1 - Push
    -- =====================================================

    -- Bench Press (4 sets x 6-8 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 0, 4, 8, 180
    FROM public.exercises WHERE name = 'Bench Press' AND is_default = true;

    -- Incline Dumbbell Press (3 sets x 8-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 1, 3, 10, 120
    FROM public.exercises WHERE name = 'Incline Dumbbell Press' AND is_default = true;

    -- Dips (3 sets x 8-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 2, 3, 12, 120
    FROM public.exercises WHERE name = 'Dips' AND is_default = true;

    -- Lateral Raises (3 sets x 12-15 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 3, 3, 15, 90
    FROM public.exercises WHERE name = 'Lateral Raises' AND is_default = true;

    -- Skull Crushers (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 4, 3, 12, 90
    FROM public.exercises WHERE name = 'Skull Crushers' AND is_default = true;

    -- Ab Wheel Rollouts (3 sets x 10-15 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 5, 3, 15, 60
    FROM public.exercises WHERE name = 'Ab Wheel Rollouts' AND is_default = true;

    -- =====================================================
    -- STEP 4: Add Exercises to Day 2 - Pull
    -- =====================================================

    -- Deadlifts (4 sets x 5-6 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 0, 4, 6, 240
    FROM public.exercises WHERE name = 'Deadlifts' AND is_default = true;

    -- Pull-ups (4 sets x 6-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 1, 4, 10, 180
    FROM public.exercises WHERE name = 'Pull-ups' AND is_default = true;

    -- Barbell Rows (3 sets x 8-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 2, 3, 10, 150
    FROM public.exercises WHERE name = 'Barbell Rows' AND is_default = true;

    -- Face Pulls (3 sets x 12-15 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 3, 3, 15, 90
    FROM public.exercises WHERE name = 'Face Pulls' AND is_default = true;

    -- Bicep Curls (3 sets x 10-12 reps) - using Bicep Curls as substitute for Barbell Curl
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 4, 3, 12, 90
    FROM public.exercises WHERE name = 'Bicep Curls' AND is_default = true;

    -- Hammer Curls (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 5, 3, 12, 90
    FROM public.exercises WHERE name = 'Hammer Curls' AND is_default = true;

    -- Hanging Leg Raises (3 sets x 10-15 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 6, 3, 15, 60
    FROM public.exercises WHERE name = 'Hanging Leg Raises' AND is_default = true;

    -- =====================================================
    -- STEP 5: Add Exercises to Day 3 - Legs
    -- =====================================================

    -- Squats (4 sets x 6-8 reps) - using Squats for Back Squat
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 0, 4, 8, 240
    FROM public.exercises WHERE name = 'Squats' AND is_default = true;

    -- Romanian Deadlifts (3 sets x 8-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 1, 3, 10, 180
    FROM public.exercises WHERE name = 'Romanian Deadlifts' AND is_default = true;

    -- Lunges (3 sets x 12-15 reps per leg)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 2, 3, 15, 120
    FROM public.exercises WHERE name = 'Lunges' AND is_default = true;

    -- Leg Press (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 3, 3, 12, 120
    FROM public.exercises WHERE name = 'Leg Press' AND is_default = true;

    -- Calf Raises (4 sets x 15-20 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 4, 4, 20, 60
    FROM public.exercises WHERE name = 'Calf Raises' AND is_default = true;

    -- =====================================================
    -- STEP 6: Add Exercises to Day 5 - Push V2
    -- =====================================================

    -- Incline Bench Press (4 sets x 6-8 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 0, 4, 8, 180
    FROM public.exercises WHERE name = 'Incline Bench Press' AND is_default = true;

    -- Dumbbell Shoulder Press (3 sets x 8-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 1, 3, 10, 120
    FROM public.exercises WHERE name = 'Dumbbell Shoulder Press' AND is_default = true;

    -- Dumbbell Press (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 2, 3, 12, 120
    FROM public.exercises WHERE name = 'Dumbbell Press' AND is_default = true;

    -- Dips (3 sets x 8-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 3, 3, 12, 120
    FROM public.exercises WHERE name = 'Dips' AND is_default = true;

    -- Lateral Raises (3 sets x 12-15 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 4, 3, 15, 90
    FROM public.exercises WHERE name = 'Lateral Raises' AND is_default = true;

    -- Close-Grip Bench Press (3 sets x 8-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 5, 3, 10, 120
    FROM public.exercises WHERE name = 'Close-Grip Bench Press' AND is_default = true;

    -- =====================================================
    -- STEP 7: Add Exercises to Day 6 - Pull V2
    -- =====================================================

    -- Barbell Rows (4 sets x 6-8 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 0, 4, 8, 180
    FROM public.exercises WHERE name = 'Barbell Rows' AND is_default = true;

    -- Chin-ups (4 sets x 6-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 1, 4, 10, 180
    FROM public.exercises WHERE name = 'Chin-ups' AND is_default = true;

    -- T-Bar Rows (3 sets x 8-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 2, 3, 10, 150
    FROM public.exercises WHERE name = 'T-Bar Rows' AND is_default = true;

    -- Dumbbell Rows (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 3, 3, 12, 120
    FROM public.exercises WHERE name = 'Dumbbell Rows' AND is_default = true;

    -- Bicep Curls (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 4, 3, 12, 90
    FROM public.exercises WHERE name = 'Bicep Curls' AND is_default = true;

    -- Face Pulls (3 sets x 12-15 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 5, 3, 15, 90
    FROM public.exercises WHERE name = 'Face Pulls' AND is_default = true;

    -- =====================================================
    -- STEP 8: Add Exercises to Day 7 - Legs V2
    -- =====================================================

    -- Front Squats (4 sets x 6-8 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 0, 4, 8, 240
    FROM public.exercises WHERE name = 'Front Squats' AND is_default = true;

    -- Bulgarian Split Squats (3 sets x 10-12 reps per leg)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 1, 3, 12, 120
    FROM public.exercises WHERE name = 'Bulgarian Split Squats' AND is_default = true;

    -- Leg Press (3 sets x 12-15 reps) - using as substitute for Hip Thrusts
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 2, 3, 15, 120
    FROM public.exercises WHERE name = 'Leg Press' AND is_default = true;

    -- Romanian Deadlifts (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 3, 3, 12, 150
    FROM public.exercises WHERE name = 'Romanian Deadlifts' AND is_default = true;

    -- Calf Raises (4 sets x 15-20 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 4, 4, 20, 60
    FROM public.exercises WHERE name = 'Calf Raises' AND is_default = true;

    RAISE NOTICE 'Successfully created 6 workouts for user@example.com';
    RAISE NOTICE 'Day 1 Push ID: %', v_workout_day1_id;
    RAISE NOTICE 'Day 2 Pull ID: %', v_workout_day2_id;
    RAISE NOTICE 'Day 3 Legs ID: %', v_workout_day3_id;
    RAISE NOTICE 'Day 5 Push V2 ID: %', v_workout_day5_id;
    RAISE NOTICE 'Day 6 Pull V2 ID: %', v_workout_day6_id;
    RAISE NOTICE 'Day 7 Legs V2 ID: %', v_workout_day7_id;

END $$;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Run these to verify the workouts were created correctly

-- Check all workouts for user@example.com
SELECT
    w.name,
    w.difficulty,
    w.estimated_duration_minutes,
    COUNT(we.id) as exercise_count
FROM public.workouts w
LEFT JOIN public.workout_exercises we ON we.workout_id = w.id
WHERE w.user_id = (SELECT id FROM auth.users WHERE email = 'user@example.com')
GROUP BY w.id, w.name, w.difficulty, w.estimated_duration_minutes
ORDER BY w.name;

-- View exercises for each workout
SELECT
    w.name as workout_name,
    e.name as exercise_name,
    we.order_index,
    we.target_sets,
    we.target_reps,
    we.rest_time_seconds
FROM public.workouts w
JOIN public.workout_exercises we ON we.workout_id = w.id
JOIN public.exercises e ON e.id = we.exercise_id
WHERE w.user_id = (SELECT id FROM auth.users WHERE email = 'user@example.com')
ORDER BY w.name, we.order_index;
