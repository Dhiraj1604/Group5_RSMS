-- Fix: price_history.product_id should reference products(id)
-- Run this in Supabase SQL Editor → https://supabase.com/dashboard/project/bdgwzkpteyxhlgprlmye/sql/new

-- Step 1: Drop the broken foreign key
ALTER TABLE public.price_history
  DROP CONSTRAINT price_history_product_id_fkey;

-- Step 2: Re-create it pointing to the correct products table
ALTER TABLE public.price_history
  ADD CONSTRAINT price_history_product_id_fkey
  FOREIGN KEY (product_id) REFERENCES public.products(id);
