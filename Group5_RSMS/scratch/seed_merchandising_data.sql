-- SQL Queries to set up data for Merchandising Insights

-- 1. Ensure products table has the necessary columns (already in schema, but for completeness)
-- ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_on_floor BOOLEAN DEFAULT FALSE;
-- ALTER TABLE public.products ADD COLUMN IF NOT EXISTS last_moved_to_floor TIMESTAMP WITH TIME ZONE;

-- 2. Populate some "Fallback" items (items on floor for > 30 days)
UPDATE public.products 
SET is_on_floor = true, 
    last_moved_to_floor = NOW() - INTERVAL '35 days'
WHERE id IN (
    SELECT id FROM public.products 
    WHERE is_active = true 
    LIMIT 5
);

-- 3. Populate some "Healthy" floor items (on floor for < 30 days)
UPDATE public.products 
SET is_on_floor = true, 
    last_moved_to_floor = NOW() - INTERVAL '5 days'
WHERE id IN (
    SELECT id FROM public.products 
    WHERE is_active = true 
    AND id NOT IN (SELECT id FROM public.products WHERE is_on_floor = true)
    LIMIT 10
);

-- 4. Seed sample sales data for "Total Sell" card and Graph
-- Create sample orders for the current store
DO $$
DECLARE
    v_store_id UUID;
    v_user_id UUID;
    v_order_id UUID;
    v_product_id UUID;
    v_base_price NUMERIC;
    v_order_date TIMESTAMP;
BEGIN
    -- Get first store and customer profile for testing
    SELECT id INTO v_store_id FROM public.stores LIMIT 1;
    SELECT id INTO v_user_id FROM public.customer_profiles LIMIT 1;

    -- Create 15 orders over the last 10 days
    FOR i IN 0..10 LOOP
        v_order_date := NOW() - (i || ' days')::INTERVAL - (RANDOM() * INTERVAL '10 hours');
        
        INSERT INTO public.customer_orders (
            user_id, order_number, status, subtotal, taxes, total_amount, store_id, created_at, updated_at
        ) VALUES (
            v_user_id, 'TEST-ORD-' || floor(random()*1000000), 'delivered', 0, 0, 0, v_store_id, v_order_date, v_order_date
        ) RETURNING id INTO v_order_id;

        -- Add 1-3 items to each order
        FOR j IN 1..floor(random()*3 + 1) LOOP
            SELECT id, base_price INTO v_product_id, v_base_price FROM public.products ORDER BY RANDOM() LIMIT 1;
            
            INSERT INTO public.customer_order_items (
                order_id, product_id, quantity, price_at_purchase, product_name, created_at
            ) VALUES (
                v_order_id, v_product_id, floor(random()*2 + 1), v_base_price, (SELECT name FROM public.products WHERE id = v_product_id), v_order_date
            );
            
            -- Update order total
            UPDATE public.customer_orders SET total_amount = total_amount + (v_base_price * floor(random()*2 + 1)) WHERE id = v_order_id;
        END LOOP;
    END LOOP;
END $$;
