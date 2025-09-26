-- ------------------------------------------------------------------
-- Retail Receipts Demo Schema & Sample Data (MySQL 8.0+)
-- Updates per request:
--  - Keep role "Admin" but DO NOT attach any receipts to Admin users.
--  - Add 3 more users with role "User" and attach all receipts to them.
--  - Replace categories with EN translations of: อื่นๆ, อาหาร, ช็อปปิ้ง, จ่ายบิล, เดินทาง
--    => ("Others","Food","Shopping","Bills","Transportation")
--  - Ensure receipt items include months 09 (Sep) and 10 (Oct), mixed with other months,
--    and category_id aligns with the new categories.
-- ------------------------------------------------------------------

-- Encoding & timezone (server/session)
SET NAMES utf8mb4;
SET time_zone = '+07:00';

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

-- Categories (replace with requested EN names)
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

-- Users
-- Keep 2 Admin users (no receipts attached to them)
INSERT INTO users
  (user_id, email, username, password_hash, full_name, role_id, profile_image, created_at, updated_at)
VALUES
  (1, '67110985@dpu.ac.th', 'u67110985', 'sha256:dummydigest1', 'Thanawat Chaiyaphum', 1, NULL, '2024-10-01 09:30:00', '2025-09-01 08:00:00'),
  (2, '67111072@dpu.ac.th', 'u67111072', 'sha256:dummydigest2', 'Napatsorn Prasert',   1, NULL, '2024-10-01 09:45:00', '2025-09-01 08:05:00');

-- Add 3 User-role accounts (all receipts will belong to these users ONLY)
INSERT INTO users
  (user_id, email, username, password_hash, full_name, role_id, profile_image, created_at, updated_at)
VALUES
  (3, 'pimchanok@example.com', 'pimchanok', 'sha256:userhash03', 'Pimchanok S.', 2, NULL, '2024-11-12 10:00:00', '2025-09-01 09:00:00'),
  (4, 'arunwat@example.com',   'arunwat',   'sha256:userhash04', 'Arunwat T.',   2, NULL, '2024-11-12 10:05:00', '2025-09-01 09:05:00'),
  (5, 'kittipat@example.com',  'kittipat',  'sha256:userhash05', 'Kittipat K.',  2, NULL, '2024-11-12 10:10:00', '2025-09-01 09:10:00');

-- Stores (ชื่อร้านตามที่กำหนดเป๊ะ)
INSERT INTO stores (store_id, store_name, address, phone) VALUES
  (1, 'seven eleven', 'ถ.สุขุมวิท 71 แขวงพระโขนงเหนือ เขตวัฒนา กรุงเทพฯ 10110', '02-381-0000'),
  (2, 'tesco lutos',  '99 หมู่ 2 ถ.พหลโยธิน ต.คลองหนึ่ง อ.คลองหลวง จ.ปทุมธานี 12120', '02-150-2000'),
  (3, 'big c',        '125 ถ.ราชปรารภ แขวงมักกะสัน เขตราชเทวี กรุงเทพฯ 10400', '02-250-1234');

-- Categories (EN translations of the requested Thai set)
--   1 Others (อื่นๆ)
--   2 Food (อาหาร)
--   3 Shopping (ช็อปปิ้ง / household & personal care & general goods)
--   4 Bills (จ่ายบิล)
--   5 Transportation (เดินทาง)
INSERT INTO categories (category_id, category_name) VALUES
  (1, 'Others'),
  (2, 'Food'),
  (3, 'Shopping'),
  (4, 'Bills'),
  (5, 'Transportation');

-- Receipts (22 rows; include months 2025-09 and 2025-10; attach ONLY to users 3,4,5)
-- created_at never before receipt_date
INSERT INTO receipts (receipt_id, user_id, store_id, receipt_date, total_amount, created_at) VALUES
  (1,  3, 1, '2024-10-05', 192.00, '2024-10-05 18:30:00'),
  (2,  4, 2, '2024-11-12', 334.00, '2024-11-12 19:10:00'),
  (3,  5, 3, '2024-12-03', 209.00, '2024-12-03 17:45:00'),
  (4,  3, 1, '2025-01-15', 224.00, '2025-01-15 20:05:00'),
  (5,  4, 2, '2025-02-10', 354.00, '2025-02-10 13:20:00'),
  (6,  5, 3, '2025-03-22', 336.00, '2025-03-22 14:10:00'),
  (7,  3, 1, '2025-04-05', 242.00, '2025-04-05 11:00:00'),
  (8,  4, 2, '2025-05-18', 249.00, '2025-05-18 16:40:00'),
  (9,  5, 3, '2025-06-07', 359.00, '2025-06-07 18:20:00'),
  (10, 3, 1, '2025-07-01', 131.00, '2025-07-01 08:15:00'),
  (11, 4, 2, '2025-08-14', 394.00, '2025-08-14 19:30:00'),
  (12, 5, 3, '2025-09-05', 358.00, '2025-09-05 10:25:00'),  -- Sep
  (13, 3, 1, '2024-10-20', 157.00, '2024-10-20 21:00:00'),
  (14, 4, 2, '2024-11-28', 310.00, '2024-11-28 15:35:00'),
  (15, 5, 3, '2025-01-28', 228.00, '2025-01-28 12:10:00'),
  (16, 3, 1, '2025-03-05', 110.00, '2025-03-05 09:50:00'),
  (17, 4, 2, '2025-04-20', 275.00, '2025-04-20 18:00:00'),
  (18, 5, 3, '2025-06-21', 204.00, '2025-06-21 19:10:00'),
  (19, 3, 1, '2025-07-19', 155.00, '2025-07-19 07:55:00'),
  (20, 4, 2, '2025-08-30', 284.00, '2025-08-30 20:45:00'),
  (21, 5, 1, '2025-10-02', 420.00, '2025-10-02 12:00:00'),  -- Oct
  (22, 3, 2, '2025-10-15', 255.00, '2025-10-15 09:30:00');  -- Oct

-- Receipt Items (map categories to the new set; ensure totals match each receipt)
-- Category mapping used below:
--   2 Food: drinks, snacks, fresh, frozen, bakery, dairy, grocery
--   3 Shopping: household, personal care, general goods/stationery
--   4 Bills: utility/phone bill payments
--   5 Transportation: transit top-ups / transport services
--   1 Others: medicines, miscellaneous
INSERT INTO receipt_items (item_id, receipt_id, category_id, item_name, quantity, unit_price, total_price) VALUES
  -- R1 (192.00)
  (1, 1,  2, 'โออิชิ กรีนที กลิ่นมะลิ 500ml', 2, 29.00, 58.00),
  (2, 1,  2, 'เลย์ รสโนริสาหร่าย 48g',       1, 25.00, 25.00),
  (3, 1,  3, 'ยาสระผมซันซิล 320ml สีส้ม',     1,109.00,109.00),

  -- R2 (334.00)
  (4, 2,  2, 'ข้าวหอมมะลิ 5kg',               1,165.00,165.00),
  (5, 2,  3, 'ผงซักฟอก Breeze 800g',           1, 79.00, 79.00),
  (6, 2,  2, 'นมเมจิ ยูเอชที 200ml 3 แพ็ค',    2, 45.00, 90.00),

  -- R3 (209.00)
  (7, 3,  2, 'ขนมปังแถว เบเกอรี่',             2, 35.00, 70.00),
  (8, 3,  2, 'ไข่ไก่ เบอร์ 2 (โหล)',           1, 75.00, 75.00),
  (9,  3,  2, 'โค้ก 1.5 ลิตร',                  2, 32.00, 64.00),

  -- R4 (224.00)
  (10,4,  2, 'มาม่า คัพ/แพ็ค 5 ซอง',           1, 55.00, 55.00),
  (11,4,  2, 'เบทาเก้น 85ml x5',                2, 42.00, 84.00),
  (12,4,  3, 'ยาสีฟันคอลเกต 150g',             1, 85.00, 85.00),

  -- R5 (354.00)
  (13,5,  2, 'เกี๊ยวซ่าแช่แข็ง 400g',          1,119.00,119.00),
  (14,5,  2, 'เนื้ออกไก่ 1kg',                  2, 95.00,190.00),
  (15,5,  2, 'บรอกโคลี 1 หัว',                  1, 45.00, 45.00),

  -- R6 (336.00)
  (16,6,  3, 'กระดาษทิชชู่ 24 ม้วน',            1,199.00,199.00),
  (17,6,  2, 'โออิชิ กรีนที กลิ่นมะลิ 500ml',  3, 29.00, 87.00),
  (18,6,  2, 'เลย์ รสโนริสาหร่าย 48g',         2, 25.00, 50.00),

  -- R7 (242.00)
  (19,7,  2, 'ยาคูลท์ 5 ขวด',                    1, 55.00, 55.00),
  (20,7,  2, 'แซนด์วิชพร้อมทาน',                 2, 39.00, 78.00),
  (21,7,  3, 'ยาสระผมซันซิล 320ml สีส้ม',        1,109.00,109.00),

  -- R8 (249.00)
  (22,8,  2, 'สันนอกหมู 1kg',                     1,139.00,139.00),
  (23,8,  2, 'กะหล่ำปลี 1 หัว',                   2, 25.00, 50.00),
  (24,8,  2, 'สไปร์ท 1.5 ลิตร',                    2, 30.00, 60.00),

  -- R9 (359.00)
  (25,9,  3, 'น้ำยาซักผ้า 1500ml',                1,189.00,189.00),
  (26,9,  2, 'นมเมจิ พาสเจอร์ไรส์ 2 ลิตร',        1, 95.00, 95.00),
  (27,9,  2, 'โอรีโอ้ 133g',                       3, 25.00, 75.00),

  -- R10 (131.00)
  (28,10, 2, 'เอ็ม-150 150ml',                     3, 12.00, 36.00),
  (29,10, 2, 'เลย์ รสดั้งเดิม 50g',                2, 30.00, 60.00),
  (30,10, 2, 'ขนมปังแผ่น',                          1, 35.00, 35.00),

  -- R11 (394.00)
  (31,11, 3, 'แชมพูเฮดแอนด์โชว์เดอร์ส 330ml',      1,169.00,169.00),
  (32,11, 2, 'มันฝรั่งแท่งแช่แข็ง 1kg',             1,129.00,129.00),
  (33,11, 2, 'โค้ก 1.5 ลิตร',                        3, 32.00, 96.00),

  -- R12 (358.00)  -- Sep 2025
  (34,12, 2, 'น่องไก่ 1kg',                          2, 89.00,178.00),
  (35,12, 2, 'ไอศกรีมคอร์นเนตโต 75g',                4, 25.00,100.00),
  (36,12, 3, 'กระดาษเช็ดหน้า (กล่อง)',                2, 40.00, 80.00),

  -- R13 (157.00)
  (37,13, 2, 'ขนมปังยากิโซบะ',                       2, 29.00, 58.00),
  (38,13, 2, 'ดัชมิลล์ ซีเล็คเต็ด 1 ลิตร',             1, 59.00, 59.00),
  (39,13, 2, 'เนสกาแฟกระป๋อง 180ml',                  2, 20.00, 40.00),

  -- R14 (310.00)
  (40,14, 2, 'ข้าวหอมมะลิ 5kg',                       1,165.00,165.00),
  (41,14, 2, 'น้ำมันปาล์ม 1 ลิตร',                     1, 69.00, 69.00),
  (42,14, 3, 'น้ำยาล้างจาน 500ml',                     2, 38.00, 76.00),

  -- R15 (228.00)
  (43,15, 2, 'โอวัลติน 400g',                          1,115.00,115.00),
  (44,15, 2, 'กล้วยหอม 1kg',                           1, 35.00, 35.00),
  (45,15, 2, 'โยเกิร์ตดัชชี่ 135g',                    6, 13.00, 78.00),

  -- R16 (110.00)
  (46,16, 2, 'เบนโตะ ปลาหมึกอบ 24g',                   4, 10.00, 40.00),
  (47,16, 2, 'ไวตามิลค์ 300ml',                         3, 15.00, 45.00),
  (48,16, 1, 'พาราเซตามอล 500mg 10 เม็ด',               1, 25.00, 25.00),

  -- R17 (275.00)
  (49,17, 2, 'หมูสับ 1kg',                              1,120.00,120.00),
  (50,17, 2, 'หอมหัวใหญ่ 1kg',                          1, 30.00, 30.00),
  (51,17, 2, 'มะเขือเทศ 1kg',                           1, 35.00, 35.00),
  (52,17, 2, 'นมยูเอชที 1 ลิตร',                        2, 45.00, 90.00),

  -- R18 (204.00)
  (53,18, 3, 'ครีมอาบน้ำโชกุบุสซึ 500ml',              1, 99.00, 99.00),
  (54,18, 2, 'เป๊ปซี่ 1.5 ลิตร',                         2, 30.00, 60.00),
  (55,18, 2, 'ขนมปังโฮลวีท',                            1, 45.00, 45.00),

  -- R19 (155.00)
  (56,19, 2, 'ข้าวโพดต้มพร้อมทาน',                       2, 25.00, 50.00),
  (57,19, 2, 'อเมริกาโน่เย็น 22oz',                      1, 45.00, 45.00),
  (58,19, 2, 'มันฝรั่งแผ่นขนาดเล็ก',                     3, 20.00, 60.00),

  -- R20 (284.00)
  (59,20, 2, 'นักเก็ตไก่แช่แข็ง 500g',                   1,129.00,129.00),
  (60,20, 3, 'น้ำยาถูพื้น 800ml',                         1, 65.00, 65.00),
  (61,20, 2, 'น้ำดื่มเนสท์เล่ เพียวไลฟ์ 1.5 ลิตร',        6, 15.00, 90.00),

  -- R21 (420.00)  -- Oct 2025: include Bills & Transportation
  (62,21, 4, 'ชำระค่าไฟฟ้า MEA กันยายน 2568',            1,320.00,320.00),
  (63,21, 5, 'เติมเงินบัตรแรบบิท BTS',                   1,100.00,100.00),

  -- R22 (255.00)  -- Oct 2025
  (64,22, 5, 'เติมเงิน MRT Card',                         1,200.00,200.00),
  (65,22, 3, 'ซองเอกสาร A4 (แพ็ค)',                       1, 55.00, 55.00);

-- ------------------------------------------------------------------
-- Indexes explicitly required (some already covered above)
-- ------------------------------------------------------------------
-- receipts(receipt_date) and receipts(user_id, store_id) already created
-- receipt_items(receipt_id) and receipt_items(category_id) already created
-- users(email) unique index already created

-- ------------------------------------------------------------------
-- VALIDATION QUERIES
-- ------------------------------------------------------------------

-- 1) Every receipt total equals sum of its items (should return 0 rows)
SELECT
  r.receipt_id,
  r.total_amount,
  SUM(ri.total_price) AS calc_items_sum
FROM receipts r
JOIN receipt_items ri ON ri.receipt_id = r.receipt_id
GROUP BY r.receipt_id, r.total_amount
HAVING ROUND(SUM(ri.total_price),2) <> ROUND(r.total_amount,2);

-- 2) Count receipts per store per month (demonstrate multi-month spread incl. Sep & Oct)
SELECT
  s.store_name,
  DATE_FORMAT(r.receipt_date, '%Y-%m') AS month_key,
  COUNT(*) AS receipt_count
FROM receipts AS r
JOIN stores   AS s ON s.store_id = r.store_id
GROUP BY s.store_name, DATE_FORMAT(r.receipt_date, '%Y-%m')
ORDER BY month_key, s.store_name;

-- 3) EXTRA CHECKS (helpful):
--    Ensure no receipts are attached to Admin users (should be 0)
SELECT u.user_id, u.email, r.receipt_id
FROM users u
LEFT JOIN receipts r ON r.user_id = u.user_id
WHERE u.role_id = 1 AND r.receipt_id IS NOT NULL;

COMMIT;
