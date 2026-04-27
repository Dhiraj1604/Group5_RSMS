-- ============================================================
-- RSMS DATABASE MIGRATION & DATA SEED
-- Run this entire script in the Supabase SQL Editor
-- ============================================================

-- ────────────────────────────────────────────
-- PHASE 1: FIX EXISTING SCHEMA BUGS
-- ────────────────────────────────────────────

-- 1A. customer_orders already uses store_id (confirmed from schema inspection).
-- boutique_id does NOT exist on this table — no column changes needed.

-- 1B. user_id already exists on customer_orders with NOT NULL — no changes needed.
-- The app will read user_id as the customer identifier.

-- 1C. Standardize customer_order_items price column to price_at_purchase
ALTER TABLE public.customer_order_items
  ADD COLUMN IF NOT EXISTS price_at_purchase NUMERIC(15, 2);

-- Migrate unit_price -> price_at_purchase if needed
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='customer_order_items' AND column_name='unit_price') THEN
    UPDATE public.customer_order_items
      SET price_at_purchase = unit_price
      WHERE price_at_purchase IS NULL AND unit_price IS NOT NULL;
  END IF;
END $$;

-- ────────────────────────────────────────────
-- PHASE 2: ADD MISSING COLUMNS TO EXISTING TABLES
-- ────────────────────────────────────────────

-- 2A. Inventory health benchmarks
ALTER TABLE public.inventory
  ADD COLUMN IF NOT EXISTS min_stock_level INTEGER DEFAULT 5,
  ADD COLUMN IF NOT EXISTS max_stock_level INTEGER DEFAULT 50;

-- Set sensible defaults based on category (if products table is joinable)
UPDATE public.inventory i
  SET min_stock_level = 3, max_stock_level = 20
  FROM public.products p
  WHERE i.product_id = p.id
    AND LOWER(p.category) IN ('watches', 'jewellery');

UPDATE public.inventory i
  SET min_stock_level = 5, max_stock_level = 40
  FROM public.products p
  WHERE i.product_id = p.id
    AND LOWER(p.category) IN ('leather_goods', 'couture', 'accessories', 'fragrances');

-- ────────────────────────────────────────────
-- PHASE 3: CREATE NEW TABLES
-- ────────────────────────────────────────────

-- 3A. Expenses table (Safe Migration)
DO $$
BEGIN
  -- If table exists but uses old column name, rename it safely
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='expenses' AND column_name='boutique_id') THEN
    ALTER TABLE public.expenses RENAME COLUMN boutique_id TO store_id;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.expenses (
  id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id    UUID          REFERENCES public.stores(id) ON DELETE CASCADE,
  category    TEXT          NOT NULL CHECK (category IN ('Salary','Rent','Utilities','Marketing','Logistics','Other')),
  amount      NUMERIC(15,2) NOT NULL DEFAULT 0,
  expense_date DATE         NOT NULL DEFAULT CURRENT_DATE,
  description TEXT,
  created_at  TIMESTAMPTZ   DEFAULT NOW()
);

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can manage expenses"
  ON public.expenses FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 3B. Store traffic table (Safe Migration)
DO $$
BEGIN
  -- If table exists but uses old column name, rename it safely
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='store_traffic' AND column_name='boutique_id') THEN
    ALTER TABLE public.store_traffic RENAME COLUMN boutique_id TO store_id;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.store_traffic (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id      UUID    REFERENCES public.stores(id) ON DELETE CASCADE,
  visitor_count INTEGER NOT NULL DEFAULT 0,
  record_date   DATE    NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE(store_id, record_date)
);

ALTER TABLE public.store_traffic ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can manage store_traffic"
  ON public.store_traffic FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ────────────────────────────────────────────
-- PHASE 4: SEED SAMPLE DATA FOR ALL 5 STORES
-- ────────────────────────────────────────────

DO $$
DECLARE
  -- Store IDs (existing Dior stores from your DB)
  store_tokyo     UUID := '050223c8-cac9-4d91-bbc3-a6acfae864a8';
  store_london    UUID := 'dc51fa48-ad77-4bc1-9bc8-6c435fdf70dc';
  store_paris     UUID := 'f1977a19-a88c-4066-8a42-9a0830752de6';
  store_mumbai    UUID := 'f6cd3d5c-629d-463d-9274-16388fc8ca11';
  store_newyork   UUID := '8232958a-d93e-44d5-bfc4-68b7604f773e';

  -- Product IDs (will be fetched dynamically below)
  prod_ids        UUID[];
  prod_prices     NUMERIC[];
  prod_categories TEXT[];

  -- Temp variables
  i               INT;
  j               INT;
  v_order_id      UUID;

  store_ids       UUID[] := ARRAY[store_tokyo, store_london, store_paris, store_mumbai, store_newyork];
  statuses        TEXT[] := ARRAY['delivered','delivered','delivered','shipped','shipped','placed'];
  customer_ids    UUID[] := ARRAY[
    gen_random_uuid(), gen_random_uuid(), gen_random_uuid(),
    gen_random_uuid(), gen_random_uuid(), gen_random_uuid(),
    gen_random_uuid(), gen_random_uuid()
  ];
  item_count      INT;
  p_idx           INT;
  quantity        INT;
  line_total      NUMERIC;
  order_total     NUMERIC;

BEGIN

-- ── 4A. Seed Products (only if table is empty) ──
IF (SELECT COUNT(*) FROM public.products) = 0 THEN
  INSERT INTO public.products (id, sku, name, description, base_price, category, is_active)
  VALUES
    (gen_random_uuid(), 'DIO-JWL-001', 'Rose des Vents Diamond Ring',   'White gold, 1.2ct diamond',     485000, 'jewellery',    true),
    (gen_random_uuid(), 'DIO-JWL-002', 'Victoire de Dior Bracelet',     '18k gold, pavé diamonds',        320000, 'jewellery',    true),
    (gen_random_uuid(), 'DIO-WTC-001', 'Dior Invictus Chronograph',     'Titanium, sapphire crystal',    1250000, 'watches',      true),
    (gen_random_uuid(), 'DIO-WTC-002', 'La D de Dior Watch',            '18k rose gold, diamonds',        890000, 'watches',      true),
    (gen_random_uuid(), 'DIO-LTH-001', 'Lady Dior Bag',                 'Cannage lambskin, medium',        295000, 'leather_goods',true),
    (gen_random_uuid(), 'DIO-LTH-002', 'Book Tote',                     'Embroidered canvas, large',        95000, 'leather_goods',true),
    (gen_random_uuid(), 'DIO-COU-001', 'New Look Couture Gown',         'Silk taffeta, bespoke',           580000, 'couture',      true),
    (gen_random_uuid(), 'DIO-ACC-001', 'Dior Oblique Scarf',            'Silk twill, 90x90cm',              45000, 'accessories',  true),
    (gen_random_uuid(), 'DIO-ACC-002', 'CD Logo Belt',                  'Calfskin, gold buckle',            32000, 'accessories',  true),
    (gen_random_uuid(), 'DIO-FRG-001', 'J''adore Parfum d''Eau',        '100ml, refillable',                18500, 'fragrances',   true),
    (gen_random_uuid(), 'DIO-FRG-002', 'Sauvage Elixir',                '60ml parfum',                      16500, 'fragrances',   true);
END IF;

-- Load product data into arrays
SELECT ARRAY_AGG(id ORDER BY created_at),
       ARRAY_AGG(base_price ORDER BY created_at),
       ARRAY_AGG(category ORDER BY created_at)
INTO prod_ids, prod_prices, prod_categories
FROM public.products
WHERE is_active = true
LIMIT 11;

-- ── 4A.5 Seed Customer Profiles (Required for Foreign Key) ──
FOR i IN 1..array_length(customer_ids, 1) LOOP
  BEGIN
    -- Try with common columns
    EXECUTE 'INSERT INTO public.customer_profiles (id, full_name, email) VALUES ($1, $2, $3) ON CONFLICT (id) DO NOTHING'
    USING customer_ids[i], 'Customer ' || i, 'customer' || i || '@example.com';
  EXCEPTION WHEN OTHERS THEN
    -- Fallback to just ID if columns differ
    EXECUTE 'INSERT INTO public.customer_profiles (id) VALUES ($1) ON CONFLICT (id) DO NOTHING'
    USING customer_ids[i];
  END;
END LOOP;

-- ── 4B. Seed Inventory for all stores ──
FOR i IN 1..array_length(store_ids, 1) LOOP
  FOR j IN 1..array_length(prod_ids, 1) LOOP
    INSERT INTO public.inventory (store_id, product_id, stock_quantity, min_stock_level, max_stock_level)
    VALUES (
      store_ids[i],
      prod_ids[j],
      floor(random() * 45 + 3)::INT,
      CASE WHEN prod_categories[j] IN ('watches','jewellery') THEN 2 ELSE 5 END,
      CASE WHEN prod_categories[j] IN ('watches','jewellery') THEN 15 ELSE 40 END
    )
    ON CONFLICT DO NOTHING;
  END LOOP;
END LOOP;

-- ── 4C. Seed Employees for all stores ──
FOR i IN 1..array_length(store_ids, 1) LOOP
  INSERT INTO public.employees (id, boutique_id, name, email, role, salary, is_active, joining_date)
  VALUES
    (gen_random_uuid(), store_ids[i], 'Store Manager '     || i, 'manager'  || i || '@dior.com', 'Manager',             180000, true, NOW() - INTERVAL '2 years'),
    (gen_random_uuid(), store_ids[i], 'Senior Associate '  || i, 'senior'   || i || '@dior.com', 'Senior Sales',        120000, true, NOW() - INTERVAL '18 months'),
    (gen_random_uuid(), store_ids[i], 'Sales Associate 1.' || i, 'sales1'   || i || '@dior.com', 'Sales Associate',      85000, true, NOW() - INTERVAL '1 year'),
    (gen_random_uuid(), store_ids[i], 'Sales Associate 2.' || i, 'sales2'   || i || '@dior.com', 'Sales Associate',      85000, true, NOW() - INTERVAL '8 months'),
    (gen_random_uuid(), store_ids[i], 'Visual Merchandiser '|| i,'visual'   || i || '@dior.com', 'Visual Merchandising', 95000, true, NOW() - INTERVAL '6 months'),
    (gen_random_uuid(), store_ids[i], 'Inventory Specialist '||i,'inventory'|| i || '@dior.com', 'Inventory',            78000, true, NOW() - INTERVAL '4 months')
  ON CONFLICT DO NOTHING;
END LOOP;

-- ── 4D. Seed 60 days of Orders (12 per store per month) ──
FOR i IN 1..array_length(store_ids, 1) LOOP
  FOR j IN 1..60 LOOP
    v_order_id    := gen_random_uuid();
    order_total := 0;
    item_count  := floor(random() * 3 + 1)::INT;

    INSERT INTO public.customer_orders (
      id, store_id, user_id, order_number,
      status, subtotal, taxes, delivery_fee, total_amount,
      created_at, updated_at
    ) VALUES (
      v_order_id,
      store_ids[i],
      customer_ids[floor(random() * 8 + 1)::INT],
      'ORD-' || LPAD(floor(random() * 999999 + 1)::TEXT, 6, '0'),
      statuses[floor(random() * 6 + 1)::INT],
      0,
      0,
      0,
      0,
      NOW() - (floor(random() * 60) || ' days')::INTERVAL,
      NOW() - (floor(random() * 60) || ' days')::INTERVAL
    );

    FOR k IN 1..item_count LOOP
      p_idx    := floor(random() * array_length(prod_ids, 1) + 1)::INT;
      quantity := floor(random() * 2 + 1)::INT;
      line_total := prod_prices[p_idx] * quantity;
      order_total := order_total + line_total;

      INSERT INTO public.customer_order_items (order_id, product_id, quantity, price_at_purchase)
      VALUES (v_order_id, prod_ids[p_idx], quantity, prod_prices[p_idx]);
    END LOOP;

    UPDATE public.customer_orders SET total_amount = order_total WHERE id = v_order_id;
  END LOOP;
END LOOP;

-- ── 4E. Seed Expenses (3 months of operational costs per store) ──
FOR i IN 1..array_length(store_ids, 1) LOOP
  -- Monthly fixed costs
  INSERT INTO public.expenses (store_id, category, amount, expense_date, description)
  VALUES
    -- Month 1
    (store_ids[i], 'Rent',       floor(random()*300000+500000)::NUMERIC, CURRENT_DATE - 60, 'Monthly rent'),
    (store_ids[i], 'Salary',     floor(random()*100000+643000)::NUMERIC, CURRENT_DATE - 60, 'Staff payroll'),
    (store_ids[i], 'Utilities',  floor(random()*20000+30000)::NUMERIC,   CURRENT_DATE - 60, 'Electricity & water'),
    (store_ids[i], 'Marketing',  floor(random()*50000+80000)::NUMERIC,   CURRENT_DATE - 55, 'Digital & print ads'),
    -- Month 2
    (store_ids[i], 'Rent',       floor(random()*300000+500000)::NUMERIC, CURRENT_DATE - 30, 'Monthly rent'),
    (store_ids[i], 'Salary',     floor(random()*100000+643000)::NUMERIC, CURRENT_DATE - 30, 'Staff payroll'),
    (store_ids[i], 'Utilities',  floor(random()*20000+30000)::NUMERIC,   CURRENT_DATE - 30, 'Electricity & water'),
    (store_ids[i], 'Marketing',  floor(random()*50000+80000)::NUMERIC,   CURRENT_DATE - 25, 'Digital & print ads'),
    -- Month 3 (current)
    (store_ids[i], 'Rent',       floor(random()*300000+500000)::NUMERIC, CURRENT_DATE,      'Monthly rent'),
    (store_ids[i], 'Salary',     floor(random()*100000+643000)::NUMERIC, CURRENT_DATE,      'Staff payroll'),
    (store_ids[i], 'Utilities',  floor(random()*20000+30000)::NUMERIC,   CURRENT_DATE,      'Electricity & water'),
    (store_ids[i], 'Logistics',  floor(random()*30000+20000)::NUMERIC,   CURRENT_DATE - 5,  'Inter-store transfers')
  ON CONFLICT DO NOTHING;
END LOOP;

-- ── 4F. Seed Store Traffic (60 days of footfall) ──
FOR i IN 1..array_length(store_ids, 1) LOOP
  FOR j IN 0..59 LOOP
    INSERT INTO public.store_traffic (store_id, visitor_count, record_date)
    VALUES (
      store_ids[i],
      floor(random() * 80 + 20)::INT,
      CURRENT_DATE - j
    )
    ON CONFLICT (store_id, record_date) DO NOTHING;
  END LOOP;
END LOOP;

-- ── 4G. Seed Audit Logs ──
INSERT INTO public.audit_logs (action, event_type, user_name, entity, created_at)
VALUES
  ('Product Created',      'Products',  'admin@dior.com',   'Lady Dior Bag',              NOW() - INTERVAL '5 days'),
  ('Inventory Updated',    'Inventory', 'tokyo@dior.com',   'Dior Invictus Chronograph',  NOW() - INTERVAL '4 days'),
  ('Store Activated',      'Stores',    'system',           'Dior New York',              NOW() - INTERVAL '3 days'),
  ('Price Adjusted',       'Products',  'admin@dior.com',   'Rose des Vents Ring',        NOW() - INTERVAL '2 days'),
  ('Transfer Approved',    'Inventory', 'paris@dior.com',   'Book Tote',                  NOW() - INTERVAL '1 day'),
  ('New Employee Added',   'Staff',     'london@dior.com',  'Sales Associate',            NOW() - INTERVAL '12 hours'),
  ('Order Shipped',        'Orders',    'system',           'ORD-884721',                 NOW() - INTERVAL '6 hours')
ON CONFLICT DO NOTHING;

END $$;
