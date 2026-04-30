-- ============================================
-- Basket Trends: transactions table + seed data
-- Run this in the Supabase SQL Editor
-- ============================================

-- 1. Create the transactions table
CREATE TABLE IF NOT EXISTS public.transactions (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    store_id uuid NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
    item_count integer NOT NULL DEFAULT 1,
    total_amount double precision NOT NULL DEFAULT 0,
    category text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT transactions_pkey PRIMARY KEY (id)
);

-- 2. Enable RLS
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- 3. Allow authenticated reads
CREATE POLICY "Allow authenticated read transactions"
    ON public.transactions FOR SELECT
    TO authenticated
    USING (true);

-- 4. Allow authenticated inserts (for POS / seed data)
CREATE POLICY "Allow authenticated insert transactions"
    ON public.transactions FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- ============================================
-- 5. Seed sample transaction data (last 8 weeks)
--    Replace the store UUIDs below with your actual store IDs.
--    You can get them by running:  SELECT id, name FROM stores;
-- ============================================

-- Helper: Insert sample transactions across last 8 weeks
-- This uses a DO block to generate realistic data.
DO $$
DECLARE
    v_store_ids uuid[];
    v_store uuid;
    v_categories text[] := ARRAY['Jewelry', 'Bags', 'Watches', 'Clothing', 'Accessories'];
    v_week integer;
    v_day integer;
    v_txn_count integer;
    v_items integer;
    v_amount double precision;
BEGIN
    -- Get all store IDs
    SELECT array_agg(id) INTO v_store_ids FROM public.stores;

    IF v_store_ids IS NULL THEN
        RAISE NOTICE 'No stores found. Please create stores first.';
        RETURN;
    END IF;

    FOREACH v_store IN ARRAY v_store_ids LOOP
        FOR v_week IN 0..7 LOOP
            -- Generate 3-8 transactions per day, 5 days a week
            FOR v_day IN 0..4 LOOP
                v_txn_count := 3 + floor(random() * 6)::int;
                FOR i IN 1..v_txn_count LOOP
                    v_items := 1 + floor(random() * 7)::int;  -- 1-7 items
                    v_amount := v_items * (500 + floor(random() * 4500)::int);  -- price per item 500-5000
                    INSERT INTO public.transactions (store_id, item_count, total_amount, category, created_at)
                    VALUES (
                        v_store,
                        v_items,
                        v_amount,
                        v_categories[1 + floor(random() * 5)::int],
                        now() - (v_week * 7 + v_day)::int * interval '1 day'
                              + (9 + floor(random() * 10))::int * interval '1 hour'
                    );
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;
