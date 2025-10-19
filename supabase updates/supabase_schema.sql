-- =====================================================
-- WEIGHT TRACKER APP - SUPABASE DATABASE SCHEMA
-- =====================================================
-- Run this script in your Supabase SQL Editor
-- This will create all tables, policies, and triggers

-- =====================================================
-- 1. ENABLE UUID EXTENSION
-- =====================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 2. USER PROFILES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
    height_cm DECIMAL(5,2),
    weight_goal_lbs DECIMAL(5,2),
    experience_level TEXT CHECK (experience_level IN ('beginner', 'intermediate', 'advanced')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- =====================================================
-- 3. EXERCISES TABLE (Custom + Default)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.exercises (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Cardio', 'Other')),
    difficulty TEXT NOT NULL CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced')),
    equipment TEXT NOT NULL,
    notes TEXT,
    is_custom BOOLEAN DEFAULT false,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    CONSTRAINT user_or_default CHECK (
        (user_id IS NOT NULL AND is_custom = true AND is_default = false) OR
        (user_id IS NULL AND is_custom = false AND is_default = true)
    )
);

-- =====================================================
-- 4. WORKOUTS TABLE (Workout Templates)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.workouts (
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

-- =====================================================
-- 5. WORKOUT EXERCISES TABLE (Junction for Templates)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.workout_exercises (
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

-- =====================================================
-- 6. WORKOUT LOGS TABLE (Completed Workouts)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.workout_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    workout_id UUID REFERENCES public.workouts ON DELETE SET NULL,
    workout_name TEXT NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- =====================================================
-- 7. EXERCISE SETS TABLE (Logged Sets)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.exercise_sets (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    workout_log_id UUID REFERENCES public.workout_logs ON DELETE CASCADE NOT NULL,
    exercise_id UUID REFERENCES public.exercises ON DELETE SET NULL NOT NULL,
    exercise_name TEXT NOT NULL,
    set_number INTEGER NOT NULL,
    weight_lbs DECIMAL(6,2),
    reps INTEGER,
    completed BOOLEAN DEFAULT true,
    rest_time_seconds INTEGER,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- =====================================================
-- 8. MEASUREMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.measurements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    measurement_type TEXT NOT NULL CHECK (measurement_type IN (
        'weight', 'body_fat',
        'neck', 'shoulders', 'chest',
        'left_bicep', 'right_bicep', 'left_forearm', 'right_forearm',
        'upper_abs', 'waist', 'lower_abs', 'hips',
        'left_thigh', 'right_thigh', 'left_calf', 'right_calf',
        'other'
    )),
    value DECIMAL(6,2) NOT NULL,
    unit TEXT NOT NULL,
    measurement_date TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- =====================================================
-- 9. USER SETTINGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users ON DELETE CASCADE UNIQUE NOT NULL,
    theme_mode TEXT DEFAULT 'system' CHECK (theme_mode IN ('light', 'dark', 'system')),
    weight_unit TEXT DEFAULT 'lbs' CHECK (weight_unit IN ('lbs', 'kg')),
    height_unit TEXT DEFAULT 'cm' CHECK (height_unit IN ('cm', 'inches')),
    notifications_enabled BOOLEAN DEFAULT true,
    rest_timer_sound BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- =====================================================
-- 10. CREATE INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_exercises_user_id ON public.exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_exercises_category ON public.exercises(category);
CREATE INDEX IF NOT EXISTS idx_exercises_is_default ON public.exercises(is_default);
CREATE INDEX IF NOT EXISTS idx_workouts_user_id ON public.workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_workout_id ON public.workout_exercises(workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_exercises_exercise_id ON public.workout_exercises(exercise_id);
CREATE INDEX IF NOT EXISTS idx_workout_logs_user_id ON public.workout_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_logs_start_time ON public.workout_logs(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_exercise_sets_workout_log_id ON public.exercise_sets(workout_log_id);
CREATE INDEX IF NOT EXISTS idx_measurements_user_id ON public.measurements(user_id);
CREATE INDEX IF NOT EXISTS idx_measurements_type_date ON public.measurements(measurement_type, measurement_date DESC);

-- =====================================================
-- 11. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- PROFILES POLICIES
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- EXERCISES POLICIES
CREATE POLICY "Users can view default exercises" ON public.exercises
    FOR SELECT USING (is_default = true OR user_id = auth.uid());

CREATE POLICY "Users can create own exercises" ON public.exercises
    FOR INSERT WITH CHECK (user_id = auth.uid() AND is_custom = true);

CREATE POLICY "Users can update own exercises" ON public.exercises
    FOR UPDATE USING (user_id = auth.uid() AND is_custom = true);

CREATE POLICY "Users can delete own exercises" ON public.exercises
    FOR DELETE USING (user_id = auth.uid() AND is_custom = true);

-- WORKOUTS POLICIES
CREATE POLICY "Users can view own workouts" ON public.workouts
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create own workouts" ON public.workouts
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own workouts" ON public.workouts
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete own workouts" ON public.workouts
    FOR DELETE USING (user_id = auth.uid());

-- WORKOUT EXERCISES POLICIES
CREATE POLICY "Users can view own workout exercises" ON public.workout_exercises
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.workouts
            WHERE workouts.id = workout_exercises.workout_id
            AND workouts.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create own workout exercises" ON public.workout_exercises
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.workouts
            WHERE workouts.id = workout_exercises.workout_id
            AND workouts.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own workout exercises" ON public.workout_exercises
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.workouts
            WHERE workouts.id = workout_exercises.workout_id
            AND workouts.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own workout exercises" ON public.workout_exercises
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.workouts
            WHERE workouts.id = workout_exercises.workout_id
            AND workouts.user_id = auth.uid()
        )
    );

-- WORKOUT LOGS POLICIES
CREATE POLICY "Users can view own workout logs" ON public.workout_logs
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create own workout logs" ON public.workout_logs
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own workout logs" ON public.workout_logs
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete own workout logs" ON public.workout_logs
    FOR DELETE USING (user_id = auth.uid());

-- EXERCISE SETS POLICIES
CREATE POLICY "Users can view own exercise sets" ON public.exercise_sets
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.workout_logs
            WHERE workout_logs.id = exercise_sets.workout_log_id
            AND workout_logs.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create own exercise sets" ON public.exercise_sets
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.workout_logs
            WHERE workout_logs.id = exercise_sets.workout_log_id
            AND workout_logs.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own exercise sets" ON public.exercise_sets
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.workout_logs
            WHERE workout_logs.id = exercise_sets.workout_log_id
            AND workout_logs.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own exercise sets" ON public.exercise_sets
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.workout_logs
            WHERE workout_logs.id = exercise_sets.workout_log_id
            AND workout_logs.user_id = auth.uid()
        )
    );

-- MEASUREMENTS POLICIES
CREATE POLICY "Users can view own measurements" ON public.measurements
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create own measurements" ON public.measurements
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own measurements" ON public.measurements
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete own measurements" ON public.measurements
    FOR DELETE USING (user_id = auth.uid());

-- USER SETTINGS POLICIES
CREATE POLICY "Users can view own settings" ON public.user_settings
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create own settings" ON public.user_settings
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own settings" ON public.user_settings
    FOR UPDATE USING (user_id = auth.uid());

-- =====================================================
-- 12. FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to handle updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.exercises
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.workouts
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.workout_logs
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.measurements
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.user_settings
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Function to create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', '')
    );
    
    INSERT INTO public.user_settings (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- 13. INSERT DEFAULT EXERCISES
-- =====================================================
INSERT INTO public.exercises (name, category, difficulty, equipment, is_default, is_custom) VALUES
-- Chest
('Bench Press', 'Chest', 'Intermediate', 'Barbell', true, false),
('Incline Bench Press', 'Chest', 'Intermediate', 'Barbell', true, false),
('Decline Bench Press', 'Chest', 'Intermediate', 'Barbell', true, false),
('Dumbbell Press', 'Chest', 'Beginner', 'Dumbbell', true, false),
('Incline Dumbbell Press', 'Chest', 'Beginner', 'Dumbbell', true, false),
('Dumbbell Flyes', 'Chest', 'Beginner', 'Dumbbell', true, false),
('Cable Crossover', 'Chest', 'Intermediate', 'Cable', true, false),
('Push-ups', 'Chest', 'Beginner', 'Bodyweight', true, false),
('Dips', 'Chest', 'Intermediate', 'Bodyweight', true, false),

-- Back
('Deadlifts', 'Back', 'Advanced', 'Barbell', true, false),
('Barbell Rows', 'Back', 'Intermediate', 'Barbell', true, false),
('T-Bar Rows', 'Back', 'Intermediate', 'Barbell', true, false),
('Pull-ups', 'Back', 'Intermediate', 'Bodyweight', true, false),
('Chin-ups', 'Back', 'Intermediate', 'Bodyweight', true, false),
('Lat Pulldown', 'Back', 'Beginner', 'Machine', true, false),
('Seated Cable Rows', 'Back', 'Beginner', 'Cable', true, false),
('Face Pulls', 'Back', 'Beginner', 'Cable', true, false),
('Dumbbell Rows', 'Back', 'Beginner', 'Dumbbell', true, false),

-- Legs
('Squats', 'Legs', 'Intermediate', 'Barbell', true, false),
('Front Squats', 'Legs', 'Advanced', 'Barbell', true, false),
('Leg Press', 'Legs', 'Beginner', 'Machine', true, false),
('Lunges', 'Legs', 'Beginner', 'Dumbbell', true, false),
('Romanian Deadlifts', 'Legs', 'Intermediate', 'Barbell', true, false),
('Leg Curls', 'Legs', 'Beginner', 'Machine', true, false),
('Leg Extensions', 'Legs', 'Beginner', 'Machine', true, false),
('Calf Raises', 'Legs', 'Beginner', 'Machine', true, false),
('Bulgarian Split Squats', 'Legs', 'Intermediate', 'Dumbbell', true, false),

-- Shoulders
('Overhead Press', 'Shoulders', 'Intermediate', 'Barbell', true, false),
('Dumbbell Shoulder Press', 'Shoulders', 'Beginner', 'Dumbbell', true, false),
('Lateral Raises', 'Shoulders', 'Beginner', 'Dumbbell', true, false),
('Front Raises', 'Shoulders', 'Beginner', 'Dumbbell', true, false),
('Rear Delt Flyes', 'Shoulders', 'Beginner', 'Dumbbell', true, false),
('Arnold Press', 'Shoulders', 'Intermediate', 'Dumbbell', true, false),
('Upright Rows', 'Shoulders', 'Beginner', 'Barbell', true, false),

-- Arms
('Bicep Curls', 'Arms', 'Beginner', 'Dumbbell', true, false),
('Hammer Curls', 'Arms', 'Beginner', 'Dumbbell', true, false),
('Preacher Curls', 'Arms', 'Beginner', 'Barbell', true, false),
('Cable Curls', 'Arms', 'Beginner', 'Cable', true, false),
('Tricep Dips', 'Arms', 'Intermediate', 'Bodyweight', true, false),
('Tricep Pushdowns', 'Arms', 'Beginner', 'Cable', true, false),
('Skull Crushers', 'Arms', 'Intermediate', 'Barbell', true, false),
('Close-Grip Bench Press', 'Arms', 'Intermediate', 'Barbell', true, false),
('Overhead Tricep Extension', 'Arms', 'Beginner', 'Dumbbell', true, false),

-- Core
('Planks', 'Core', 'Beginner', 'Bodyweight', true, false),
('Crunches', 'Core', 'Beginner', 'Bodyweight', true, false),
('Russian Twists', 'Core', 'Beginner', 'Bodyweight', true, false),
('Leg Raises', 'Core', 'Intermediate', 'Bodyweight', true, false),
('Cable Crunches', 'Core', 'Beginner', 'Cable', true, false),
('Ab Wheel Rollouts', 'Core', 'Advanced', 'Other', true, false),
('Hanging Leg Raises', 'Core', 'Advanced', 'Bodyweight', true, false),
('Mountain Climbers', 'Core', 'Beginner', 'Bodyweight', true, false),

-- Cardio
('Running', 'Cardio', 'Beginner', 'Other', true, false),
('Cycling', 'Cardio', 'Beginner', 'Machine', true, false),
('Jump Rope', 'Cardio', 'Beginner', 'Other', true, false),
('Burpees', 'Cardio', 'Intermediate', 'Bodyweight', true, false),
('Rowing', 'Cardio', 'Beginner', 'Machine', true, false),
('Stair Climbing', 'Cardio', 'Beginner', 'Machine', true, false)
ON CONFLICT DO NOTHING;

-- =====================================================
-- SETUP COMPLETE!
-- =====================================================
-- Next steps:
-- 1. Go to Authentication > Providers in Supabase dashboard
-- 2. Enable Email provider
-- 3. Configure email templates (optional)
-- 4. Copy your Supabase URL and anon key to the Flutter app
-- =====================================================
