-- ------------------------------------------------------------------
-- Retail Receipts + Incomes Demo Schema & Sample Data (MySQL 8.0+)
-- Adds income functions, categories, sample rows (~20).
-- Also hashes passwords via SQL SHA2(...,256).
-- ------------------------------------------------------------------

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
DROP TABLE IF EXISTS stores;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;

-- NEW income objects
DROP TABLE IF EXISTS incomes;
DROP TABLE IF EXISTS income_categories;
SET FOREIGN_KEY_CHECKS = 1;

-- ------------------------------------------------------------------
-- DDL
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

-- Stores
CREATE TABLE stores (
  store_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  store_name  VARCHAR(100) NOT NULL,
  address     TEXT NOT NULL,
  phone       VARCHAR(20) NOT NULL,
  PRIMARY KEY (store_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Expense Categories (existing)
CREATE TABLE categories (
  category_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  category_name  VARCHAR(100) NOT NULL,
  PRIMARY KEY (category_id),
  UNIQUE KEY ux_categories_category_name (category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Receipts (expenses header)
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

-- Receipt Items (expenses detail)
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

-- >>> NEW: Income Categories
CREATE TABLE income_categories (
  income_category_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  income_category_name VARCHAR(100) NOT NULL,
  PRIMARY KEY (income_category_id),
  UNIQUE KEY ux_income_categories_name (income_category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- >>> NEW: Incomes (header-only; income is a single-number entry)
CREATE TABLE incomes (
  income_id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id            INT UNSIGNED NOT NULL,
  income_category_id INT UNSIGNED NOT NULL,
  amount             DECIMAL(12,2) NOT NULL,
  income_date        DATE NOT NULL,
  note               TEXT,
  created_at         DATETIME NOT NULL,
  PRIMARY KEY (income_id),
  KEY idx_incomes_date (income_date),
  KEY idx_incomes_user_cat (user_id, income_category_id),
  CONSTRAINT chk_incomes_amount_pos CHECK (amount > 0.00),
  CONSTRAINT chk_incomes_created_not_before_date CHECK (created_at >= CONCAT(income_date, ' 00:00:00')),
  CONSTRAINT fk_incomes_user_id
    FOREIGN KEY (user_id) REFERENCES users (user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_incomes_category_id
    FOREIGN KEY (income_category_id) REFERENCES income_categories (income_category_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------
-- DML: roles → users (with SQL hashing) → stores → categories → receipts → items
-- ------------------------------------------------------------------

-- Roles
INSERT INTO roles (role_id, role_name) VALUES
  (1, 'Admin'),
  (2, 'User');

-- Users (hash passwords in SQL; admins have no expense receipts)
INSERT INTO users
  (user_id, email, username, password_hash, full_name, role_id, profile_image, created_at, updated_at)
VALUES
  (1, '67110985@dpu.ac.th', 'u67110985', SHA2('Admin1234',256), 'Thanawat Chaiyaphum', 1, NULL, '2024-10-01 09:30:00', '2025-09-01 08:00:00'),
  (2, '67111072@dpu.ac.th', 'u67111072', SHA2('Admin1234',256), 'Napatsorn Prasert',   1, NULL, '2024-10-01 09:45:00', '2025-09-01 08:05:00'),

  -- Users (all receipts/incomes attach to these 3)
  (3, 'pimchanok@example.com', 'pimchanok', SHA2('123456',256), 'Pimchanok S.', 2, NULL, '2024-11-12 10:00:00', '2025-09-01 09:00:00'),
  (4, 'arunwat@example.com',   'arunwat',   SHA2('123456',256), 'Arunwat T.',   2, NULL, '2024-11-12 10:05:00', '2025-09-01 09:05:00'),
  (5, 'kittipat@example.com',  'kittipat',  SHA2('123456',256), 'Kittipat K.',  2, NULL, '2024-11-12 10:10:00', '2025-09-01 09:10:00');

-- Stores
INSERT INTO stores (store_id, store_name, address, phone) VALUES
  (1, 'seven eleven', 'ถ.สุขุมวิท 71 แขวงพระโขนงเหนือ เขตวัฒนา กรุงเทพฯ 10110', '02-381-0000'),
  (2, 'tesco lutos',  '99 หมู่ 2 ถ.พหลโยธิน ต.คลองหนึ่ง อ.คลองหลวง จ.ปทุมธานี 12120', '02-150-2000'),
  (3, 'big c',        '125 ถ.ราชปรารภ แขวงมักกะสัน เขตราชเทวี กรุงเทพฯ 10400', '02-250-1234');

-- Expense Categories (EN)
INSERT INTO categories (category_id, category_name) VALUES
  (1, 'Others'),
  (2, 'Food'),
  (3, 'Shopping'),
  (4, 'Bills'),
  (5, 'Transportation');

-- Receipts (sameตามที่ให้มา)
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
  (12, 5, 3, '2025-09-05', 358.00, '2025-09-05 10:25:00'),
  (13, 3, 1, '2024-10-20', 157.00, '2024-10-20 21:00:00'),
  (14, 4, 2, '2024-11-28', 310.00, '2024-11-28 15:35:00'),
  (15, 5, 3, '2025-01-28', 228.00, '2025-01-28 12:10:00'),
  (16, 3, 1, '2025-03-05', 110.00, '2025-03-05 09:50:00'),
  (17, 4, 2, '2025-04-20', 275.00, '2025-04-20 18:00:00'),
  (18, 5, 3, '2025-06-21', 204.00, '2025-06-21 19:10:00'),
  (19, 3, 1, '2025-07-19', 155.00, '2025-07-19 07:55:00'),
  (20, 4, 2, '2025-08-30', 284.00, '2025-08-30 20:45:00'),
  (21, 5, 1, '2025-10-02', 420.00, '2025-10-02 12:00:00'),
  (22, 3, 2, '2025-10-15', 255.00, '2025-10-15 09:30:00');

-- Receipt Items (sameตามที่ให้มา)
INSERT INTO receipt_items (item_id, receipt_id, category_id, item_name, quantity, unit_price, total_price) VALUES
  (1, 1,  2, 'โออิชิ กรีนที กลิ่นมะลิ 500ml', 2, 29.00, 58.00),
  (2, 1,  2, 'เลย์ รสโนริสาหร่าย 48g',       1, 25.00, 25.00),
  (3, 1,  3, 'ยาสระผมซันซิล 320ml สีส้ม',     1,109.00,109.00),
  (4, 2,  2, 'ข้าวหอมมะลิ 5kg',               1,165.00,165.00),
  (5, 2,  3, 'ผงซักฟอก Breeze 800g',           1, 79.00, 79.00),
  (6, 2,  2, 'นมเมจิ ยูเอชที 200ml 3 แพ็ค',    2, 45.00, 90.00),
  (7, 3,  2, 'ขนมปังแถว เบเกอรี่',             2, 35.00, 70.00),
  (8, 3,  2, 'ไข่ไก่ เบอร์ 2 (โหล)',           1, 75.00, 75.00),
  (9,  3,  2, 'โค้ก 1.5 ลิตร',                  2, 32.00, 64.00),
  (10,4,  2, 'มาม่า คัพ/แพ็ค 5 ซอง',           1, 55.00, 55.00),
  (11,4,  2, 'เบทาเก้น 85ml x5',                2, 42.00, 84.00),
  (12,4,  3, 'ยาสีฟันคอลเกต 150g',             1, 85.00, 85.00),
  (13,5,  2, 'เกี๊ยวซ่าแช่แข็ง 400g',          1,119.00,119.00),
  (14,5,  2, 'เนื้ออกไก่ 1kg',                  2, 95.00,190.00),
  (15,5,  2, 'บรอกโคลี 1 หัว',                  1, 45.00, 45.00),
  (16,6,  3, 'กระดาษทิชชู่ 24 ม้วน',            1,199.00,199.00),
  (17,6,  2, 'โออิชิ กรีนที กลิ่นมะลิ 500ml',  3, 29.00, 87.00),
  (18,6,  2, 'เลย์ รสโนริสาหร่าย 48g',         2, 25.00, 50.00),
  (19,7,  2, 'ยาคูลท์ 5 ขวด',                    1, 55.00, 55.00),
  (20,7,  2, 'แซนด์วิชพร้อมทาน',                 2, 39.00, 78.00),
  (21,7,  3, 'ยาสระผมซันซิล 320ml สีส้ม',        1,109.00,109.00),
  (22,8,  2, 'สันนอกหมู 1kg',                     1,139.00,139.00),
  (23,8,  2, 'กะหล่ำปลี 1 หัว',                   2, 25.00, 50.00),
  (24,8,  2, 'สไปร์ท 1.5 ลิตร',                    2, 30.00, 60.00),
  (25,9,  3, 'น้ำยาซักผ้า 1500ml',                1,189.00,189.00),
  (26,9,  2, 'นมเมจิ พาสเจอร์ไรส์ 2 ลิตร',        1, 95.00, 95.00),
  (27,9,  2, 'โอรีโอ้ 133g',                       3, 25.00, 75.00),
  (28,10, 2, 'เอ็ม-150 150ml',                     3, 12.00, 36.00),
  (29,10, 2, 'เลย์ รสดั้งเดิม 50g',                2, 30.00, 60.00),
  (30,10, 2, 'ขนมปังแผ่น',                          1, 35.00, 35.00),
  (31,11, 3, 'แชมพูเฮดแอนด์โชว์เดอร์ส 330ml',      1,169.00,169.00),
  (32,11, 2, 'มันฝรั่งแท่งแช่แข็ง 1kg',             1,129.00,129.00),
  (33,11, 2, 'โค้ก 1.5 ลิตร',                        3, 32.00, 96.00),
  (34,12, 2, 'น่องไก่ 1kg',                          2, 89.00,178.00),
  (35,12, 2, 'ไอศกรีมคอร์นเนตโต 75g',                4, 25.00,100.00),
  (36,12, 3, 'กระดาษเช็ดหน้า (กล่อง)',                2, 40.00, 80.00),
  (37,13, 2, 'ขนมปังยากิโซบะ',                       2, 29.00, 58.00),
  (38,13, 2, 'ดัชมิลล์ ซีเล็คเต็ด 1 ลิตร',             1, 59.00, 59.00),
  (39,13, 2, 'เนสกาแฟกระป๋อง 180ml',                  2, 20.00, 40.00),
  (40,14, 2, 'ข้าวหอมมะลิ 5kg',                       1,165.00,165.00),
  (41,14, 2, 'น้ำมันปาล์ม 1 ลิตร',                     1, 69.00, 69.00),
  (42,14, 3, 'น้ำยาล้างจาน 500ml',                     2, 38.00, 76.00),
  (43,15, 2, 'โอวัลติน 400g',                          1,115.00,115.00),
  (44,15, 2, 'กล้วยหอม 1kg',                           1, 35.00, 35.00),
  (45,15, 2, 'โยเกิร์ตดัชชี่ 135g',                    6, 13.00, 78.00),
  (46,16, 2, 'เบนโตะ ปลาหมึกอบ 24g',                   4, 10.00, 40.00),
  (47,16, 2, 'ไวตามิลค์ 300ml',                         3, 15.00, 45.00),
  (48,16, 1, 'พาราเซตามอล 500mg 10 เม็ด',               1, 25.00, 25.00),
  (49,17, 2, 'หมูสับ 1kg',                              1,120.00,120.00),
  (50,17, 2, 'หอมหัวใหญ่ 1kg',                          1, 30.00, 30.00),
  (51,17, 2, 'มะเขือเทศ 1kg',                           1, 35.00, 35.00),
  (52,17, 2, 'นมยูเอชที 1 ลิตร',                        2, 45.00, 90.00),
  (53,18, 3, 'ครีมอาบน้ำโชกุบุสซึ 500ml',              1, 99.00, 99.00),
  (54,18, 2, 'เป๊ปซี่ 1.5 ลิตร',                         2, 30.00, 60.00),
  (55,18, 2, 'ขนมปังโฮลวีท',                            1, 45.00, 45.00),
  (56,19, 2, 'ข้าวโพดต้มพร้อมทาน',                       2, 25.00, 50.00),
  (57,19, 2, 'อเมริกาโน่เย็น 22oz',                      1, 45.00, 45.00),
  (58,19, 2, 'มันฝรั่งแผ่นขนาดเล็ก',                     3, 20.00, 60.00),
  (59,20, 2, 'นักเก็ตไก่แช่แข็ง 500g',                   1,129.00,129.00),
  (60,20, 3, 'น้ำยาถูพื้น 800ml',                         1, 65.00, 65.00),
  (61,20, 2, 'น้ำดื่มเนสท์เล่ เพียวไลฟ์ 1.5 ลิตร',        6, 15.00, 90.00),
  (62,21, 4, 'ชำระค่าไฟฟ้า MEA กันยายน 2568',            1,320.00,320.00),
  (63,21, 5, 'เติมเงินบัตรแรบบิท BTS',                   1,100.00,100.00),
  (64,22, 5, 'เติมเงิน MRT Card',                         1,200.00,200.00),
  (65,22, 3, 'ซองเอกสาร A4 (แพ็ค)',                       1, 55.00, 55.00);

-- ------------------------------------------------------------------
-- NEW: Income Categories + Sample Incomes (~20 rows)
-- ------------------------------------------------------------------

INSERT INTO income_categories (income_category_id, income_category_name) VALUES
  (1, 'Salary'),
  (2, 'Wages'),
  (3, 'Gift'),
  (4, 'Sales');

-- Incomes: attach ONLY to users 3,4,5 (no Admin). Spread across months incl. Sep & Oct 2025.
INSERT INTO incomes (income_id, user_id, income_category_id, amount, income_date, note, created_at) VALUES
  -- User 3 (Pimchanok) - salary monthly + side incomes
  (1,  3, 1, 28000.00, '2025-06-30', 'Monthly salary',             '2025-06-30 09:00:00'),
  (2,  3, 1, 28000.00, '2025-07-31', 'Monthly salary',             '2025-07-31 09:00:00'),
  (3,  3, 1, 28000.00, '2025-08-31', 'Monthly salary',             '2025-08-31 09:00:00'),
  (4,  3, 1, 28000.00, '2025-09-30', 'Monthly salary',             '2025-09-30 09:00:00'),
  (5,  3, 1, 28000.00, '2025-10-31', 'Monthly salary',             '2025-10-31 09:00:00'),
  (6,  3, 4,  1200.00, '2025-09-12', 'Shopee thrift sale',         '2025-09-12 12:10:00'),
  (7,  3, 3,   800.00, '2025-10-10', 'Gift from friend',           '2025-10-10 18:05:00'),
  (8,  3, 2,  1500.00, '2025-04-15', 'Part-time event staff',      '2025-04-15 21:30:00'),

  -- User 4 (Arunwat) - higher salary + gigs
  (9,  4, 1, 35000.00, '2025-06-30', 'Monthly salary',             '2025-06-30 09:05:00'),
  (10, 4, 1, 35000.00, '2025-07-31', 'Monthly salary',             '2025-07-31 09:05:00'),
  (11, 4, 1, 35000.00, '2025-08-31', 'Monthly salary',             '2025-08-31 09:05:00'),
  (12, 4, 1, 35000.00, '2025-09-30', 'Monthly salary',             '2025-09-30 09:05:00'),
  (13, 4, 1, 35000.00, '2025-10-31', 'Monthly salary',             '2025-10-31 09:05:00'),
  (14, 4, 4,  2100.00, '2025-10-05', 'Sold used monitor',          '2025-10-05 14:20:00'),
  (15, 4, 2,  2000.00, '2025-09-20', 'Weekend freelance coding',   '2025-09-20 20:00:00'),
  (16, 4, 3,  1000.00, '2025-03-10', 'Birthday gift',              '2025-03-10 19:45:00'),

  -- User 5 (Kittipat) - steady salary + sales/wages
  (17, 5, 1, 26000.00, '2025-06-30', 'Monthly salary',             '2025-06-30 09:10:00'),
  (18, 5, 1, 26000.00, '2025-07-31', 'Monthly salary',             '2025-07-31 09:10:00'),
  (19, 5, 1, 26000.00, '2025-08-31', 'Monthly salary',             '2025-08-31 09:10:00'),
  (20, 5, 1, 26000.00, '2025-09-30', 'Monthly salary',             '2025-09-30 09:10:00'),
  (21, 5, 1, 26000.00, '2025-10-31', 'Monthly salary',             '2025-10-31 09:10:00'),
  (22, 5, 4,  3500.00, '2025-09-08', 'Garage sale (bicycle)',      '2025-09-08 11:25:00'),
  (23, 5, 2,  1800.00, '2025-10-12', 'Delivery helper (weekend)',  '2025-10-12 17:40:00');

-- ------------------------------------------------------------------
-- Helpful Indexes (already present for main usage)
-- ------------------------------------------------------------------
-- receipts(receipt_date), receipts(user_id,store_id)
-- receipt_items(receipt_id), receipt_items(category_id)
-- incomes(income_date), incomes(user_id, income_category_id)

-- ------------------------------------------------------------------
-- VALIDATION / ANALYTICS QUERIES
-- ------------------------------------------------------------------

-- 1) Expense: Every receipt total equals sum of its items (should return 0 rows)
SELECT
  r.receipt_id,
  r.total_amount,
  SUM(ri.total_price) AS calc_items_sum
FROM receipts r
JOIN receipt_items ri ON ri.receipt_id = r.receipt_id
GROUP BY r.receipt_id, r.total_amount
HAVING ROUND(SUM(ri.total_price),2) <> ROUND(r.total_amount,2);

-- 2) Expense count per store per month (shows spread incl. Sep & Oct 2025)
SELECT
  s.store_name,
  DATE_FORMAT(r.receipt_date, '%Y-%m') AS month_key,
  COUNT(*) AS receipt_count
FROM receipts r
JOIN stores s ON s.store_id = r.store_id
GROUP BY s.store_name, DATE_FORMAT(r.receipt_date, '%Y-%m')
ORDER BY month_key, s.store_name;

-- 3) Ensure no expenses are attached to Admin users (should be 0)
SELECT u.user_id, u.email, r.receipt_id
FROM users u
LEFT JOIN receipts r ON r.user_id = u.user_id
WHERE u.role_id = 1 AND r.receipt_id IS NOT NULL;

-- 4) Income totals by user & month
SELECT
  u.user_id,
  u.username,
  DATE_FORMAT(i.income_date, '%Y-%m') AS month_key,
  SUM(i.amount) AS total_income
FROM incomes i
JOIN users u ON u.user_id = i.user_id
GROUP BY u.user_id, u.username, DATE_FORMAT(i.income_date, '%Y-%m')
ORDER BY u.user_id, month_key;

-- 5) Income totals by category (all users)
SELECT
  ic.income_category_name,
  SUM(i.amount) AS total_amount
FROM incomes i
JOIN income_categories ic ON ic.income_category_id = i.income_category_id
GROUP BY ic.income_category_name
ORDER BY total_amount DESC;

-- 6) Net (Income - Expense) per user per month
WITH exp AS (
  SELECT user_id, DATE_FORMAT(receipt_date, '%Y-%m') AS m, SUM(total_amount) AS expense_total
  FROM receipts
  GROUP BY user_id, DATE_FORMAT(receipt_date, '%Y-%m')
),
inc AS (
  SELECT user_id, DATE_FORMAT(income_date, '%Y-%m') AS m, SUM(amount) AS income_total
  FROM incomes
  GROUP BY user_id, DATE_FORMAT(income_date, '%Y-%m')
)
SELECT
  COALESCE(inc.user_id, exp.user_id) AS user_id,
  DATE_FORMAT(STR_TO_DATE(CONCAT(COALESCE(inc.m, exp.m),'-01'), '%Y-%m-%d'), '%Y-%m') AS month_key,
  COALESCE(income_total, 0) AS income_total,
  COALESCE(expense_total, 0) AS expense_total,
  COALESCE(income_total, 0) - COALESCE(expense_total, 0) AS net_balance
FROM inc
FULL JOIN exp ON inc.user_id = exp.user_id AND inc.m = exp.m
ORDER BY user_id, month_key;

COMMIT;
