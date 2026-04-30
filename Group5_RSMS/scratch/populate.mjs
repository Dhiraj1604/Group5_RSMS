import { randomUUID } from 'crypto';

const URL = "https://bdgwzkpteyxhlgprlmye.supabase.co/rest/v1";
const KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkZ3d6a3B0ZXl4aGxncHJsbXllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxNTM5OTksImV4cCI6MjA5MTcyOTk5OX0.AU2fdMOK0WfjqQEFqLsMfGCWChf3rMzSdVOzQ_5QYOU";

const headers = {
    'apikey': KEY,
    'Authorization': `Bearer ${KEY}`,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
};

async function req(table, method, body = null) {
    const opts = { method, headers: { ...headers } };
    if (body) opts.body = JSON.stringify(body);
    const res = await fetch(`${URL}/${table}`, opts);
    if (!res.ok) {
        const text = await res.text();
        console.error(`Error on ${table}:`, text);
        return null;
    }
    return res.json();
}

function randomDate(start, end) {
    return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime())).toISOString();
}

async function run() {
    console.log("Fetching existing stores...");
    let stores = await req("stores?select=id", "GET");
    if (!stores || stores.length === 0) {
        console.log("Inserting stores...");
        stores = await req("stores", "POST", [
            { id: randomUUID(), name: "RSMS Flagship Mumbai", city: "Mumbai", country: "India", code: "BTQ-MUM-01", is_active: true },
            { id: randomUUID(), name: "RSMS Delhi Boutique", city: "New Delhi", country: "India", code: "BTQ-DEL-01", is_active: true },
            { id: randomUUID(), name: "RSMS Bangalore Store", city: "Bangalore", country: "India", code: "BTQ-BLR-01", is_active: true }
        ]);
    }

    console.log("Fetching existing products...");
    let products = await req("products?select=id,base_price,category", "GET");
    if (!products || products.length === 0) {
        console.log("Inserting products...");
        products = await req("products", "POST", [
            { id: randomUUID(), sku: "JWL-RNG-001", name: "Maharaja Diamond Ring", category: "jewellery", base_price: 485000, is_active: true },
            { id: randomUUID(), sku: "WTC-CHR-001", name: "Chronograph Prestige", category: "watches", base_price: 1250000, is_active: true },
            { id: randomUUID(), sku: "LTH-BAG-003", name: "Midnight Tote", category: "leather_goods", base_price: 95000, is_active: true },
            { id: randomUUID(), sku: "COU-GWN-007", name: "Evening Cascade Gown", category: "couture", base_price: 320000, is_active: true },
            { id: randomUUID(), sku: "ACC-SCF-001", name: "Silk Cashmere Scarf", category: "accessories", base_price: 45000, is_active: true },
            { id: randomUUID(), sku: "FRG-EDP-001", name: "Oud Noir Extrait", category: "fragrances", base_price: 25000, is_active: true },
            { id: randomUUID(), sku: "WTC-DVE-002", name: "Deep Sea Diver", category: "watches", base_price: 850000, is_active: true }
        ]);
    }

    if (!stores || !products) return console.log("Failed to fetch/create basic entities");

    console.log("Inserting Inventory...");
    let inventoryPayload = [];
    for (let s of stores) {
        for (let p of products) {
            inventoryPayload.push({
                store_id: s.id,
                product_id: p.id,
                stock_quantity: Math.floor(Math.random() * 50) + 2
            });
        }
    }
    await req("inventory", "POST", inventoryPayload);

    console.log("Generating Orders and Items...");
    const statuses = ["completed", "completed", "completed", "completed", "pending", "cancelled"];
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - (30 * 24 * 60 * 60 * 1000));
    const customerIds = [randomUUID(), randomUUID(), randomUUID(), randomUUID(), randomUUID()]; // Some new, some returning

    for (let s of stores) {
        for (let i = 0; i < 15; i++) {
            const orderId = randomUUID();
            const status = statuses[Math.floor(Math.random() * statuses.length)];
            const date = randomDate(thirtyDaysAgo, now);
            const customerId = customerIds[Math.floor(Math.random() * customerIds.length)];
            
            // Generate items
            let totalAmount = 0;
            let items = [];
            const itemCount = Math.floor(Math.random() * 3) + 1;
            for (let j = 0; j < itemCount; j++) {
                const p = products[Math.floor(Math.random() * products.length)];
                const quantity = Math.floor(Math.random() * 2) + 1;
                totalAmount += (p.base_price * quantity);
                items.push({
                    order_id: orderId,
                    product_id: p.id,
                    quantity: quantity,
                    unit_price: p.base_price
                });
            }

            await req("customer_orders", "POST", [{
                id: orderId,
                boutique_id: s.id,
                total_amount: totalAmount,
                status: status,
                created_at: date,
                customer_id: customerId
            }]);

            await req("customer_order_items", "POST", items);
        }
    }

    console.log("Inserting Audit Logs...");
    await req("audit_logs", "POST", [
        { action: "Product Created", event_type: "Products", user_name: "admin@rsms.com", entity: "Maharaja Diamond Ring" },
        { action: "Inventory Updated", event_type: "Inventory", user_name: "admin@rsms.com", entity: "Deep Sea Diver" },
        { action: "Store Activated", event_type: "Stores", user_name: "system", entity: "RSMS Delhi Boutique" }
    ]);

    console.log("Done populating DB!");
}

run();
