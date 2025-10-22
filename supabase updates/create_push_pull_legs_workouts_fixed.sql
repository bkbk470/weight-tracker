-- =====================================================
-- CREATE PUSH/PULL/LEGS WORKOUT PROGRAM - FIXED VERSION
-- =====================================================
-- This version uses the ACTUAL exercise names from your database
-- =====================================================

DO $$
DECLARE
    v_user_id UUID := '1167db04-7c58-4351-a94a-954a61dbed52';

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

    INSERT INTO public.workouts (user_id, name, description, difficulty, estimated_duration_minutes)
    VALUES (v_user_id, 'Day 1 - Push (Chest, Shoulders, Triceps)', 'Push workout focusing on chest, shoulders, and triceps with core work', 'Intermediate', 75)
    RETURNING id INTO v_workout_day1_id;

    INSERT INTO public.workouts (user_id, name, description, difficulty, estimated_duration_minutes)
    VALUES (v_user_id, 'Day 2 - Pull (Back, Biceps, Rear Delts)', 'Pull workout focusing on back, biceps, and rear delts with core work', 'Intermediate', 75)
    RETURNING id INTO v_workout_day2_id;

    INSERT INTO public.workouts (user_id, name, description, difficulty, estimated_duration_minutes)
    VALUES (v_user_id, 'Day 3 - Legs (Quads, Hamstrings, Glutes)', 'Leg workout focusing on quads, hamstrings, glutes, and calves', 'Intermediate', 80)
    RETURNING id INTO v_workout_day3_id;

    INSERT INTO public.workouts (user_id, name, description, difficulty, estimated_duration_minutes)
    VALUES (v_user_id, 'Day 5 - Push (Chest, Shoulders, Triceps) V2', 'Push workout variation with different exercise selection', 'Intermediate', 75)
    RETURNING id INTO v_workout_day5_id;

    INSERT INTO public.workouts (user_id, name, description, difficulty, estimated_duration_minutes)
    VALUES (v_user_id, 'Day 6 - Pull (Back, Biceps, Rear Delts) V2', 'Pull workout variation with different exercise selection', 'Intermediate', 75)
    RETURNING id INTO v_workout_day6_id;

    INSERT INTO public.workouts (user_id, name, description, difficulty, estimated_duration_minutes)
    VALUES (v_user_id, 'Day 7 - Legs (Quads, Glutes, Hamstrings) V2', 'Leg workout variation with different exercise selection', 'Intermediate', 80)
    RETURNING id INTO v_workout_day7_id;

    RAISE NOTICE 'Created 6 workout templates';

    -- =====================================================
    -- STEP 2: Add Exercises to Day 1 - Push
    -- =====================================================

    -- Bench Press (using Bench Press - Wide Grip as closest match)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 0, 4, 8, 180
    FROM public.exercises WHERE name = 'Bench Press - Wide Grip (Barbell)' AND is_default = true LIMIT 1;

    -- Incline Dumbbell Press
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 1, 3, 10, 120
    FROM public.exercises WHERE name = 'Incline Bench Press (Dumbbell)' AND is_default = true LIMIT 1;

    -- Chest Dips
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 2, 3, 12, 120
    FROM public.exercises WHERE name = 'Chest Dip' AND is_default = true LIMIT 1;

    -- Lateral Raises
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 3, 3, 15, 90
    FROM public.exercises WHERE name = 'Lateral Raise (Dumbbell)' AND is_default = true LIMIT 1;

    -- Skull Crushers (using Triceps Pushdown as substitute)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 4, 3, 12, 90
    FROM public.exercises WHERE name = 'Triceps Pushdown' AND is_default = true LIMIT 1;

    -- Ab Wheel
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day1_id, id, 5, 3, 15, 60
    FROM public.exercises WHERE name = 'Ab Wheel' AND is_default = true LIMIT 1;

    RAISE NOTICE 'Added exercises to Day 1 - Push';

    -- =====================================================
    -- STEP 3: Add Exercises to Day 2 - Pull
    -- =====================================================

    -- Deadlifts
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 0, 4, 6, 240
    FROM public.exercises WHERE name = 'Deadlift (Barbell)' AND is_default = true LIMIT 1;

    -- Pull-ups (using Chin Up as alternative)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 1, 4, 10, 180
    FROM public.exercises WHERE name = 'Chin Up' AND is_default = true LIMIT 1;

    -- Bent Over Row (Barbell)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 2, 3, 10, 150
    FROM public.exercises WHERE name = 'Bent Over Row (Barbell)' AND is_default = true LIMIT 1;

    -- Face Pull
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 3, 3, 15, 90
    FROM public.exercises WHERE name = 'Face Pull' AND is_default = true LIMIT 1;

    -- Bicep Curl (Barbell)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 4, 3, 12, 90
    FROM public.exercises WHERE name = 'Bicep Curl (Barbell)' AND is_default = true LIMIT 1;

    -- Hammer Curl (using Cross Body Hammer Curl)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 5, 3, 12, 90
    FROM public.exercises WHERE name = 'Cross Body Hammer Curl' AND is_default = true LIMIT 1;

    -- Hanging Leg Raises (using Leg Raises or Ab Scissors)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day2_id, id, 6, 3, 15, 60
    FROM public.exercises WHERE name = 'Ab Scissors' AND is_default = true LIMIT 1;

    RAISE NOTICE 'Added exercises to Day 2 - Pull';

    -- =====================================================
    -- STEP 4: Add Exercises to Day 3 - Legs
    -- =====================================================

    -- Squat (Barbell)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 0, 4, 8, 240
    FROM public.exercises WHERE name = 'Squat (Barbell)' AND is_default = true LIMIT 1;

    -- Romanian Deadlifts (using Deadlift (Barbell) variation)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 1, 3, 10, 180
    FROM public.exercises WHERE name = 'Deadlift (Barbell)' AND is_default = true LIMIT 1;

    -- Bulgarian Split Squat
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 2, 3, 15, 120
    FROM public.exercises WHERE name = 'Bulgarian Split Squat' AND is_default = true LIMIT 1;

    -- Leg Press (Machine)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 3, 3, 12, 120
    FROM public.exercises WHERE name = 'Leg Press (Machine)' AND is_default = true LIMIT 1;

    -- Calf Raises (using Calf Press Machine)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day3_id, id, 4, 4, 20, 60
    FROM public.exercises WHERE name = 'Calf Press (Machine)' AND is_default = true LIMIT 1;

    RAISE NOTICE 'Added exercises to Day 3 - Legs';

    -- =====================================================
    -- STEP 5: Add Exercises to Day 5 - Push V2
    -- =====================================================

    -- Incline Bench Press (Dumbbell)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 0, 4, 8, 180
    FROM public.exercises WHERE name = 'Incline Bench Press (Dumbbell)' AND is_default = true LIMIT 1;

    -- Shoulder Press (Dumbbell)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 1, 3, 10, 120
    FROM public.exercises WHERE name = 'Shoulder Press (Dumbbell)' AND is_default = true LIMIT 1;

    -- Chest Press (Machine) as substitute for Dumbbell Press
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 2, 3, 12, 120
    FROM public.exercises WHERE name = 'Chest Press (Machine)' AND is_default = true LIMIT 1;

    -- Chest Dip
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 3, 3, 12, 120
    FROM public.exercises WHERE name = 'Chest Dip' AND is_default = true LIMIT 1;

    -- Lateral Raise (Dumbbell)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 4, 3, 15, 90
    FROM public.exercises WHERE name = 'Lateral Raise (Dumbbell)' AND is_default = true LIMIT 1;

    -- Close-Grip Bench Press
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day5_id, id, 5, 3, 10, 120
    FROM public.exercises WHERE name = 'Bench Press - Close Grip (Barbell)' AND is_default = true LIMIT 1;

    RAISE NOTICE 'Added exercises to Day 5 - Push V2';

    -- =====================================================
    -- STEP 6: Add Exercises to Day 6 - Pull V2
    -- =====================================================

    -- Bent Over Row (Barbell)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 0, 4, 8, 180
    FROM public.exercises WHERE name = 'Bent Over Row (Barbell)' AND is_default = true LIMIT 1;

    -- Chin Up (Weighted)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 1, 4, 10, 180
    FROM public.exercises WHERE name = 'Chin Up (Weighted)' AND is_default = true LIMIT 1;

    -- Bent Over Row (Dumbbell) as T-Bar Row substitute
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 2, 3, 10, 150
    FROM public.exercises WHERE name = 'Bent Over Row (Dumbbell)' AND is_default = true LIMIT 1;

    -- Chest Supported Incline Row (Dumbbell) as additional row variation
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 3, 3, 12, 120
    FROM public.exercises WHERE name = 'Chest Supported Incline Row (Dumbbell)' AND is_default = true LIMIT 1;

    -- Bicep Curl (Barbell)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 4, 3, 12, 90
    FROM public.exercises WHERE name = 'Bicep Curl (Barbell)' AND is_default = true LIMIT 1;

    -- Face Pull
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day6_id, id, 5, 3, 15, 90
    FROM public.exercises WHERE name = 'Face Pull' AND is_default = true LIMIT 1;

    RAISE NOTICE 'Added exercises to Day 6 - Pull V2';

    -- =====================================================
    -- STEP 7: Add Exercises to Day 7 - Legs V2
    -- =====================================================

    -- Front Squat (using Squat variation or Box Squat)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 0, 4, 8, 240
    FROM public.exercises WHERE name = 'Box Squat (Barbell)' AND is_default = true LIMIT 1;

    -- Bulgarian Split Squat
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 1, 3, 12, 120
    FROM public.exercises WHERE name = 'Bulgarian Split Squat' AND is_default = true LIMIT 1;

    -- Leg Press (Machine)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 2, 3, 15, 120
    FROM public.exercises WHERE name = 'Leg Press (Machine)' AND is_default = true LIMIT 1;

    -- Deadlift (Barbell) lighter for RDL
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 3, 3, 12, 150
    FROM public.exercises WHERE name = 'Deadlift (Barbell)' AND is_default = true LIMIT 1;

    -- Calf Press (Machine)
    INSERT INTO public.workout_exercises (workout_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds)
    SELECT v_workout_day7_id, id, 4, 4, 20, 60
    FROM public.exercises WHERE name = 'Calf Press (Machine)' AND is_default = true LIMIT 1;

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
