-- Check user_id data type first
-- Run this script in Supabase SQL Editor

-- Check what auth.uid() returns
SELECT 
    auth.uid() as current_user_id,
    pg_typeof(auth.uid()) as user_id_type;

-- Check user_id data type in egg_session
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'egg_session' AND column_name = 'user_id';

-- Check existing data in egg_session
SELECT 
    user_id, 
    pg_typeof(user_id) as actual_type,
    COUNT(*) as count
FROM egg_session 
GROUP BY user_id, pg_typeof(user_id)
LIMIT 5;

-- Check if there are any existing policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'egg_item'
ORDER BY policyname;
