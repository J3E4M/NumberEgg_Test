-- Supabase Migration: Update egg_session table to use grade0-5 instead of big/medium/small
-- Run this in Supabase SQL Editor

-- Step 1: Add new grade columns if they don't exist
ALTER TABLE egg_session 
ADD COLUMN IF NOT EXISTS grade0_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS grade1_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS grade2_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS grade3_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS grade4_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS grade5_count INTEGER NOT NULL DEFAULT 0;

-- Step 2: Migrate data from old columns to new columns (if old columns exist)
UPDATE egg_session SET 
  grade0_count = COALESCE(small_count, 0),  -- เบอร์ 5 = เล็กที่สุด
  grade1_count = CASE 
    WHEN small_count > 0 THEN small_count / 2 
    ELSE 0 
  END,
  grade2_count = COALESCE(medium_count, 0),  -- เบอร์ 2 = กลาง
  grade3_count = CASE 
    WHEN medium_count > 0 THEN medium_count / 2 
    ELSE 0 
  END,
  grade4_count = CASE 
    WHEN big_count > 0 THEN big_count / 2 
    ELSE 0 
  END,
  grade5_count = COALESCE(big_count, 0)      -- เบอร์ 0 = ใหญ่ที่สุด
WHERE EXISTS (
  SELECT 1 FROM information_schema.columns 
  WHERE table_name = 'egg_session' 
  AND column_name IN ('big_count', 'medium_count', 'small_count')
);

-- Step 3: Drop old columns (optional - only run after confirming migration works)
-- ALTER TABLE egg_session DROP COLUMN IF EXISTS big_count;
-- ALTER TABLE egg_session DROP COLUMN IF EXISTS medium_count;
-- ALTER TABLE egg_session DROP COLUMN IF EXISTS small_count;

-- Step 4: Verify the migration
SELECT 
  id, 
  user_id,
  grade0_count, grade1_count, grade2_count, grade3_count, grade4_count, grade5_count,
  (grade0_count + grade1_count + grade2_count + grade3_count + grade4_count + grade5_count) as total_eggs
FROM egg_session 
ORDER BY created_at DESC 
LIMIT 5;
