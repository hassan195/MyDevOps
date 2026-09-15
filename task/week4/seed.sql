-- seed.sql
-- create product_stock table if not exists
CREATE TABLE IF NOT EXISTS product_stock (
    id SERIAL PRIMARY KEY,
    sku INTEGER UNIQUE NOT NULL DEFAULT 0,
    product_name TEXT NOT NULL,
    qty INTEGER NOT NULL DEFAULT 0,
    warehouse TEXT NOT NULL DEFAULT 'main',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- insert test data (ON CONFLICT to avoid errors when running multiple times)
INSERT INTO product_stock (sku, product_name, qty, warehouse) VALUES
    (42, 'Wireless Mouse',       120, 'main'),
    (32, 'Mechanical Keyboard',   45, 'main'),
    (12, 'USB-C Hub',             80, 'main'),
    (19, '27-inch Monitor',       15, 'secondary'),
    (26, 'Webcam 1080p',          60, 'main'),
    (8, 'Laptop Stand',          33, 'secondary'),
    (15, 'Noise Cancelling Headphones', 22, 'main'),
    (81, 'External SSD 1TB',      50, 'main')
ON CONFLICT (sku) DO NOTHING;