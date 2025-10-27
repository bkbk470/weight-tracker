-- Seed Default Exercises for Weight Tracker
-- Run this in your Supabase SQL Editor to populate the exercises table with common exercises
--
-- Instructions:
-- 1. Go to https://supabase.com/dashboard/project/YOUR_PROJECT/sql
-- 2. Paste and run this entire SQL file
-- 3. Restart your Flutter app to load the new exercises

-- First, ensure the exercises table exists with the correct schema
-- (If you already have the table, this will just skip)
CREATE TABLE IF NOT EXISTS exercises (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  difficulty TEXT NOT NULL,
  equipment TEXT NOT NULL,
  notes TEXT,
  image_url TEXT,
  is_custom BOOLEAN DEFAULT false,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_exercises_user_id ON exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_exercises_category ON exercises(category);
CREATE INDEX IF NOT EXISTS idx_exercises_is_default ON exercises(is_default);

-- Enable Row Level Security
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;

-- Create policies (users can see default exercises + their own custom exercises)
DROP POLICY IF EXISTS "Users can view default exercises" ON exercises;
CREATE POLICY "Users can view default exercises" ON exercises
  FOR SELECT
  USING (is_default = true OR auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their own exercises" ON exercises;
CREATE POLICY "Users can create their own exercises" ON exercises
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own exercises" ON exercises;
CREATE POLICY "Users can update their own exercises" ON exercises
  FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own exercises" ON exercises;
CREATE POLICY "Users can delete their own exercises" ON exercises
  FOR DELETE
  USING (auth.uid() = user_id);

-- Clear any existing default exercises (in case you're re-running this)
DELETE FROM exercises WHERE is_default = true;

-- ==================== CHEST EXERCISES ====================
INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, notes, image_url) VALUES
('Barbell Bench Press', 'Chest', 'Intermediate', 'Barbell', true, false, 'Classic chest builder. Keep your feet flat on the floor and maintain a slight arch in your lower back.', 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400'),
('Dumbbell Bench Press', 'Chest', 'Beginner', 'Dumbbells', true, false, 'Allows for greater range of motion than barbell. Keep dumbbells aligned with your chest.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('Incline Barbell Bench Press', 'Chest', 'Intermediate', 'Barbell', true, false, 'Targets upper chest. Set bench to 30-45 degree angle.', 'https://images.unsplash.com/photo-1571019613914-85f342df0f0e?w=400'),
('Incline Dumbbell Press', 'Chest', 'Intermediate', 'Dumbbells', true, false, 'Great for upper chest development. Use 30-45 degree incline.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Decline Bench Press', 'Chest', 'Intermediate', 'Barbell', true, false, 'Emphasizes lower chest. Secure your legs properly.', 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400'),
('Dumbbell Flyes', 'Chest', 'Beginner', 'Dumbbells', true, false, 'Great for chest stretch and contraction. Keep a slight bend in elbows.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Incline Dumbbell Flyes', 'Chest', 'Intermediate', 'Dumbbells', true, false, 'Targets upper chest with stretch. Maintain controlled movement.', 'https://images.unsplash.com/photo-1571019613914-85f342df0f0e?w=400'),
('Cable Crossover', 'Chest', 'Intermediate', 'Cable Machine', true, false, 'Constant tension on chest. Adjust cable height for different angles.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
('Push-ups', 'Chest', 'Beginner', 'Body Weight', true, false, 'Classic bodyweight exercise. Keep core tight and body in straight line.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Chest Dips', 'Chest', 'Advanced', 'Dip Bar', true, false, 'Lean forward to target chest. Keep elbows slightly flared.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
('Machine Chest Press', 'Chest', 'Beginner', 'Machine', true, false, 'Beginner-friendly. Adjust seat so handles align with mid-chest.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('Pec Deck Machine', 'Chest', 'Beginner', 'Machine', true, false, 'Isolation exercise. Focus on squeezing chest at peak contraction.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400');

-- ==================== BACK EXERCISES ====================
INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, notes, image_url) VALUES
('Deadlift', 'Back', 'Advanced', 'Barbell', true, false, 'King of back exercises. Keep back straight and lift with your legs.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
('Barbell Row', 'Back', 'Intermediate', 'Barbell', true, false, 'Great for thickness. Pull to lower chest/upper abs.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('Dumbbell Row', 'Back', 'Beginner', 'Dumbbells', true, false, 'Unilateral back builder. Support yourself on bench.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Pull-ups', 'Back', 'Advanced', 'Pull-up Bar', true, false, 'Excellent for back width. Use various grips for different emphasis.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Lat Pulldown', 'Back', 'Beginner', 'Cable Machine', true, false, 'Great alternative to pull-ups. Pull to upper chest.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
('Seated Cable Row', 'Back', 'Beginner', 'Cable Machine', true, false, 'Targets mid-back. Keep torso stable and squeeze shoulder blades.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('T-Bar Row', 'Back', 'Intermediate', 'T-Bar Machine', true, false, 'Excellent for back thickness. Keep chest up.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Face Pulls', 'Back', 'Beginner', 'Cable Machine', true, false, 'Great for rear delts and upper back. Pull to face level.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Chin-ups', 'Back', 'Intermediate', 'Pull-up Bar', true, false, 'Underhand grip variation. Excellent for biceps and lats.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
('Single Arm Dumbbell Row', 'Back', 'Beginner', 'Dumbbells', true, false, 'Allows for greater range of motion. Focus on one side at a time.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('Inverted Row', 'Back', 'Beginner', 'Body Weight', true, false, 'Bodyweight row. Adjust height for difficulty.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Hyperextensions', 'Back', 'Beginner', 'Hyperextension Bench', true, false, 'Strengthens lower back. Keep movement controlled.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400');

-- ==================== LEGS EXERCISES ====================
INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, notes, image_url) VALUES
('Barbell Squat', 'Legs', 'Intermediate', 'Barbell', true, false, 'King of leg exercises. Keep chest up and knees tracking over toes.', 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400'),
('Front Squat', 'Legs', 'Advanced', 'Barbell', true, false, 'Emphasizes quads. Keep elbows high and chest up.', 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400'),
('Romanian Deadlift', 'Legs', 'Intermediate', 'Barbell', true, false, 'Great for hamstrings and glutes. Keep slight knee bend.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
('Leg Press', 'Legs', 'Beginner', 'Machine', true, false, 'Safe alternative to squats. Don''t lock out knees at top.', 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400'),
('Leg Curl', 'Legs', 'Beginner', 'Machine', true, false, 'Isolates hamstrings. Keep hips down on bench.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('Leg Extension', 'Legs', 'Beginner', 'Machine', true, false, 'Isolates quadriceps. Don''t hyperextend knees.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Walking Lunges', 'Legs', 'Beginner', 'Dumbbells', true, false, 'Great for quads and glutes. Keep torso upright.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Bulgarian Split Squat', 'Legs', 'Intermediate', 'Dumbbells', true, false, 'Unilateral leg exercise. Rear foot elevated.', 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400'),
('Calf Raises', 'Legs', 'Beginner', 'Machine', true, false, 'Targets calves. Full range of motion for best results.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('Goblet Squat', 'Legs', 'Beginner', 'Dumbbell', true, false, 'Great for learning squat form. Hold dumbbell at chest.', 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400'),
('Hack Squat', 'Legs', 'Intermediate', 'Machine', true, false, 'Machine squat variation. Targets quads.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Step-ups', 'Legs', 'Beginner', 'Dumbbells', true, false, 'Functional leg exercise. Use box or bench.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400');

-- ==================== SHOULDERS EXERCISES ====================
INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, notes, image_url) VALUES
('Overhead Press', 'Shoulders', 'Intermediate', 'Barbell', true, false, 'Main shoulder builder. Press straight up overhead.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('Dumbbell Shoulder Press', 'Shoulders', 'Beginner', 'Dumbbells', true, false, 'Allows natural movement pattern. Can be done seated or standing.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Arnold Press', 'Shoulders', 'Intermediate', 'Dumbbells', true, false, 'Rotation adds extra shoulder activation. Named after Arnold Schwarzenegger.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('Lateral Raises', 'Shoulders', 'Beginner', 'Dumbbells', true, false, 'Isolates side delts. Keep slight bend in elbows.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Front Raises', 'Shoulders', 'Beginner', 'Dumbbells', true, false, 'Targets front delts. Alternate arms or both together.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('Rear Delt Flyes', 'Shoulders', 'Beginner', 'Dumbbells', true, false, 'Essential for rear deltoids. Bend forward at hips.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Cable Lateral Raise', 'Shoulders', 'Beginner', 'Cable Machine', true, false, 'Constant tension on delts. Cross cable behind body.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
('Machine Shoulder Press', 'Shoulders', 'Beginner', 'Machine', true, false, 'Beginner-friendly pressing motion. Good for building strength.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('Upright Row', 'Shoulders', 'Intermediate', 'Barbell', true, false, 'Works shoulders and traps. Pull elbows high.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Shrugs', 'Shoulders', 'Beginner', 'Dumbbells', true, false, 'Builds trap muscles. Just shrug shoulders up.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('Pike Push-ups', 'Shoulders', 'Intermediate', 'Body Weight', true, false, 'Bodyweight shoulder exercise. Hips up high.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Face Pulls', 'Shoulders', 'Beginner', 'Cable Machine', true, false, 'Great for rear delts and shoulder health.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400');

-- ==================== ARMS EXERCISES ====================
INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, notes, image_url) VALUES
('Barbell Curl', 'Arms', 'Beginner', 'Barbell', true, false, 'Classic bicep builder. Keep elbows stable.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('Dumbbell Curl', 'Arms', 'Beginner', 'Dumbbells', true, false, 'Allows natural wrist rotation. Can be done alternating or together.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Hammer Curl', 'Arms', 'Beginner', 'Dumbbells', true, false, 'Targets brachialis. Keep palms facing each other.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Concentration Curl', 'Arms', 'Beginner', 'Dumbbell', true, false, 'Isolates biceps. Rest elbow on inner thigh.', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
('Preacher Curl', 'Arms', 'Intermediate', 'Barbell', true, false, 'Prevents cheating. Use preacher bench.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Cable Curl', 'Arms', 'Beginner', 'Cable Machine', true, false, 'Constant tension on biceps. Various attachments possible.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
('Tricep Dips', 'Arms', 'Intermediate', 'Dip Bar', true, false, 'Excellent tricep builder. Keep torso upright.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
('Close-Grip Bench Press', 'Arms', 'Intermediate', 'Barbell', true, false, 'Mass builder for triceps. Hands shoulder-width apart.', 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400'),
('Tricep Pushdown', 'Arms', 'Beginner', 'Cable Machine', true, false, 'Isolates triceps. Keep elbows at sides.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
('Overhead Tricep Extension', 'Arms', 'Beginner', 'Dumbbell', true, false, 'Stretches long head of tricep. Keep elbows close to head.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Skull Crushers', 'Arms', 'Intermediate', 'Barbell', true, false, 'Lying tricep extension. Lower to forehead or behind head.', 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400'),
('Diamond Push-ups', 'Arms', 'Intermediate', 'Body Weight', true, false, 'Bodyweight tricep exercise. Hands form diamond shape.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400');

-- ==================== CORE EXERCISES ====================
INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, notes, image_url) VALUES
('Plank', 'Core', 'Beginner', 'Body Weight', true, false, 'Core stability exercise. Keep body straight.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Crunches', 'Core', 'Beginner', 'Body Weight', true, false, 'Basic ab exercise. Focus on contracting abs.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Bicycle Crunches', 'Core', 'Beginner', 'Body Weight', true, false, 'Works abs and obliques. Bring opposite elbow to knee.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Russian Twists', 'Core', 'Intermediate', 'Dumbbell', true, false, 'Targets obliques. Rotate torso side to side.', 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400'),
('Hanging Leg Raises', 'Core', 'Advanced', 'Pull-up Bar', true, false, 'Advanced ab exercise. Raise legs to horizontal.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Ab Wheel Rollout', 'Core', 'Advanced', 'Ab Wheel', true, false, 'Very effective ab exercise. Start from knees if needed.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Mountain Climbers', 'Core', 'Beginner', 'Body Weight', true, false, 'Dynamic core exercise. Alternate bringing knees to chest.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Side Plank', 'Core', 'Intermediate', 'Body Weight', true, false, 'Targets obliques. Keep body in straight line.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Dead Bug', 'Core', 'Beginner', 'Body Weight', true, false, 'Great for core stability. Alternate opposite arm and leg.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Cable Woodchoppers', 'Core', 'Intermediate', 'Cable Machine', true, false, 'Rotational core exercise. Move diagonally across body.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
('Leg Raises', 'Core', 'Intermediate', 'Body Weight', true, false, 'Lower ab focus. Raise legs while lying on back.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Cable Crunches', 'Core', 'Beginner', 'Cable Machine', true, false, 'Weighted ab exercise. Kneel and crunch down.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400');

-- ==================== CARDIO EXERCISES ====================
INSERT INTO exercises (name, category, difficulty, equipment, is_default, is_custom, notes, image_url) VALUES
('Treadmill Running', 'Cardio', 'Beginner', 'Treadmill', true, false, 'Classic cardio. Adjust speed and incline for intensity.', 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400'),
('Stationary Bike', 'Cardio', 'Beginner', 'Bike', true, false, 'Low-impact cardio. Great for recovery days.', 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400'),
('Rowing Machine', 'Cardio', 'Intermediate', 'Rowing Machine', true, false, 'Full-body cardio. Focus on form: legs, core, then arms.', 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400'),
('Elliptical', 'Cardio', 'Beginner', 'Elliptical', true, false, 'Low-impact cardio machine. Easy on joints.', 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400'),
('Jump Rope', 'Cardio', 'Intermediate', 'Jump Rope', true, false, 'High-intensity cardio. Great for conditioning.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Burpees', 'Cardio', 'Advanced', 'Body Weight', true, false, 'Full-body cardio exercise. High intensity.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Box Jumps', 'Cardio', 'Intermediate', 'Plyo Box', true, false, 'Explosive power exercise. Land softly on box.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Battle Ropes', 'Cardio', 'Intermediate', 'Battle Ropes', true, false, 'Upper body cardio. Create waves with ropes.', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'),
('Stair Climber', 'Cardio', 'Intermediate', 'Stair Climber', true, false, 'Tough leg cardio. Builds endurance and leg strength.', 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400'),
('High Knees', 'Cardio', 'Beginner', 'Body Weight', true, false, 'Running in place with high knee drive.', 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400'),
('Swimming', 'Cardio', 'Intermediate', 'Pool', true, false, 'Full-body low-impact cardio. Various strokes available.', 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400'),
('Assault Bike', 'Cardio', 'Advanced', 'Assault Bike', true, false, 'Intense full-body cardio. Arms and legs together.', 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400');

-- Verify the exercises were inserted
SELECT category, COUNT(*) as exercise_count
FROM exercises
WHERE is_default = true
GROUP BY category
ORDER BY category;

-- Total count
SELECT COUNT(*) as total_default_exercises
FROM exercises
WHERE is_default = true;

-- Display a sample of the exercises
SELECT name, category, difficulty, equipment
FROM exercises
WHERE is_default = true
ORDER BY category, name
LIMIT 20;
