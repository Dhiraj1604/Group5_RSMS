-- Fix: Storage RLS policies for product-images bucket
-- Run this in Supabase SQL Editor → https://supabase.com/dashboard/project/bdgwzkpteyxhlgprlmye/sql/new
--
-- The "new row violates row-level security policy" error means the storage bucket
-- has RLS enabled but no policy allows authenticated users to upload/read files.

-- 1. Allow authenticated users to upload files to the product-images bucket
CREATE POLICY "Authenticated users can upload product images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'product-images');

-- 2. Allow authenticated users to update/replace existing images
CREATE POLICY "Authenticated users can update product images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'product-images')
WITH CHECK (bucket_id = 'product-images');

-- 3. Allow anyone to view product images (public bucket)
CREATE POLICY "Anyone can view product images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'product-images');

-- 4. Allow authenticated users to delete product images
CREATE POLICY "Authenticated users can delete product images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'product-images');
