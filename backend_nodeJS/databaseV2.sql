-- ------------------------------------------------------------------
-- Retail Receipts Demo Schema & Sample Data (MySQL 8.0+)
-- - Snake_case column names
-- - Realistic Thai sample data (UTF-8)
-- - Deterministic values (no randomness)
-- - FK with ON DELETE / ON UPDATE rules
-- - Basic CHECK constraints
-- - Validation queries at the end
-- ------------------------------------------------------------------

-- Encoding & timezone (server/session)
SET NAMES utf8mb4;
SET time_zone = '+07:00';

-- Use a single transaction for the whole script
START TRANSACTION;

-- ------------------------------------------------------------------
-- Drop existing objects safely (FK order)
-- ------------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS receipt_items;
DROP TABLE IF EXISTS receipts;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS stores;   -- (แก้ชื่อสะกดจาก stroes -> stores)
DROP TABLE IF EXISTS users;    -- (แก้ชื่อคอลัมน์เป็น created_at/updated_at)
DROP TABLE IF EXISTS roles;
SET FOREIGN_KEY_CHECKS = 1;

-- ------------------------------------------------------------------
-- DDL: Tables
-- ------------------------------------------------------------------

-- Roles
CREATE TABLE roles (
  role_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  role_name    VARCHAR(50) NOT NULL,
  PRIMARY KEY (role_id),
  UNIQUE KEY ux_roles_role_name (role_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Users
CREATE TABLE users (
  user_id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  email          VARCHAR(255) NOT NULL,
  username       VARCHAR(100) NOT NULL,
  password_hash  TEXT NOT NULL,
  full_name      VARCHAR(150) NOT NULL,
  role_id        INT UNSIGNED NOT NULL,
  profile_image  TEXT,
  created_at     DATETIME NOT NULL,
  updated_at     DATETIME NOT NULL,
  PRIMARY KEY (user_id),
  UNIQUE KEY ux_users_email (email),
  KEY fk_users_role_id (role_id),
  CONSTRAINT fk_users_role_id
    FOREIGN KEY (role_id)
    REFERENCES roles (role_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Stores  (สะกดเป็น stores)
CREATE TABLE stores (
  store_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  store_name  VARCHAR(100) NOT NULL,
  address     TEXT NOT NULL,
  phone       VARCHAR(20) NOT NULL,
  PRIMARY KEY (store_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Categories
CREATE TABLE categories (
  category_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  category_name  VARCHAR(100) NOT NULL,
  PRIMARY KEY (category_id),
  UNIQUE KEY ux_categories_category_name (category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Receipts
CREATE TABLE receipts (
  receipt_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       INT UNSIGNED NOT NULL,
  store_id      INT UNSIGNED NOT NULL,
  receipt_date  DATE NOT NULL,
  total_amount  DECIMAL(12,2) NOT NULL,
  created_at    DATETIME NOT NULL,
  PRIMARY KEY (receipt_id),
  KEY idx_receipts_receipt_date (receipt_date),
  KEY idx_receipts_user_store (user_id, store_id),
  KEY fk_receipts_user_id (user_id),
  KEY fk_receipts_store_id (store_id),
  CONSTRAINT chk_receipts_total_nonneg CHECK (total_amount >= 0.00),
  CONSTRAINT chk_receipts_created_not_before_date CHECK (created_at >= CONCAT(receipt_date, ' 00:00:00')),
  CONSTRAINT fk_receipts_user_id
    FOREIGN KEY (user_id) REFERENCES users (user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_receipts_store_id
    FOREIGN KEY (store_id) REFERENCES stores (store_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Receipt Items
CREATE TABLE receipt_items (
  item_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  receipt_id   INT UNSIGNED NOT NULL,
  category_id  INT UNSIGNED NOT NULL,
  item_name    TEXT NOT NULL,
  quantity     INT NOT NULL,
  unit_price   DECIMAL(12,2) NOT NULL,
  total_price  DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (item_id),
  KEY idx_receipt_items_receipt_id (receipt_id),
  KEY idx_receipt_items_category_id (category_id),
  CONSTRAINT chk_receipt_items_qty_pos CHECK (quantity > 0),
  CONSTRAINT chk_receipt_items_unitprice_nonneg CHECK (unit_price >= 0.00),
  CONSTRAINT chk_receipt_items_total_eq CHECK (total_price = quantity * unit_price),
  CONSTRAINT fk_receipt_items_receipt_id
    FOREIGN KEY (receipt_id) REFERENCES receipts (receipt_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_receipt_items_category_id
    FOREIGN KEY (category_id) REFERENCES categories (category_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------
-- DML: Insert data  (Order: roles → users → stores → categories → receipts → receipt_items)
-- ------------------------------------------------------------------

-- Roles
INSERT INTO roles (role_id, role_name) VALUES
  (1, 'Admin'),
  (2, 'User');

-- Users (ทั้งสองเป็น Admin)
INSERT INTO users
  (user_id, email, username, password_hash, full_name, role_id, profile_image, created_at, updated_at)
VALUES
  (1, '67110985@dpu.ac.th', 'u67110985', 'sha256:dummydigest1', 'Thanawat Chaiyaphum', 1, NULL, '2024-10-01 09:30:00', '2025-09-01 08:00:00'),
  (2, '67111072@dpu.ac.th', 'u67111072', 'sha256:dummydigest2', 'Napatsorn Prasert',   1, NULL, '2024-10-01 09:45:00', '2025-09-01 08:05:00');

-- Stores (ชื่อร้านตามที่กำหนดเป๊ะ)
INSERT INTO stores (store_id, store_name, address, phone) VALUES
  (1, 'seven eleven', 'ถ.สุขุมวิท 71 แขวงพระโขนงเหนือ เขตวัฒนา กรุงเทพฯ 10110', '02-381-0000'),
  (2, 'tesco lutos',  '99 หมู่ 2 ถ.พหลโยธิน ต.คลองหนึ่ง อ.คลองหลวง จ.ปทุมธานี 12120', '02-150-2000'),
  (3, 'big c',        '125 ถ.ราชปรารภ แขวงมักกะสัน เขตราชเทวี กรุงเทพฯ 10400', '02-250-1234');

-- Categories (หลากหลาย)
INSERT INTO categories (category_id, category_name) VALUES
  (1,  'Beverages'),
  (2,  'Snacks'),
  (3,  'Personal Care'),
  (4,  'Household'),
  (5,  'Grocery'),
  (6,  'Frozen'),
  (7,  'Bakery'),
  (8,  'Dairy'),
  (9,  'Produce'),
  (10, 'Meat & Seafood');

-- Receipts (อย่างน้อย 20 ใบ, กระจายวันที่ช่วง 6–12 เดือนย้อนหลังจาก 2025-09-25)
-- สลับ user_id และครบทุกร้าน, created_at ไม่นำหน้า receipt_date
INSERT INTO receipts (receipt_id, user_id, store_id, receipt_date, total_amount, created_at) VALUES
  (1,  1, 1, '2024-10-05', 192.00, '2024-10-05 18:30:00'),
  (2,  2, 2, '2024-11-12', 334.00, '2024-11-12 19:10:00'),
  (3,  1, 3, '2024-12-03', 209.00, '2024-12-03 17:45:00'),
  (4,  2, 1, '2025-01-15', 224.00, '2025-01-15 20:05:00'),
  (5,  1, 2, '2025-02-10', 354.00, '2025-02-10 13:20:00'),
  (6,  2, 3, '2025-03-22', 336.00, '2025-03-22 14:10:00'),
  (7,  1, 1, '2025-04-05', 242.00, '2025-04-05 11:00:00'),
  (8,  2, 2, '2025-05-18', 249.00, '2025-05-18 16:40:00'),
  (9,  1, 3, '2025-06-07', 359.00, '2025-06-07 18:20:00'),
  (10, 2, 1, '2025-07-01', 131.00, '2025-07-01 08:15:00'),
  (11, 1, 2, '2025-08-14', 394.00, '2025-08-14 19:30:00'),
  (12, 2, 3, '2025-09-05', 358.00, '2025-09-05 10:25:00'),
  (13, 1, 1, '2024-10-20', 157.00, '2024-10-20 21:00:00'),
  (14, 2, 2, '2024-11-28', 310.00, '2024-11-28 15:35:00'),
  (15, 1, 3, '2025-01-28', 228.00, '2025-01-28 12:10:00'),
  (16, 2, 1, '2025-03-05', 110.00, '2025-03-05 09:50:00'),
  (17, 1, 2, '2025-04-20', 275.00, '2025-04-20 18:00:00'),
  (18, 2, 3, '2025-06-21', 204.00, '2025-06-21 19:10:00'),
  (19, 1, 1, '2025-07-19', 155.00, '2025-07-19 07:55:00'),
  (20, 2, 2, '2025-08-30', 284.00, '2025-08-30 20:45:00');

-- Receipt Items (2–6 รายการ/ใบ, ระบุหมวดถูกต้อง, total_price = quantity * unit_price)
INSERT INTO receipt_items (item_id, receipt_id, category_id, item_name, quantity, unit_price, total_price) VALUES
  -- Receipt 1 (192.00)
  (1, 1, 1,  'โออิชิ กรีนที กลิ่นมะลิ 500ml',         2,  29.00,  58.00),
  (2, 1, 2,  'เลย์ รสโนริสาหร่าย 48g',                1,  25.00,  25.00),
  (3, 1, 3,  'ยาสระผมซันซิล 320ml สีส้ม',              1, 109.00, 109.00),

  -- Receipt 2 (334.00)
  (4, 2, 5,  'ข้าวหอมมะลิ 5kg',                        1, 165.00, 165.00),
  (5, 2, 4,  'ผงซักฟอก Breeze 800g',                    1,  79.00,  79.00),
  (6, 2, 8,  'นมเมจิ ยูเอชที 200ml 3 แพ็ค',            2,  45.00,  90.00),

  -- Receipt 3 (209.00)
  (7, 3, 7,  'ขนมปังแถว เบเกอรี่',                      2,  35.00,  70.00),
  (8, 3, 5,  'ไข่ไก่ เบอร์ 2 (โหล)',                    1,  75.00,  75.00),
  (9, 3, 1,  'โค้ก 1.5 ลิตร',                            2,  32.00,  64.00),

  -- Receipt 4 (224.00)
  (10, 4, 5, 'มาม่า คัพ/แพ็ค 5 ซอง',                    1,  55.00,  55.00),
  (11, 4, 8, 'เบทาเก้น 85ml x5',                         2,  42.00,  84.00),
  (12, 4, 3, 'ยาสีฟันคอลเกต 150g',                      1,  85.00,  85.00),

  -- Receipt 5 (354.00)
  (13, 5, 6, 'เกี๊ยวซ่าแช่แข็ง 400g',                   1, 119.00, 119.00),
  (14, 5,10, 'เนื้ออกไก่ 1kg',                           2,  95.00, 190.00),
  (15, 5, 9, 'บรอกโคลี 1 หัว',                           1,  45.00,  45.00),

  -- Receipt 6 (336.00)
  (16, 6, 4, 'กระดาษทิชชู่ 24 ม้วน',                     1, 199.00, 199.00),
  (17, 6, 1, 'โออิชิ กรีนที กลิ่นมะลิ 500ml',           3,  29.00,  87.00),
  (18, 6, 2, 'เลย์ รสโนริสาหร่าย 48g',                  2,  25.00,  50.00),

  -- Receipt 7 (242.00)
  (19, 7, 8, 'ยาคูลท์ 5 ขวด',                             1,  55.00,  55.00),
  (20, 7, 7, 'แซนด์วิชพร้อมทาน',                          2,  39.00,  78.00),
  (21, 7, 3, 'ยาสระผมซันซิล 320ml สีส้ม',                1, 109.00, 109.00),

  -- Receipt 8 (249.00)
  (22, 8,10, 'สันนอกหมู 1kg',                              1, 139.00, 139.00),
  (23, 8, 9, 'กะหล่ำปลี 1 หัว',                            2,  25.00,  50.00),
  (24, 8, 1, 'สไปร์ท 1.5 ลิตร',                             2,  30.00,  60.00),

  -- Receipt 9 (359.00)
  (25, 9, 4, 'น้ำยาซักผ้า 1500ml',                         1, 189.00, 189.00),
  (26, 9, 8, 'นมเมจิ พาสเจอร์ไรส์ 2 ลิตร',                 1,  95.00,  95.00),
  (27, 9, 2, 'โอรีโอ้ 133g',                                3,  25.00,  75.00),

  -- Receipt 10 (131.00)
  (28,10, 1, 'เอ็ม-150 150ml',                              3,  12.00,  36.00),
  (29,10, 2, 'เลย์ รสดั้งเดิม 50g',                         2,  30.00,  60.00),
  (30,10, 7, 'ขนมปังแผ่น',                                   1,  35.00,  35.00),

  -- Receipt 11 (394.00)
  (31,11, 3, 'แชมพูเฮดแอนด์โชว์เดอร์ส 330ml',               1, 169.00, 169.00),
  (32,11, 6, 'มันฝรั่งแท่งแช่แข็ง 1kg',                      1, 129.00, 129.00),
  (33,11, 1, 'โค้ก 1.5 ลิตร',                                 3,  32.00,  96.00),

  -- Receipt 12 (358.00)
  (34,12,10, 'น่องไก่ 1kg',                                   2,  89.00, 178.00),
  (35,12, 6, 'ไอศกรีมคอร์นเนตโต 75g',                         4,  25.00, 100.00),
  (36,12, 4, 'กระดาษเช็ดหน้า (กล่อง)',                         2,  40.00,  80.00),

  -- Receipt 13 (157.00)
  (37,13, 7, 'ขนมปังยากิโซบะ',                                2,  29.00,  58.00),
  (38,13, 8, 'ดัชมิลล์ ซีเล็คเต็ด 1 ลิตร',                      1,  59.00,  59.00),
  (39,13, 1, 'เนสกาแฟกระป๋อง 180ml',                           2,  20.00,  40.00),

  -- Receipt 14 (310.00)
  (40,14, 5, 'ข้าวหอมมะลิ 5kg',                                1, 165.00, 165.00),
  (41,14, 5, 'น้ำมันปาล์ม 1 ลิตร',                              1,  69.00,  69.00),
  (42,14, 4, 'น้ำยาล้างจาน 500ml',                              2,  38.00,  76.00),

  -- Receipt 15 (228.00)
  (43,15, 5, 'โอวัลติน 400g',                                   1, 115.00, 115.00),
  (44,15, 9, 'กล้วยหอม 1kg',                                    1,  35.00,  35.00),
  (45,15, 8, 'โยเกิร์ตดัชชี่ 135g',                             6,  13.00,  78.00),

  -- Receipt 16 (110.00)
  (46,16, 2, 'เบนโตะ ปลาหมึกอบ 24g',                            4,  10.00,  40.00),
  (47,16, 1, 'ไวตามิลค์ 300ml',                                  3,  15.00,  45.00),
  (48,16, 3, 'พาราเซตามอล 500mg 10 เม็ด',                        1,  25.00,  25.00),

  -- Receipt 17 (275.00)
  (49,17,10, 'หมูสับ 1kg',                                       1, 120.00, 120.00),
  (50,17, 9, 'หอมหัวใหญ่ 1kg',                                   1,  30.00,  30.00),
  (51,17, 9, 'มะเขือเทศ 1kg',                                    1,  35.00,  35.00),
  (52,17, 8, 'นมยูเอชที 1 ลิตร',                                 2,  45.00,  90.00),

  -- Receipt 18 (204.00)
  (53,18, 3, 'ครีมอาบน้ำโชกุบุสซึ 500ml',                       1,  99.00,  99.00),
  (54,18, 1, 'เป๊ปซี่ 1.5 ลิตร',                                  2,  30.00,  60.00),
  (55,18, 7, 'ขนมปังโฮลวีท',                                     1,  45.00,  45.00),

  -- Receipt 19 (155.00)
  (56,19, 9, 'ข้าวโพดต้มพร้อมทาน',                                2,  25.00,  50.00),
  (57,19, 1, 'อเมริกาโน่เย็น 22oz',                               1,  45.00,  45.00),
  (58,19, 2, 'มันฝรั่งแผ่นขนาดเล็ก',                              3,  20.00,  60.00),

  -- Receipt 20 (284.00)
  (59,20, 6, 'นักเก็ตไก่แช่แข็ง 500g',                           1, 129.00, 129.00),
  (60,20, 4, 'น้ำยาถูพื้น 800ml',                                  1,  65.00,  65.00),
  (61,20, 1, 'น้ำดื่มเนสท์เล่ เพียวไลฟ์ 1.5 ลิตร',                6,  15.00,  90.00);

-- ------------------------------------------------------------------
-- Indexes explicitly required (some already covered above)
-- ------------------------------------------------------------------
-- receipts(receipt_date) and receipts(user_id, store_id) already created
-- receipt_items(receipt_id) and receipt_items(category_id) already created
-- users(email) unique index already created

-- ------------------------------------------------------------------
-- VALIDATION QUERIES (ควรรันแล้วให้ผลสอดคล้อง)
-- ------------------------------------------------------------------

-- 1) ตรวจว่าทุกใบเสร็จมี total_amount ตรงกับผลรวมรายการ (ควรได้ 0 แถว)
SELECT
  r.receipt_id,
  r.total_amount,
  SUM(ri.total_price) AS calc_items_sum
FROM receipts r
JOIN receipt_items ri ON ri.receipt_id = r.receipt_id
GROUP BY r.receipt_id, r.total_amount
HAVING ROUND(SUM(ri.total_price),2) <> ROUND(r.total_amount,2);

-- 2) นับจำนวนใบเสร็จต่อร้าน/ต่อเดือน (พิสูจน์ว่ามีหลายเดือน)
SELECT
  s.store_name,
  DATE_FORMAT(r.receipt_date, '%Y-%m') AS month_key,
  COUNT(*) AS receipt_count
FROM receipts AS r
JOIN stores   AS s ON s.store_id = r.store_id
GROUP BY
  s.store_name,
  DATE_FORMAT(r.receipt_date, '%Y-%m')
ORDER BY
  DATE_FORMAT(r.receipt_date, '%Y-%m'),
  s.store_name;

COMMIT;
