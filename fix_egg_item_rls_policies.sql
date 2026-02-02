-- Fix RLS policies for egg_item table
-- Run this script in Supabase SQL Editor

-- First, check current policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'egg_item'
ORDER BY policyname;

-- Check user_id data type in egg_session
SELECT 
    column_name, 
    data_type, 
    is_nullable 
FROM information_schema.columns 
WHERE table_name = 'egg_session' AND column_name = 'user_id';

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view own egg items" ON egg_item;
DROP POLICY IF EXISTS "Users can create own egg items" ON egg_item;
DROP POLICY IF EXISTS "Users can update own egg items" ON egg_item;
DROP POLICY IF EXISTS "Users can delete own egg items" ON egg_item;

-- Create new policies with proper user_id handling

-- Policy for viewing own egg items
CREATE POLICY "Users can view own egg items" ON egg_item
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM egg_session 
      WHERE egg_session.id = egg_item.session_id 
      AND egg_session.user_id = auth.uid()::text
    )
  );

-- Policy for creating own egg items (most important)
CREATE POLICY "Users can create own egg items" ON egg_item
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM egg_session 
      WHERE egg_session.id = session_id 
      AND egg_session.user_id = auth.uid()::text
    )
  );

-- Policy for updating own egg items
CREATE POLICY "Users can update own egg items" ON egg_item
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM egg_session 
      WHERE egg_session.id = egg_item.session_id 
      AND egg_session.user_id = auth.uid()::text
    )
  );

-- Policy for deleting own egg items
CREATE POLICY "Users can delete own egg items" ON egg_item
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM egg_session 
      WHERE egg_session.id = egg_item.session_id 
      AND egg_session.user_id = auth.uid()::text
    )
  );

-- Alternative: If user_id is UUID, use this instead
/*
CREATE POLICY "Users can create own egg items" ON egg_item
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM egg_session 
      WHERE egg_session.id = session_id 
      AND egg_session.user_id = auth.uid()
    )
  );
*/

-- Alternative: If user_id is INTEGER, use this instead
/*
CREATE POLICY "Users can create own egg items" ON egg_item
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM egg_session 
      WHERE egg_session.id = session_id 
      AND egg_session.user_id = (auth.uid()::text)::integer
    )
  );
*/

-- Grant permissions
GRANT SELECT ON egg_item TO authenticated;
GRANT INSERT ON egg_item TO authenticated;
GRANT UPDATE ON egg_item TO authenticated;
GRANT DELETE ON egg_item TO authenticated;

-- Test the policy by checking current user
SELECT 
    auth.uid() as current_user_id,
    pg_typeof(auth.uid()) as user_id_type;

-- Verify new policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'egg_item'
ORDER BY policyname;
