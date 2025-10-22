-- =====================================================
-- CREATE PUSH/PULL/LEGS WORKOUT PROGRAM
-- =====================================================
-- INSTRUCTIONS:
-- 1. First, find your user ID by running this query:
--    SELECT id, email FROM auth.users;
-- 2. Copy your UUID and paste it in the line below (replace 'YOUR-USER-ID-HERE')
-- 3. Run this script
-- =====================================================

DO $$
DECLARE
    -- ⚠️ REPLACE THIS WITH YOUR ACTUAL USER UUID ⚠️
    v_user_id UUID := 'YOUR-USER-ID-HERE';  -- Example: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

    v_workout_day1_id UUID;
    v_workout_day2_id UUID;
    v_workout_day3_id UUID;
    v_workout_day5_id UUID;
    v_workout_day6_id UUID;
    v_workout_day7_id UUID;
BEGIN
    -- Validate user ID exists
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = v_user_id) THEN
        RAISE EXCEPTION 'User ID % not found in auth.users. Please check your user ID.', v_user_id;
    END IF;

    RAISE NOTICE 'Creating workouts for user ID: %', v_user_id;

    -- =====================================================
    -- STEP 1: Create Workout Templates
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

    RAISE NOTICE 'Created 6 workout templates';

    -- =====================================================
    -- STEP 2: Add Exercises to Day 1 - Push
    -- =====================================================

    -- Bench Press (4 sets x 6-8 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 0, 4, 8, 180
    FROM public.exercises WHERE name = 'Bench Press' AND is_default = true LIMIT 1;

    -- Incline Dumbbell Press (3 sets x 8-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 1, 3, 10, 120
    FROM public.exercises WHERE name = 'Incline Dumbbell Press' AND is_default = true LIMIT 1;

    -- Dips (3 sets x 8-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 2, 3, 12, 120
    FROM public.exercises WHERE name = 'Dips' AND is_default = true LIMIT 1;

    -- Lateral Raises (3 sets x 12-15 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 3, 3, 15, 90
    FROM public.exercises WHERE name = 'Lateral Raises' AND is_default = true LIMIT 1;

    -- Skull Crushers (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 4, 3, 12, 90
    FROM public.exercises WHERE name = 'Skull Crushers' AND is_default = true LIMIT 1;

    -- Ab Wheel Rollouts (3 sets x 10-15 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 5, 3, 15, 60
    FROM public.exercises WHERE name = 'Ab Wheel Rollouts' AND is_default = true LIMIT 1;

    RAISE NOTICE 'Added exercises to Day 1 - Push';

    -- =====================================================
    -- STEP 3: Add Exercises to Day 2 - Pull
    -- =====================================================

    -- Deadlifts (4 sets x 5-6 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 0, 4, 6, 240
    FROM public.exercises WHERE name = 'Deadlifts' AND is_default = true LIMIT 1;

    -- Pull-ups (4 sets x 6-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 1, 4, 10, 180
    FROM public.exercises WHERE name = 'Pull-ups' AND is_default = true LIMIT 1;

    -- Barbell Rows (3 sets x 8-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 2, 3, 10, 150
    FROM public.exercises WHERE name = 'Barbell Rows' AND is_default = true LIMIT 1;

    -- Face Pulls (3 sets x 12-15 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 3, 3, 15, 90
    FROM public.exercises WHERE name = 'Face Pulls' AND is_default = true LIMIT 1;

    -- Bicep Curls (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 4, 3, 12, 90
    FROM public.exercises WHERE name = 'Bicep Curls' AND is_default = true LIMIT 1;

    -- Hammer Curls (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 5, 3, 12, 90
    FROM public.exercises WHERE name = 'Hammer Curls' AND is_default = true LIMIT 1;

    -- Hanging Leg Raises (3 sets x 10-15 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 6, 3, 15, 60
    FROM public.exercises WHERE name = 'Hanging Leg Raises' AND is_default = true LIMIT 1;

    RAISE NOTICE 'Added exercises to Day 2 - Pull';

    -- =====================================================
    -- STEP 4: Add Exercises to Day 3 - Legs
    -- =====================================================

    -- Squats (4 sets x 6-8 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 0, 4, 8, 240
    FROM public.exercises WHERE name = 'Squats' AND is_default = true LIMIT 1;

    -- Romanian Deadlifts (3 sets x 8-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 1, 3, 10, 180
    FROM public.exercises WHERE name = 'Romanian Deadlifts' AND is_default = true LIMIT 1;

    -- Lunges (3 sets x 12-15 reps per leg)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 2, 3, 15, 120
    FROM public.exercises WHERE name = 'Lunges' AND is_default = true LIMIT 1;

    -- Leg Press (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 3, 3, 12, 120
    FROM public.exercises WHERE name = 'Leg Press' AND is_default = true LIMIT 1;

    -- Calf Raises (4 sets x 15-20 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 4, 4, 20, 60
    FROM public.exercises WHERE name = 'Calf Raises' AND is_default = true LIMIT 1;

    RAISE NOTICE 'Added exercises to Day 3 - Legs';

    -- =====================================================
    -- STEP 5: Add Exercises to Day 5 - Push V2
    -- =====================================================

    -- Incline Bench Press (4 sets x 6-8 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 0, 4, 8, 180
    FROM public.exercises WHERE name = 'Incline Bench Press' AND is_default = true LIMIT 1;

    -- Dumbbell Shoulder Press (3 sets x 8-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 1, 3, 10, 120
    FROM public.exercises WHERE name = 'Dumbbell Shoulder Press' AND is_default = true LIMIT 1;

    -- Dumbbell Press (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 2, 3, 12, 120
    FROM public.exercises WHERE name = 'Dumbbell Press' AND is_default = true LIMIT 1;

    -- Dips (3 sets x 8-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 3, 3, 12, 120
    FROM public.exercises WHERE name = 'Dips' AND is_default = true LIMIT 1;

    -- Lateral Raises (3 sets x 12-15 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 4, 3, 15, 90
    FROM public.exercises WHERE name = 'Lateral Raises' AND is_default = true LIMIT 1;

    -- Close-Grip Bench Press (3 sets x 8-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 5, 3, 10, 120
    FROM public.exercises WHERE name = 'Close-Grip Bench Press' AND is_default = true LIMIT 1;

    RAISE NOTICE 'Added exercises to Day 5 - Push V2';

    -- =====================================================
    -- STEP 6: Add Exercises to Day 6 - Pull V2
    -- =====================================================

    -- Barbell Rows (4 sets x 6-8 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 0, 4, 8, 180
    FROM public.exercises WHERE name = 'Barbell Rows' AND is_default = true LIMIT 1;

    -- Chin-ups (4 sets x 6-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 1, 4, 10, 180
    FROM public.exercises WHERE name = 'Chin-ups' AND is_default = true LIMIT 1;

    -- T-Bar Rows (3 sets x 8-10 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 2, 3, 10, 150
    FROM public.exercises WHERE name = 'T-Bar Rows' AND is_default = true LIMIT 1;

    -- Dumbbell Rows (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 3, 3, 12, 120
    FROM public.exercises WHERE name = 'Dumbbell Rows' AND is_default = true LIMIT 1;

    -- Bicep Curls (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 4, 3, 12, 90
    FROM public.exercises WHERE name = 'Bicep Curls' AND is_default = true LIMIT 1;

    -- Face Pulls (3 sets x 12-15 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 5, 3, 15, 90
    FROM public.exercises WHERE name = 'Face Pulls' AND is_default = true LIMIT 1;

    RAISE NOTICE 'Added exercises to Day 6 - Pull V2';

    -- =====================================================
    -- STEP 7: Add Exercises to Day 7 - Legs V2
    -- =====================================================

    -- Front Squats (4 sets x 6-8 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 0, 4, 8, 240
    FROM public.exercises WHERE name = 'Front Squats' AND is_default = true LIMIT 1;

    -- Bulgarian Split Squats (3 sets x 10-12 reps per leg)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 1, 3, 12, 120
    FROM public.exercises WHERE name = 'Bulgarian Split Squats' AND is_default = true LIMIT 1;

    -- Leg Press (3 sets x 12-15 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 2, 3, 15, 120
    FROM public.exercises WHERE name = 'Leg Press' AND is_default = true LIMIT 1;

    -- Romanian Deadlifts (3 sets x 10-12 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 3, 3, 12, 150
    FROM public.exercises WHERE name = 'Romanian Deadlifts' AND is_default = true LIMIT 1;

    -- Calf Raises (4 sets x 15-20 reps)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 4, 4, 20, 60
    FROM public.exercises WHERE name = 'Calf Raises' AND is_default = true LIMIT 1;

    RAISE NOTICE 'Added exercises to Day 7 - Legs V2';

    -- =====================================================
    -- SUCCESS!
    -- =====================================================
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Successfully created 6 workouts!';
    RAISE NOTICE '========================================';
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
-- Uncomment and run these to verify the workouts were created correctly

-- Check all workouts
-- SELECT
--     w.name,
--     w.difficulty,
--     w.estimated_duration_minutes,
--     COUNT(we.id) as exercise_count
-- FROM public.workouts w
-- LEFT JOIN public.workout_exercises we ON we.workout_id = w.id
-- GROUP BY w.id, w.name, w.difficulty, w.estimated_duration_minutes
-- ORDER BY w.name;

-- View exercises for each workout
-- SELECT
--     w.name as workout_name,
--     e.name as exercise_name,
--     we.order_index,
--     we.target_sets,
--     we.target_reps,
--     we.rest_time_seconds
-- FROM public.workouts w
-- JOIN public.workout_exercises we ON we.workout_id = w.id
-- JOIN public.exercises e ON e.id = we.exercise_id
-- ORDER BY w.name, we.order_index;
