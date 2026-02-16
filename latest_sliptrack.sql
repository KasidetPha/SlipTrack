/*
 Navicat Premium Data Transfer

 Source Server         : SlipTrack Docker
 Source Server Type    : MySQL
 Source Server Version : 80045 (8.0.45)
 Source Host           : localhost:3307
 Source Schema         : sliptrack

 Target Server Type    : MySQL
 Target Server Version : 80045 (8.0.45)
 File Encoding         : 65001

 Date: 10/02/2026 14:22:25
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for budget_settings
-- ----------------------------
DROP TABLE IF EXISTS `budget_settings`;
CREATE TABLE `budget_settings`  (
  `setting_id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` int UNSIGNED NOT NULL,
  `warning_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `warning_percentage` tinyint UNSIGNED NOT NULL DEFAULT 80,
  `overspending_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`setting_id`) USING BTREE,
  UNIQUE INDEX `uq_budget_settings_user`(`user_id` ASC) USING BTREE,
  CONSTRAINT `fk_budget_settings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of budget_settings
-- ----------------------------
INSERT INTO `budget_settings` VALUES (1, 5, 1, 80, 1, '2025-12-03 13:36:30', '2025-12-03 13:36:30');

-- ----------------------------
-- Table structure for expense_budgets
-- ----------------------------
DROP TABLE IF EXISTS `expense_budgets`;
CREATE TABLE `expense_budgets`  (
  `budget_id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` int UNSIGNED NOT NULL,
  `category_id` int UNSIGNED NOT NULL,
  `year` smallint UNSIGNED NOT NULL,
  `month` tinyint UNSIGNED NOT NULL,
  `amount` decimal(12, 2) NOT NULL DEFAULT 0.00,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`budget_id`) USING BTREE,
  UNIQUE INDEX `uq_expense_budgets_user_cat_month`(`user_id` ASC, `category_id` ASC, `year` ASC, `month` ASC) USING BTREE,
  INDEX `fk_expbud_category`(`category_id` ASC) USING BTREE,
  CONSTRAINT `fk_expbud_category` FOREIGN KEY (`category_id`) REFERENCES `expense_categories` (`category_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_expbud_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 8 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of expense_budgets
-- ----------------------------
INSERT INTO `expense_budgets` VALUES (1, 5, 1, 2025, 12, 3000.00, '2025-12-03 13:36:30', '2025-12-03 13:36:30');
INSERT INTO `expense_budgets` VALUES (2, 5, 2, 2025, 12, 800.00, '2025-12-03 13:36:30', '2025-12-03 13:36:30');
INSERT INTO `expense_budgets` VALUES (3, 5, 4, 2025, 12, 0.00, '2025-12-16 15:30:30', '2025-12-16 15:30:30');
INSERT INTO `expense_budgets` VALUES (6, 5, 3, 2025, 12, 0.00, '2025-12-16 15:30:30', '2025-12-16 15:30:30');
INSERT INTO `expense_budgets` VALUES (7, 5, 5, 2025, 12, 20.00, '2025-12-16 15:30:30', '2025-12-16 15:30:30');

-- ----------------------------
-- Table structure for expense_categories
-- ----------------------------
DROP TABLE IF EXISTS `expense_categories`;
CREATE TABLE `expense_categories`  (
  `category_id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` int UNSIGNED NULL DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 1,
  `category_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `icon_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `color_hex` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  PRIMARY KEY (`category_id`) USING BTREE,
  UNIQUE INDEX `ux_categories_category_name`(`category_name` ASC) USING BTREE,
  INDEX `fk_expense_categories_user`(`user_id` ASC) USING BTREE,
  CONSTRAINT `fk_expense_categories_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of expense_categories
-- ----------------------------
INSERT INTO `expense_categories` VALUES (1, NULL, 1, 'Others', 'category', '#7F8C8D');
INSERT INTO `expense_categories` VALUES (2, NULL, 1, 'Food', 'restaurant', '#E67E22');
INSERT INTO `expense_categories` VALUES (3, NULL, 1, 'Shopping', 'shopping_bag', '#2980B9');
INSERT INTO `expense_categories` VALUES (4, NULL, 1, 'Bills', 'receipt_long', '#27AE60');
INSERT INTO `expense_categories` VALUES (5, NULL, 1, 'Transportation', 'directions_bus', '#8E44AD');

-- ----------------------------
-- Table structure for income_categories
-- ----------------------------
DROP TABLE IF EXISTS `income_categories`;
CREATE TABLE `income_categories`  (
  `income_category_id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` int UNSIGNED NULL DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 1,
  `income_category_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `icon_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `color_hex` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  PRIMARY KEY (`income_category_id`) USING BTREE,
  UNIQUE INDEX `ux_income_categories_name`(`income_category_name` ASC) USING BTREE,
  INDEX `fk_income_categories_user`(`user_id` ASC) USING BTREE,
  CONSTRAINT `fk_income_categories_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of income_categories
-- ----------------------------
INSERT INTO `income_categories` VALUES (1, NULL, 1, 'Salary', 'payments', '#2ECC71');
INSERT INTO `income_categories` VALUES (2, NULL, 1, 'Wages', 'work', '#3498DB');
INSERT INTO `income_categories` VALUES (3, NULL, 1, 'Gift', 'card_giftcard', '#9B59B6');
INSERT INTO `income_categories` VALUES (4, NULL, 1, 'Sales', 'sell', '#F1C40F');

-- ----------------------------
-- Table structure for incomes
-- ----------------------------
DROP TABLE IF EXISTS `incomes`;
CREATE TABLE `incomes`  (
  `income_id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` int UNSIGNED NOT NULL,
  `income_category_id` int UNSIGNED NOT NULL,
  `amount` decimal(12, 2) NOT NULL,
  `income_source` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `income_date` date NOT NULL,
  `note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`income_id`) USING BTREE,
  INDEX `idx_incomes_date`(`income_date` ASC) USING BTREE,
  INDEX `idx_incomes_user_cat`(`user_id` ASC, `income_category_id` ASC) USING BTREE,
  INDEX `fk_incomes_category_id`(`income_category_id` ASC) USING BTREE,
  CONSTRAINT `fk_incomes_category_id` FOREIGN KEY (`income_category_id`) REFERENCES `income_categories` (`income_category_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_incomes_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 39 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of incomes
-- ----------------------------
INSERT INTO `incomes` VALUES (1, 3, 1, 28000.00, NULL, '2025-06-30', 'Monthly salary', '2025-06-30 09:00:00');
INSERT INTO `incomes` VALUES (2, 3, 1, 28000.00, NULL, '2025-07-31', 'Monthly salary', '2025-07-31 09:00:00');
INSERT INTO `incomes` VALUES (3, 3, 1, 28000.00, NULL, '2025-08-31', 'Monthly salary', '2025-08-31 09:00:00');
INSERT INTO `incomes` VALUES (4, 3, 1, 28000.00, NULL, '2025-09-30', 'Monthly salary', '2025-09-30 09:00:00');
INSERT INTO `incomes` VALUES (5, 3, 1, 28000.00, NULL, '2025-10-31', 'Monthly salary', '2025-10-31 09:00:00');
INSERT INTO `incomes` VALUES (6, 3, 4, 1200.00, NULL, '2025-09-12', 'Shopee thrift sale', '2025-09-12 12:10:00');
INSERT INTO `incomes` VALUES (7, 3, 3, 800.00, NULL, '2025-10-10', 'Gift from friend', '2025-10-10 18:05:00');
INSERT INTO `incomes` VALUES (8, 3, 2, 1500.00, NULL, '2025-04-15', 'Part-time event staff', '2025-04-15 21:30:00');
INSERT INTO `incomes` VALUES (9, 4, 1, 35000.00, NULL, '2025-06-30', 'Monthly salary', '2025-06-30 09:05:00');
INSERT INTO `incomes` VALUES (10, 4, 1, 35000.00, NULL, '2025-07-31', 'Monthly salary', '2025-07-31 09:05:00');
INSERT INTO `incomes` VALUES (11, 4, 1, 35000.00, NULL, '2025-08-31', 'Monthly salary', '2025-08-31 09:05:00');
INSERT INTO `incomes` VALUES (12, 4, 1, 35000.00, NULL, '2025-09-30', 'Monthly salary', '2025-09-30 09:05:00');
INSERT INTO `incomes` VALUES (13, 4, 1, 35000.00, NULL, '2025-10-31', 'Monthly salary', '2025-10-31 09:05:00');
INSERT INTO `incomes` VALUES (14, 4, 4, 2100.00, NULL, '2025-10-05', 'Sold used monitor', '2025-10-05 14:20:00');
INSERT INTO `incomes` VALUES (15, 4, 2, 2000.00, NULL, '2025-09-20', 'Weekend freelance coding', '2025-09-20 20:00:00');
INSERT INTO `incomes` VALUES (16, 4, 3, 1000.00, NULL, '2025-03-10', 'Birthday gift', '2025-03-10 19:45:00');
INSERT INTO `incomes` VALUES (17, 5, 1, 26000.00, NULL, '2025-06-30', 'Monthly salary', '2025-06-30 09:10:00');
INSERT INTO `incomes` VALUES (18, 5, 1, 26000.00, NULL, '2025-07-31', 'Monthly salary', '2025-07-31 09:10:00');
INSERT INTO `incomes` VALUES (19, 5, 1, 26000.00, NULL, '2025-08-31', 'Monthly salary', '2025-08-31 09:10:00');
INSERT INTO `incomes` VALUES (20, 5, 1, 26000.00, NULL, '2025-09-30', 'Monthly salary', '2025-09-30 09:10:00');
INSERT INTO `incomes` VALUES (21, 5, 1, 26000.00, NULL, '2025-10-31', 'Monthly salary', '2025-10-31 09:10:00');
INSERT INTO `incomes` VALUES (22, 5, 4, 3500.00, NULL, '2025-09-08', 'Garage sale (bicycle)', '2025-09-08 11:25:00');
INSERT INTO `incomes` VALUES (23, 5, 2, 1800.00, NULL, '2025-10-12', 'Delivery helper (weekend)', '2025-10-12 17:40:00');
INSERT INTO `incomes` VALUES (24, 5, 1, 500.00, 'ขายของออนไลน์', '2025-12-06', 'test note', '2026-01-03 15:39:16');
INSERT INTO `incomes` VALUES (25, 5, 1, 1000.00, 'ขายของออนไลน์', '2026-01-03', 'test note', '2026-01-03 15:43:50');
INSERT INTO `incomes` VALUES (26, 5, 1, 2000.00, 'saraly', '2026-01-08', 'salary', '2026-01-08 13:28:12');
INSERT INTO `incomes` VALUES (27, 5, 2, 500.00, 'Job', '2026-01-08', 'for job', '2026-01-08 13:46:23');
INSERT INTO `incomes` VALUES (28, 5, 2, 500.00, 'Job', '2026-01-08', 'for job', '2026-01-08 13:49:29');
INSERT INTO `incomes` VALUES (29, 5, 2, 200.00, 'Job', '2026-01-09', 'job', '2026-01-09 16:01:18');
INSERT INTO `incomes` VALUES (30, 5, 2, 400.00, 'job', '2026-01-09', 'bro', '2026-01-09 16:49:44');
INSERT INTO `incomes` VALUES (31, 5, 1, 20000.00, 'Salary m12', '2026-01-11', '', '2026-01-11 13:02:00');
INSERT INTO `incomes` VALUES (32, 5, 2, 200.00, 'Jobs', '2026-01-11', '', '2026-01-11 13:16:14');
INSERT INTO `incomes` VALUES (33, 5, 2, 200.00, 'freelance', '2026-01-13', '1st', '2026-01-13 12:13:57');
INSERT INTO `incomes` VALUES (34, 5, 2, 500.00, 'job', '2026-01-16', 'freelance', '2026-01-16 14:50:08');
INSERT INTO `incomes` VALUES (35, 5, 2, 20.00, 'job', '2026-01-16', '', '2026-01-16 15:12:58');
INSERT INTO `incomes` VALUES (36, 5, 1, 20.00, 'sell', '2026-01-16', '', '2026-01-16 15:17:04');
INSERT INTO `incomes` VALUES (37, 5, 1, 60.00, 'saw drop', '2026-01-17', '', '2026-01-17 04:47:42');
INSERT INTO `incomes` VALUES (38, 5, 2, 200.00, 'freelance', '2026-01-17', '', '2026-01-17 04:48:45');

-- ----------------------------
-- Table structure for receipt_items
-- ----------------------------
DROP TABLE IF EXISTS `receipt_items`;
CREATE TABLE `receipt_items`  (
  `item_id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `receipt_id` int UNSIGNED NOT NULL,
  `category_id` int UNSIGNED NOT NULL,
  `item_name` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` int NOT NULL,
  `unit_price` decimal(12, 2) NOT NULL,
  `total_price` decimal(12, 2) NOT NULL,
  PRIMARY KEY (`item_id`) USING BTREE,
  INDEX `idx_receipt_items_receipt_id`(`receipt_id` ASC) USING BTREE,
  INDEX `idx_receipt_items_category_id`(`category_id` ASC) USING BTREE,
  CONSTRAINT `fk_receipt_items_expense_category_id` FOREIGN KEY (`category_id`) REFERENCES `expense_categories` (`category_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_receipt_items_receipt_id` FOREIGN KEY (`receipt_id`) REFERENCES `receipts` (`receipt_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 99 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of receipt_items
-- ----------------------------
INSERT INTO `receipt_items` VALUES (1, 1, 2, 'โออิชิ กรีนที กลิ่นมะลิ 500ml', 2, 29.00, 58.00);
INSERT INTO `receipt_items` VALUES (2, 1, 2, 'เลย์ รสโนริสาหร่าย 48g', 1, 25.00, 25.00);
INSERT INTO `receipt_items` VALUES (3, 1, 3, 'ยาสระผมซันซิล 320ml สีส้ม', 1, 109.00, 109.00);
INSERT INTO `receipt_items` VALUES (4, 2, 2, 'ข้าวหอมมะลิ 5kg', 1, 165.00, 165.00);
INSERT INTO `receipt_items` VALUES (5, 2, 3, 'ผงซักฟอก Breeze 800g', 1, 79.00, 79.00);
INSERT INTO `receipt_items` VALUES (6, 2, 2, 'นมเมจิ ยูเอชที 200ml 3 แพ็ค', 2, 45.00, 90.00);
INSERT INTO `receipt_items` VALUES (7, 3, 2, 'ขนมปังแถว เบเกอรี่', 2, 35.00, 70.00);
INSERT INTO `receipt_items` VALUES (8, 3, 2, 'ไข่ไก่ เบอร์ 2 (โหล)', 1, 75.00, 75.00);
INSERT INTO `receipt_items` VALUES (9, 3, 2, 'โค้ก 1.5 ลิตร', 2, 32.00, 64.00);
INSERT INTO `receipt_items` VALUES (10, 4, 2, 'มาม่า คัพ/แพ็ค 5 ซอง', 1, 55.00, 55.00);
INSERT INTO `receipt_items` VALUES (11, 4, 2, 'เบทาเก้น 85ml x5', 2, 42.00, 84.00);
INSERT INTO `receipt_items` VALUES (12, 4, 3, 'ยาสีฟันคอลเกต 150g', 1, 85.00, 85.00);
INSERT INTO `receipt_items` VALUES (13, 5, 2, 'เกี๊ยวซ่าแช่แข็ง 400g', 1, 119.00, 119.00);
INSERT INTO `receipt_items` VALUES (14, 5, 2, 'เนื้ออกไก่ 1kg', 2, 95.00, 190.00);
INSERT INTO `receipt_items` VALUES (15, 5, 2, 'บรอกโคลี 1 หัว', 1, 45.00, 45.00);
INSERT INTO `receipt_items` VALUES (16, 6, 3, 'กระดาษทิชชู่ 24 ม้วน', 1, 199.00, 199.00);
INSERT INTO `receipt_items` VALUES (17, 6, 2, 'โออิชิ กรีนที กลิ่นมะลิ 500ml', 3, 29.00, 87.00);
INSERT INTO `receipt_items` VALUES (18, 6, 2, 'เลย์ รสโนริสาหร่าย 48g', 2, 25.00, 50.00);
INSERT INTO `receipt_items` VALUES (19, 7, 2, 'ยาคูลท์ 5 ขวด', 1, 55.00, 55.00);
INSERT INTO `receipt_items` VALUES (20, 7, 2, 'แซนด์วิชพร้อมทาน', 2, 39.00, 78.00);
INSERT INTO `receipt_items` VALUES (21, 7, 3, 'ยาสระผมซันซิล 320ml สีส้ม', 1, 109.00, 109.00);
INSERT INTO `receipt_items` VALUES (22, 8, 2, 'สันนอกหมู 1kg', 1, 139.00, 139.00);
INSERT INTO `receipt_items` VALUES (23, 8, 2, 'กะหล่ำปลี 1 หัว', 2, 25.00, 50.00);
INSERT INTO `receipt_items` VALUES (24, 8, 2, 'สไปร์ท 1.5 ลิตร', 2, 30.00, 60.00);
INSERT INTO `receipt_items` VALUES (25, 9, 3, 'น้ำยาซักผ้า 1500ml', 1, 189.00, 189.00);
INSERT INTO `receipt_items` VALUES (26, 9, 2, 'นมเมจิ พาสเจอร์ไรส์ 2 ลิตร', 1, 95.00, 95.00);
INSERT INTO `receipt_items` VALUES (27, 9, 2, 'โอรีโอ้ 133g', 3, 25.00, 75.00);
INSERT INTO `receipt_items` VALUES (28, 10, 2, 'เอ็ม-150 150ml', 3, 12.00, 36.00);
INSERT INTO `receipt_items` VALUES (29, 10, 2, 'เลย์ รสดั้งเดิม 50g', 2, 30.00, 60.00);
INSERT INTO `receipt_items` VALUES (30, 10, 2, 'ขนมปังแผ่น', 1, 35.00, 35.00);
INSERT INTO `receipt_items` VALUES (31, 11, 3, 'แชมพูเฮดแอนด์โชว์เดอร์ส 330ml', 1, 169.00, 169.00);
INSERT INTO `receipt_items` VALUES (32, 11, 2, 'มันฝรั่งแท่งแช่แข็ง 1kg', 1, 129.00, 129.00);
INSERT INTO `receipt_items` VALUES (33, 11, 2, 'โค้ก 1.5 ลิตร', 3, 32.00, 96.00);
INSERT INTO `receipt_items` VALUES (34, 12, 2, 'น่องไก่ 1kg', 2, 89.00, 178.00);
INSERT INTO `receipt_items` VALUES (35, 12, 2, 'ไอศกรีมคอร์นเนตโต 75g', 4, 25.00, 100.00);
INSERT INTO `receipt_items` VALUES (36, 12, 3, 'กระดาษเช็ดหน้า (กล่อง)', 2, 40.00, 80.00);
INSERT INTO `receipt_items` VALUES (37, 13, 2, 'ขนมปังยากิโซบะ', 2, 29.00, 58.00);
INSERT INTO `receipt_items` VALUES (38, 13, 2, 'ดัชมิลล์ ซีเล็คเต็ด 1 ลิตร', 1, 59.00, 59.00);
INSERT INTO `receipt_items` VALUES (39, 13, 2, 'เนสกาแฟกระป๋อง 180ml', 2, 20.00, 40.00);
INSERT INTO `receipt_items` VALUES (40, 14, 2, 'ข้าวหอมมะลิ 5kg', 1, 165.00, 165.00);
INSERT INTO `receipt_items` VALUES (41, 14, 2, 'น้ำมันปาล์ม 1 ลิตร', 1, 69.00, 69.00);
INSERT INTO `receipt_items` VALUES (42, 14, 3, 'น้ำยาล้างจาน 500ml', 2, 38.00, 76.00);
INSERT INTO `receipt_items` VALUES (43, 15, 2, 'โอวัลติน 400g', 1, 115.00, 115.00);
INSERT INTO `receipt_items` VALUES (44, 15, 2, 'กล้วยหอม 1kg', 1, 35.00, 35.00);
INSERT INTO `receipt_items` VALUES (45, 15, 2, 'โยเกิร์ตดัชชี่ 135g', 6, 13.00, 78.00);
INSERT INTO `receipt_items` VALUES (46, 16, 2, 'เบนโตะ ปลาหมึกอบ 24g', 4, 10.00, 40.00);
INSERT INTO `receipt_items` VALUES (47, 16, 2, 'ไวตามิลค์ 300ml', 3, 15.00, 45.00);
INSERT INTO `receipt_items` VALUES (48, 16, 1, 'พาราเซตามอล 500mg 10 เม็ด', 1, 25.00, 25.00);
INSERT INTO `receipt_items` VALUES (49, 17, 2, 'หมูสับ 1kg', 1, 120.00, 120.00);
INSERT INTO `receipt_items` VALUES (50, 17, 2, 'หอมหัวใหญ่ 1kg', 1, 30.00, 30.00);
INSERT INTO `receipt_items` VALUES (51, 17, 2, 'มะเขือเทศ 1kg', 1, 35.00, 35.00);
INSERT INTO `receipt_items` VALUES (52, 17, 2, 'นมยูเอชที 1 ลิตร', 2, 45.00, 90.00);
INSERT INTO `receipt_items` VALUES (53, 18, 3, 'ครีมอาบน้ำโชกุบุสซึ 500ml', 1, 99.00, 99.00);
INSERT INTO `receipt_items` VALUES (54, 18, 2, 'เป๊ปซี่ 1.5 ลิตร', 2, 30.00, 60.00);
INSERT INTO `receipt_items` VALUES (55, 18, 2, 'ขนมปังโฮลวีท', 1, 45.00, 45.00);
INSERT INTO `receipt_items` VALUES (56, 19, 2, 'ข้าวโพดต้มพร้อมทาน', 2, 25.00, 50.00);
INSERT INTO `receipt_items` VALUES (57, 19, 2, 'อเมริกาโน่เย็น 22oz', 1, 45.00, 45.00);
INSERT INTO `receipt_items` VALUES (58, 19, 2, 'มันฝรั่งแผ่นขนาดเล็ก', 3, 20.00, 60.00);
INSERT INTO `receipt_items` VALUES (59, 20, 2, 'นักเก็ตไก่แช่แข็ง 500g', 1, 129.00, 129.00);
INSERT INTO `receipt_items` VALUES (60, 20, 3, 'น้ำยาถูพื้น 800ml', 1, 65.00, 65.00);
INSERT INTO `receipt_items` VALUES (61, 20, 2, 'น้ำดื่มเนสท์เล่ เพียวไลฟ์ 1.5 ลิตร', 6, 15.00, 90.00);
INSERT INTO `receipt_items` VALUES (62, 21, 4, 'ชำระค่าไฟฟ้า MEA กันยายน 2568', 1, 320.00, 320.00);
INSERT INTO `receipt_items` VALUES (63, 21, 5, 'เติมเงินบัตรแรบบิท BTS', 1, 100.00, 100.00);
INSERT INTO `receipt_items` VALUES (64, 22, 5, 'เติมเงิน MRT Card', 1, 200.00, 200.00);
INSERT INTO `receipt_items` VALUES (65, 22, 3, 'ซองเอกสาร A4 (แพ็ค)', 1, 55.00, 55.00);
INSERT INTO `receipt_items` VALUES (66, 23, 1, 'TrueMoney Wallet', 1, 200.00, 200.00);
INSERT INTO `receipt_items` VALUES (67, 24, 2, 'kfc', 1, 100.00, 100.00);
INSERT INTO `receipt_items` VALUES (68, 25, 3, 'shirt', 1, 50.00, 50.00);
INSERT INTO `receipt_items` VALUES (69, 26, 2, 'candy', 1, 10.00, 10.00);
INSERT INTO `receipt_items` VALUES (70, 27, 2, 'kfc', 1, 200.00, 200.00);
INSERT INTO `receipt_items` VALUES (71, 28, 5, 'bus', 1, 10.00, 10.00);
INSERT INTO `receipt_items` VALUES (72, 29, 3, 'shopee', 1, 200.00, 200.00);
INSERT INTO `receipt_items` VALUES (73, 30, 2, 'food', 1, 300.00, 300.00);
INSERT INTO `receipt_items` VALUES (74, 31, 5, 'grab', 1, 30.00, 30.00);
INSERT INTO `receipt_items` VALUES (75, 32, 4, 'bill', 1, 10000.00, 10000.00);
INSERT INTO `receipt_items` VALUES (76, 33, 5, 'train', 1, 11.00, 11.00);
INSERT INTO `receipt_items` VALUES (77, 34, 1, 'wallet', 1, 100.00, 100.00);
INSERT INTO `receipt_items` VALUES (78, 35, 5, 'bus', 1, 12000.00, 12000.00);
INSERT INTO `receipt_items` VALUES (89, 42, 1, 'นมกล่อง', 3, 33.00, 99.00);
INSERT INTO `receipt_items` VALUES (90, 42, 2, 'นมถั่วเหลือง UHT', 1, 15.00, 15.00);
INSERT INTO `receipt_items` VALUES (91, 43, 5, 'นมกล่อง', 5, 20.00, 100.00);
INSERT INTO `receipt_items` VALUES (92, 43, 2, 'นมถั่วเหลือง UHT', 7, 10.00, 70.00);
INSERT INTO `receipt_items` VALUES (93, 44, 2, 'box', 3, 11.00, 33.00);
INSERT INTO `receipt_items` VALUES (94, 44, 3, 'shirt', 3, 150.00, 450.00);
INSERT INTO `receipt_items` VALUES (95, 45, 3, 'dog', 1, 1500.00, 1500.00);
INSERT INTO `receipt_items` VALUES (96, 45, 2, 'cat', 1, 1200.00, 1200.00);
INSERT INTO `receipt_items` VALUES (97, 46, 3, 'tree', 1, 1500.00, 1500.00);
INSERT INTO `receipt_items` VALUES (98, 46, 3, 'short', 1, 1200.00, 1200.00);

-- ----------------------------
-- Table structure for receipts
-- ----------------------------
DROP TABLE IF EXISTS `receipts`;
CREATE TABLE `receipts`  (
  `receipt_id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` int UNSIGNED NOT NULL,
  `store_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `receipt_date` date NOT NULL,
  `total_amount` decimal(12, 2) NOT NULL,
  `source` enum('manual','ocr') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'manual',
  `ocr_status` enum('pending','success','failed') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `ocr_duration_ms` int UNSIGNED NULL DEFAULT NULL,
  `ocr_error_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `ocr_error_message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `ocr_engine` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `raw_ocr_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`receipt_id`) USING BTREE,
  INDEX `idx_receipts_receipt_date`(`receipt_date` ASC) USING BTREE,
  INDEX `idx_receipts_user_store`(`user_id` ASC) USING BTREE,
  INDEX `fk_receipts_user_id`(`user_id` ASC) USING BTREE,
  CONSTRAINT `fk_receipts_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `receipts_chk_1` CHECK (json_valid(`raw_ocr_json`))
) ENGINE = InnoDB AUTO_INCREMENT = 47 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of receipts
-- ----------------------------
INSERT INTO `receipts` VALUES (1, 3, 'seven eleven', '2024-10-05', 192.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2024-10-05 18:30:00');
INSERT INTO `receipts` VALUES (2, 4, 'tesco lutos', '2024-11-12', 334.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2024-11-12 19:10:00');
INSERT INTO `receipts` VALUES (3, 5, 'big c', '2024-12-03', 209.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2024-12-03 17:45:00');
INSERT INTO `receipts` VALUES (4, 3, 'seven eleven', '2025-01-15', 224.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-01-15 20:05:00');
INSERT INTO `receipts` VALUES (5, 4, 'tesco lutos', '2025-02-10', 354.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-02-10 13:20:00');
INSERT INTO `receipts` VALUES (6, 5, 'big c', '2025-03-22', 336.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-03-22 14:10:00');
INSERT INTO `receipts` VALUES (7, 3, 'seven eleven', '2025-04-05', 242.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-04-05 11:00:00');
INSERT INTO `receipts` VALUES (8, 4, 'tesco lutos', '2025-05-18', 249.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-05-18 16:40:00');
INSERT INTO `receipts` VALUES (9, 5, 'big c', '2025-06-07', 359.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-06-07 18:20:00');
INSERT INTO `receipts` VALUES (10, 3, 'seven eleven', '2025-07-01', 131.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-07-01 08:15:00');
INSERT INTO `receipts` VALUES (11, 4, 'tesco lutos', '2025-08-14', 394.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-08-14 19:30:00');
INSERT INTO `receipts` VALUES (12, 5, 'big c', '2025-09-05', 358.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-09-05 10:25:00');
INSERT INTO `receipts` VALUES (13, 3, 'seven eleven', '2024-10-20', 157.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2024-10-20 21:00:00');
INSERT INTO `receipts` VALUES (14, 4, 'tesco lutos', '2024-11-28', 310.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2024-11-28 15:35:00');
INSERT INTO `receipts` VALUES (15, 5, 'big c', '2025-01-28', 228.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-01-28 12:10:00');
INSERT INTO `receipts` VALUES (16, 3, 'seven eleven', '2025-03-05', 110.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-03-05 09:50:00');
INSERT INTO `receipts` VALUES (17, 4, 'tesco lutos', '2025-04-20', 275.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-04-20 18:00:00');
INSERT INTO `receipts` VALUES (18, 5, 'big c', '2025-06-21', 204.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-06-21 19:10:00');
INSERT INTO `receipts` VALUES (19, 3, 'seven eleven', '2025-07-19', 155.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-07-19 07:55:00');
INSERT INTO `receipts` VALUES (20, 4, 'tesco lutos', '2025-08-30', 284.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-08-30 20:45:00');
INSERT INTO `receipts` VALUES (21, 5, 'seven eleven', '2025-10-02', 420.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-10-02 12:00:00');
INSERT INTO `receipts` VALUES (22, 3, 'tesco lutos', '2025-10-15', 255.00, 'manual', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-10-15 09:30:00');
INSERT INTO `receipts` VALUES (23, 5, NULL, '2026-01-16', 200.00, 'manual', 'pending', NULL, NULL, NULL, NULL, '7-11', NULL, '2026-01-16 14:27:00');
INSERT INTO `receipts` VALUES (24, 5, NULL, '2026-01-16', 100.00, 'manual', 'pending', NULL, NULL, NULL, NULL, 'the mall', NULL, '2026-01-16 14:50:49');
INSERT INTO `receipts` VALUES (25, 5, NULL, '2026-01-16', 50.00, 'manual', 'pending', NULL, NULL, NULL, NULL, 'shopee', NULL, '2026-01-16 15:05:48');
INSERT INTO `receipts` VALUES (26, 5, NULL, '2026-01-16', 10.00, 'manual', 'pending', NULL, NULL, NULL, NULL, '7-11', NULL, '2026-01-16 15:12:40');
INSERT INTO `receipts` VALUES (27, 5, NULL, '2026-01-16', 200.00, 'manual', 'pending', NULL, NULL, NULL, NULL, '', NULL, '2026-01-16 15:24:45');
INSERT INTO `receipts` VALUES (28, 5, NULL, '2026-01-16', 10.00, 'manual', 'pending', NULL, NULL, NULL, NULL, '', NULL, '2026-01-16 15:25:43');
INSERT INTO `receipts` VALUES (29, 5, NULL, '2026-01-16', 200.00, 'manual', 'pending', NULL, NULL, NULL, NULL, '', NULL, '2026-01-16 15:34:50');
INSERT INTO `receipts` VALUES (30, 5, NULL, '2026-01-16', 300.00, 'manual', 'pending', NULL, NULL, NULL, NULL, '', NULL, '2026-01-16 15:35:17');
INSERT INTO `receipts` VALUES (31, 5, NULL, '2026-01-17', 30.00, 'manual', 'pending', NULL, NULL, NULL, NULL, '', NULL, '2026-01-17 04:26:32');
INSERT INTO `receipts` VALUES (32, 5, NULL, '2026-01-17', 10000.00, 'manual', 'pending', NULL, NULL, NULL, NULL, '', NULL, '2026-01-17 04:28:10');
INSERT INTO `receipts` VALUES (33, 5, NULL, '2026-01-17', 11.00, 'manual', 'pending', NULL, NULL, NULL, NULL, '', NULL, '2026-01-17 04:34:52');
INSERT INTO `receipts` VALUES (34, 5, NULL, '2026-01-17', 100.00, 'manual', 'pending', NULL, NULL, NULL, NULL, '', NULL, '2026-01-17 04:49:03');
INSERT INTO `receipts` VALUES (35, 5, NULL, '2026-01-19', 12000.00, 'manual', 'pending', NULL, NULL, NULL, NULL, 'bus 522', NULL, '2026-01-19 09:07:24');
INSERT INTO `receipts` VALUES (42, 5, '7-11', '2025-10-19', 114.00, 'ocr', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-09 07:57:12');
INSERT INTO `receipts` VALUES (43, 5, '7-11', '2026-02-09', 170.00, 'ocr', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-09 08:11:25');
INSERT INTO `receipts` VALUES (44, 5, '7-11', '2026-02-09', 483.00, 'ocr', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-09 08:29:16');
INSERT INTO `receipts` VALUES (45, 5, '7-11', '2026-02-09', 2700.00, 'ocr', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-09 08:45:27');
INSERT INTO `receipts` VALUES (46, 5, '7-11', '2026-02-09', 2700.00, 'ocr', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-09 08:50:20');

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users`  (
  `user_id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `full_name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('user','admin') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'user',
  `profile_image` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`user_id`) USING BTREE,
  UNIQUE INDEX `ux_users_email`(`email` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO `users` VALUES (1, '67110985@dpu.ac.th', 'u67110985', '60fe74406e7f353ed979f350f2fbb6a2e8690a5fa7d1b0c32983d1d8b3f95f67', 'Thanawat Chaiyaphum', 'user', NULL, '2024-10-01 09:30:00', '2025-09-01 08:00:00');
INSERT INTO `users` VALUES (2, '67111072@dpu.ac.th', 'u67111072', '60fe74406e7f353ed979f350f2fbb6a2e8690a5fa7d1b0c32983d1d8b3f95f67', 'Napatsorn Prasert', 'user', NULL, '2024-10-01 09:45:00', '2025-09-01 08:05:00');
INSERT INTO `users` VALUES (3, 'pimchanok@example.com', 'pimchanok', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'Pimchanok S.', 'user', NULL, '2024-11-12 10:00:00', '2025-09-01 09:00:00');
INSERT INTO `users` VALUES (4, 'arunwat@example.com', 'arunwat', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'Arunwat T.', 'user', NULL, '2024-11-12 10:05:00', '2025-09-01 09:05:00');
INSERT INTO `users` VALUES (5, 'kittipat@example.com', 'kittipat', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'Kittipat K.', 'user', NULL, '2024-11-12 10:10:00', '2025-09-01 09:10:00');

SET FOREIGN_KEY_CHECKS = 1;
