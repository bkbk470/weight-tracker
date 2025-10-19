-- =====================================================
-- FIX WORKOUTS TABLE - Complete Reset
-- =====================================================
-- This will recreate the workouts table with the correct schema

-- Step 1: Drop dependent tables first
DROP TABLE IF EXISTS public.workout_exercises CASCADE;
DROP TABLE IF EXISTS public.workouts CASCADE;

-- Step 2: Recreate workouts table with CORRECT schema
CREATE TABLE public.workouts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    difficulty TEXT CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced')),
    estimated_duration_minutes INTEGER,
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Step 3: Recreate workout_exercises table
CREATE TABLE public.workout_exercises (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    workout_id UUID REFERENCES public.workouts ON DELETE CASCADE NOT NULL,
    exercise_id UUID REFERENCES public.exercises ON DELETE CASCADE NOT NULL,
    order_index INTEGER NOT NULL DEFAULT 0,
    target_sets INTEGER NOT NULL DEFAULT 3,
    target_reps INTEGER NOT NULL DEFAULT 10,
    rest_time_seconds INTEGER NOT NULL DEFAULT 90,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(workout_id, exercise_id, order_index)
);

-- Step 4: Enable RLS
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;

-- Step 5: Create policies for workouts
DROP POLICY IF EXISTS "Users can view own workouts" ON public.workouts;
CREATE POLICY "Users can view own workouts" ON public.workouts
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can create own workouts" ON public.workouts;
CREATE POLICY "Users can create own workouts" ON public.workouts
    FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own workouts" ON public.workouts;
CREATE POLICY "Users can update own workouts" ON public.workouts
    FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own workouts" ON public.workouts;
CREATE POLICY "Users can delete own workouts" ON public.workouts
    FOR DELETE USING (user_id = auth.uid());

-- Step 6: Create policies for workout_exercises
DROP POLICY IF EXISTS "Users can view own workout exercises" ON public.workout_exercises;
CREATE POLICY "Users can view own workout exercises" ON public.workout_exercises
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.workouts
            WHERE workouts.id = workout_exercises.workout_id
            AND workouts.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can create own workout exercises" ON public.workout_exercises;
CREATE POLICY "Users can create own workout exercises" ON public.workout_exercises
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.workouts
            WHERE workouts.id = workout_exercises.workout_id
            AND workouts.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update own workout exercises" ON public.workout_exercises;
CREATE POLICY "Users can update own workout exercises" ON public.workout_exercises
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.workouts
            WHERE workouts.id = workout_exercises.workout_id
            AND workouts.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete own workout exercises" ON public.workout_exercises;
CREATE POLICY "Users can delete own workout exercises" ON public.workout_exercises
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.workouts
            WHERE workouts.id = workout_exercises.workout_id
            AND workouts.user_id = auth.uid()
        )
    );

-- Step 7: Create indexes
CREATE INDEX IF NOT EXISTS idx_workouts_user_id ON public.workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_workout_id ON public.workout_exercises(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_exercise_id ON public.workout_exercises(exercise_id);

-- Step 8: Create trigger for updated_at
DROP TRIGGER IF EXISTS set_updated_at ON public.workouts;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.workouts
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =====================================================
-- DONE! Now try creating a workout in the app
-- =====================================================
