-- =====================================================
-- FIX DUPLICATE CUSTOM EXERCISES SAFELY
-- =====================================================
-- This script migrates references from custom duplicate exercises
-- to default exercises, then removes the duplicates
-- =====================================================

DO $$
DECLARE
    v_custom_pullups_id UUID;
    v_default_chinup_id UUID;

    v_custom_barbell_rows_id UUID;
    v_default_barbell_rows_id UUID;

    v_custom_leg_press_id UUID;
    v_default_leg_press_id UUID;

    v_custom_deadlifts_id UUID;
    v_default_deadlifts_id UUID;

    v_custom_dumbbell_flyes_id UUID;
    v_default_dumbbell_flyes_id UUID;
BEGIN
    RAISE NOTICE 'Starting exercise migration...';

    -- =====================================================
    -- STEP 1: Get IDs of custom and default exercises
    -- =====================================================

    -- Pull-ups (custom) -> Chin Up (default)
    SELECT id INTO v_custom_pullups_id
    FROM public.exercises
    WHERE name = 'Pull-ups' AND user_id = '1167db04-7c58-4351-a94a-954a61dbed52' AND is_custom = true;

    SELECT id INTO v_default_chinup_id
    FROM public.exercises
    WHERE name = 'Chin Up' AND is_default = true;

    -- Barbell Rows (custom) -> Bent Over Row (Barbell) (default)
    SELECT id INTO v_custom_barbell_rows_id
    FROM public.exercises
    WHERE name = 'Barbell Rows' AND user_id = '1167db04-7c58-4351-a94a-954a61dbed52' AND is_custom = true;

    SELECT id INTO v_default_barbell_rows_id
    FROM public.exercises
    WHERE name = 'Bent Over Row (Barbell)' AND is_default = true;

    -- Leg Press (custom) -> Leg Press (Machine) (default)
    SELECT id INTO v_custom_leg_press_id
    FROM public.exercises
    WHERE name = 'Leg Press' AND user_id = '1167db04-7c58-4351-a94a-954a61dbed52' AND is_custom = true;

    SELECT id INTO v_default_leg_press_id
    FROM public.exercises
    WHERE name = 'Leg Press (Machine)' AND is_default = true;

    -- Deadlifts (custom) -> Deadlift (Barbell) (default)
    SELECT id INTO v_custom_deadlifts_id
    FROM public.exercises
    WHERE name = 'Deadlifts' AND user_id = '1167db04-7c58-4351-a94a-954a61dbed52' AND is_custom = true;

    SELECT id INTO v_default_deadlifts_id
    FROM public.exercises
    WHERE name = 'Deadlift (Barbell)' AND is_default = true;

    -- Dumbbell Flyes (custom) -> Chest Fly (Dumbbell) (default)
    SELECT id INTO v_custom_dumbbell_flyes_id
    FROM public.exercises
    WHERE name = 'Dumbbell Flyes' AND user_id = '1167db04-7c58-4351-a94a-954a61dbed52' AND is_custom = true;

    SELECT id INTO v_default_dumbbell_flyes_id
    FROM public.exercises
    WHERE name = 'Chest Fly (Dumbbell)' AND is_default = true;

    RAISE NOTICE 'Found exercise IDs';

    -- =====================================================
    -- STEP 2: Update workout_exercises references
    -- =====================================================

    IF v_custom_pullups_id IS NOT NULL AND v_default_chinup_id IS NOT NULL THEN
        UPDATE public.workout_exercises
        SET exercise_id = v_default_chinup_id
        WHERE exercise_id = v_custom_pullups_id;
        RAISE NOTICE 'Updated workout_exercises: Pull-ups -> Chin Up';
    END IF;

    IF v_custom_barbell_rows_id IS NOT NULL AND v_default_barbell_rows_id IS NOT NULL THEN
        UPDATE public.workout_exercises
        SET exercise_id = v_default_barbell_rows_id
        WHERE exercise_id = v_custom_barbell_rows_id;
        RAISE NOTICE 'Updated workout_exercises: Barbell Rows -> Bent Over Row (Barbell)';
    END IF;

    IF v_custom_leg_press_id IS NOT NULL AND v_default_leg_press_id IS NOT NULL THEN
        UPDATE public.workout_exercises
        SET exercise_id = v_default_leg_press_id
        WHERE exercise_id = v_custom_leg_press_id;
        RAISE NOTICE 'Updated workout_exercises: Leg Press -> Leg Press (Machine)';
    END IF;

    IF v_custom_deadlifts_id IS NOT NULL AND v_default_deadlifts_id IS NOT NULL THEN
        UPDATE public.workout_exercises
        SET exercise_id = v_default_deadlifts_id
        WHERE exercise_id = v_custom_deadlifts_id;
        RAISE NOTICE 'Updated workout_exercises: Deadlifts -> Deadlift (Barbell)';
    END IF;

    IF v_custom_dumbbell_flyes_id IS NOT NULL AND v_default_dumbbell_flyes_id IS NOT NULL THEN
        UPDATE public.workout_exercises
        SET exercise_id = v_default_dumbbell_flyes_id
        WHERE exercise_id = v_custom_dumbbell_flyes_id;
        RAISE NOTICE 'Updated workout_exercises: Dumbbell Flyes -> Chest Fly (Dumbbell)';
    END IF;

    -- =====================================================
    -- STEP 3: Update exercise_sets references
    -- =====================================================

    IF v_custom_pullups_id IS NOT NULL AND v_default_chinup_id IS NOT NULL THEN
        UPDATE public.exercise_sets
        SET exercise_id = v_default_chinup_id
        WHERE exercise_id = v_custom_pullups_id;
        RAISE NOTICE 'Updated exercise_sets: Pull-ups -> Chin Up';
    END IF;

    IF v_custom_barbell_rows_id IS NOT NULL AND v_default_barbell_rows_id IS NOT NULL THEN
        UPDATE public.exercise_sets
        SET exercise_id = v_default_barbell_rows_id
        WHERE exercise_id = v_custom_barbell_rows_id;
        RAISE NOTICE 'Updated exercise_sets: Barbell Rows -> Bent Over Row (Barbell)';
    END IF;

    IF v_custom_leg_press_id IS NOT NULL AND v_default_leg_press_id IS NOT NULL THEN
        UPDATE public.exercise_sets
        SET exercise_id = v_default_leg_press_id
        WHERE exercise_id = v_custom_leg_press_id;
        RAISE NOTICE 'Updated exercise_sets: Leg Press -> Leg Press (Machine)';
    END IF;

    IF v_custom_deadlifts_id IS NOT NULL AND v_default_deadlifts_id IS NOT NULL THEN
        UPDATE public.exercise_sets
        SET exercise_id = v_default_deadlifts_id
        WHERE exercise_id = v_custom_deadlifts_id;
        RAISE NOTICE 'Updated exercise_sets: Deadlifts -> Deadlift (Barbell)';
    END IF;

    IF v_custom_dumbbell_flyes_id IS NOT NULL AND v_default_dumbbell_flyes_id IS NOT NULL THEN
        UPDATE public.exercise_sets
        SET exercise_id = v_default_dumbbell_flyes_id
        WHERE exercise_id = v_custom_dumbbell_flyes_id;
        RAISE NOTICE 'Updated exercise_sets: Dumbbell Flyes -> Chest Fly (Dumbbell)';
    END IF;

    -- =====================================================
    -- STEP 4: Delete custom duplicate exercises
    -- =====================================================

    DELETE FROM public.exercises
    WHERE user_id = '1167db04-7c58-4351-a94a-954a61dbed52'
    AND is_custom = true
    AND name IN ('Pull-ups', 'Barbell Rows', 'Leg Press', 'Deadlifts', 'Dumbbell Flyes');

    RAISE NOTICE 'Deleted custom duplicate exercises';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Migration complete!';
    RAISE NOTICE '========================================';

END $$;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check remaining exercises
SELECT
  name,
  user_id,
  is_custom,
  is_default,
  CASE
    WHEN user_id IS NULL AND is_default = true THEN '✓ Available to everyone'
    WHEN user_id IS NOT NULL AND is_custom = true THEN 'Custom (user-specific)'
    ELSE 'Unknown'
  END as availability
FROM public.exercises
WHERE name IN ('Pull-ups', 'Barbell Rows', 'Leg Press', 'Deadlifts', 'Dumbbell Flyes',
               'Bent Over Row (Barbell)', 'Leg Press (Machine)', 'Deadlift (Barbell)',
               'Chin Up', 'Chest Fly (Dumbbell)')
ORDER BY name, is_default DESC;

-- Check exercise_sets to confirm they now use default exercises
SELECT
  es.exercise_name,
  e.name as actual_exercise_name,
  e.is_default,
  COUNT(*) as set_count
FROM public.exercise_sets es
JOIN public.exercises e ON e.id = es.exercise_id
WHERE es.exercise_name IN ('Pull-ups', 'Barbell Rows', 'Leg Press', 'Deadlifts', 'Dumbbell Flyes')
GROUP BY es.exercise_name, e.name, e.is_default
ORDER BY es.exercise_name;
