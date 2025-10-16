-- =====================================================
-- WORKOUT TEMPLATES TABLE
-- =====================================================
-- This table stores pre-made workout templates that all users can access
-- These are example workouts that users can duplicate and customize

-- Create workout_templates table
CREATE TABLE IF NOT EXISTS workout_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL DEFAULT 'General',
  difficulty TEXT CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced')) DEFAULT 'Intermediate',
  estimated_duration_minutes INTEGER DEFAULT 45,
  target_muscle_groups TEXT[], -- Array of muscle groups (e.g., ['Chest', 'Triceps'])
  equipment_needed TEXT[], -- Array of equipment (e.g., ['Barbell', 'Bench'])
  is_featured BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create workout_template_exercises table (similar to workout_exercises)
CREATE TABLE IF NOT EXISTS workout_template_exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id UUID NOT NULL REFERENCES workout_templates(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  order_index INTEGER NOT NULL,
  target_sets INTEGER DEFAULT 3,
  target_reps INTEGER DEFAULT 10,
  rest_time_seconds INTEGER DEFAULT 90,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(template_id, order_index)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_workout_templates_category ON workout_templates(category);
CREATE INDEX IF NOT EXISTS idx_workout_templates_difficulty ON workout_templates(difficulty);
CREATE INDEX IF NOT EXISTS idx_workout_templates_featured ON workout_templates(is_featured);
CREATE INDEX IF NOT EXISTS idx_workout_template_exercises_template_id ON workout_template_exercises(template_id);
CREATE INDEX IF NOT EXISTS idx_workout_template_exercises_exercise_id ON workout_template_exercises(exercise_id);

-- Enable RLS (Row Level Security)
ALTER TABLE workout_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_template_exercises ENABLE ROW LEVEL SECURITY;

-- Create policies (all users can read templates, but only admins can create/update/delete)
CREATE POLICY "Anyone can view workout templates"
  ON workout_templates FOR SELECT
  USING (true);

CREATE POLICY "Anyone can view workout template exercises"
  ON workout_template_exercises FOR SELECT
  USING (true);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_workout_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_workout_templates_updated_at
  BEFORE UPDATE ON workout_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_templates_updated_at();

-- =====================================================
-- INSERT SAMPLE WORKOUT TEMPLATES
-- =====================================================

-- First, let's ensure we have some default exercises
-- (You may need to adjust these IDs based on your existing exercises table)

-- Template 1: Full Body Strength
INSERT INTO workout_templates (name, description, category, difficulty, estimated_duration_minutes, target_muscle_groups, equipment_needed, is_featured)
VALUES (
  'Full Body Strength',
  'A complete full-body workout targeting all major muscle groups. Perfect for building overall strength and muscle mass.',
  'Strength',
  'Intermediate',
  60,
  ARRAY['Chest', 'Back', 'Legs', 'Shoulders', 'Arms'],
  ARRAY['Barbell', 'Dumbbells', 'Bench'],
  true
);

-- Template 2: Upper Body Power
INSERT INTO workout_templates (name, description, category, difficulty, estimated_duration_minutes, target_muscle_groups, equipment_needed, is_featured)
VALUES (
  'Upper Body Power',
  'Focus on chest, back, shoulders, and arms. Build upper body strength and muscle definition.',
  'Strength',
  'Beginner',
  45,
  ARRAY['Chest', 'Back', 'Shoulders', 'Arms'],
  ARRAY['Dumbbells', 'Bench', 'Pull-up Bar'],
  true
);

-- Template 3: Lower Body Blast
INSERT INTO workout_templates (name, description, category, difficulty, estimated_duration_minutes, target_muscle_groups, equipment_needed, is_featured)
VALUES (
  'Lower Body Blast',
  'Intense leg and core workout. Build powerful legs and a strong foundation.',
  'Strength',
  'Advanced',
  50,
  ARRAY['Legs', 'Core', 'Glutes'],
  ARRAY['Barbell', 'Leg Press', 'Dumbbells'],
  true
);

-- Template 4: Core Focus
INSERT INTO workout_templates (name, description, category, difficulty, estimated_duration_minutes, target_muscle_groups, equipment_needed, is_featured)
VALUES (
  'Core Focus',
  'Dedicated core and stability training. Perfect for building a strong, functional midsection.',
  'Core',
  'Beginner',
  30,
  ARRAY['Core', 'Abs'],
  ARRAY['Mat', 'Medicine Ball'],
  false
);

-- Template 5: Push Day
INSERT INTO workout_templates (name, description, category, difficulty, estimated_duration_minutes, target_muscle_groups, equipment_needed, is_featured)
VALUES (
  'Push Day',
  'Classic push workout focusing on chest, shoulders, and triceps.',
  'Strength',
  'Intermediate',
  45,
  ARRAY['Chest', 'Shoulders', 'Triceps'],
  ARRAY['Barbell', 'Dumbbells', 'Bench'],
  true
);

-- Template 6: Pull Day
INSERT INTO workout_templates (name, description, category, difficulty, estimated_duration_minutes, target_muscle_groups, equipment_needed, is_featured)
VALUES (
  'Pull Day',
  'Back and biceps focused workout. Build a strong back and powerful arms.',
  'Strength',
  'Intermediate',
  45,
  ARRAY['Back', 'Biceps'],
  ARRAY['Pull-up Bar', 'Dumbbells', 'Cable Machine'],
  true
);

-- Template 7: Leg Day
INSERT INTO workout_templates (name, description, category, difficulty, estimated_duration_minutes, target_muscle_groups, equipment_needed, is_featured)
VALUES (
  'Leg Day',
  'Complete lower body workout. Build strong, powerful legs.',
  'Strength',
  'Intermediate',
  50,
  ARRAY['Legs', 'Glutes', 'Calves'],
  ARRAY['Barbell', 'Leg Press', 'Leg Curl Machine'],
  true
);

-- Template 8: Quick HIIT
INSERT INTO workout_templates (name, description, category, difficulty, estimated_duration_minutes, target_muscle_groups, equipment_needed, is_featured)
VALUES (
  'Quick HIIT',
  'High-intensity interval training for fat burning and conditioning.',
  'Cardio',
  'Intermediate',
  20,
  ARRAY['Full Body'],
  ARRAY['Bodyweight'],
  false
);

-- Template 9: Beginner's Full Body
INSERT INTO workout_templates (name, description, category, difficulty, estimated_duration_minutes, target_muscle_groups, equipment_needed, is_featured)
VALUES (
  'Beginner''s Full Body',
  'Perfect for getting started with strength training. Learn the basics and build a foundation.',
  'Strength',
  'Beginner',
  35,
  ARRAY['Full Body'],
  ARRAY['Dumbbells', 'Bodyweight'],
  true
);

-- Template 10: Athletic Performance
INSERT INTO workout_templates (name, description, category, difficulty, estimated_duration_minutes, target_muscle_groups, equipment_needed, is_featured)
VALUES (
  'Athletic Performance',
  'Power and explosiveness training for athletes. Improve speed, agility, and strength.',
  'Athletic',
  'Advanced',
  55,
  ARRAY['Full Body', 'Core', 'Legs'],
  ARRAY['Barbell', 'Plyometric Box', 'Medicine Ball'],
  false
);

-- =====================================================
-- NOTE: To add exercises to these templates, you'll need to:
-- 1. Get the exercise IDs from your exercises table
-- 2. Insert records into workout_template_exercises
-- 
-- Example:
-- INSERT INTO workout_template_exercises (template_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds, notes)
-- SELECT 
--   (SELECT id FROM workout_templates WHERE name = 'Push Day'),
--   (SELECT id FROM exercises WHERE name = 'Bench Press'),
--   0, 4, 8, 180, 'Focus on explosive power'
-- WHERE EXISTS (SELECT 1 FROM exercises WHERE name = 'Bench Press');
-- =====================================================

COMMIT;
