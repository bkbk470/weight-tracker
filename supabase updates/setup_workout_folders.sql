-- ==========================================
-- WORKOUT FOLDERS FEATURE - DATABASE SETUP
-- ==========================================
-- Run this SQL in your Supabase SQL Editor

-- 1. Create workout_folders table
CREATE TABLE IF NOT EXISTS workout_folders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  color TEXT, -- Color name for visual organization (e.g., 'blue', 'green', 'red')
  icon TEXT, -- Icon name for the folder (optional, currently defaults to 'folder')
  parent_folder_id UUID REFERENCES workout_folders(id) ON DELETE CASCADE, -- For nested folders (future feature)
  order_index INTEGER DEFAULT 0, -- For custom ordering
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Add folder_id column to workouts table
-- This allows workouts to be organized into folders
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS folder_id UUID REFERENCES workout_folders(id) ON DELETE SET NULL;

-- 3. Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_workout_folders_user_id ON workout_folders(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_folders_parent_folder_id ON workout_folders(parent_folder_id);
CREATE INDEX IF NOT EXISTS idx_workouts_folder_id ON workouts(folder_id);

-- 4. Enable Row Level Security (RLS) on workout_folders
ALTER TABLE workout_folders ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS Policies for workout_folders
-- Users can only see their own folders
CREATE POLICY "Users can view their own folders"
  ON workout_folders FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create their own folders
CREATE POLICY "Users can create their own folders"
  ON workout_folders FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own folders
CREATE POLICY "Users can update their own folders"
  ON workout_folders FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own folders
CREATE POLICY "Users can delete their own folders"
  ON workout_folders FOR DELETE
  USING (auth.uid() = user_id);

-- 6. Create a trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_workout_folders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER workout_folders_updated_at
  BEFORE UPDATE ON workout_folders
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_folders_updated_at();

-- 7. (Optional) Insert some sample folders for testing
-- Uncomment the lines below if you want to create sample folders
-- Replace 'YOUR_USER_ID_HERE' with your actual user ID from auth.users

/*
INSERT INTO workout_folders (user_id, name, description, color, icon) VALUES
  ('YOUR_USER_ID_HERE', 'Strength Training', 'All my strength and resistance workouts', 'blue', 'folder'),
  ('YOUR_USER_ID_HERE', 'Cardio', 'Running, cycling, and cardio exercises', 'green', 'folder'),
  ('YOUR_USER_ID_HERE', 'Flexibility', 'Yoga and stretching routines', 'purple', 'folder'),
  ('YOUR_USER_ID_HERE', 'HIIT', 'High intensity interval training workouts', 'red', 'folder'),
  ('YOUR_USER_ID_HERE', 'Recovery', 'Light workouts and recovery sessions', 'orange', 'folder');
*/

-- ==========================================
-- VERIFICATION QUERIES
-- ==========================================
-- Run these to verify the setup worked correctly

-- Check if table was created
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'workout_folders'
);

-- Check if folder_id column was added to workouts
SELECT EXISTS (
  SELECT FROM information_schema.columns 
  WHERE table_schema = 'public' 
  AND table_name = 'workouts' 
  AND column_name = 'folder_id'
);

-- Check if indexes were created
SELECT indexname FROM pg_indexes 
WHERE tablename IN ('workout_folders', 'workouts') 
AND schemaname = 'public'
ORDER BY tablename, indexname;

-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'workout_folders' 
AND schemaname = 'public';

-- Check policies
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'workout_folders'
ORDER BY policyname;

-- ==========================================
-- DONE!
-- ==========================================
-- Your workout folders feature is now set up and ready to use!
