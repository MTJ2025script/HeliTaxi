-- ========================================
-- Heli-Taxi Database Schema
-- Version 2.1.0 - Complete Rebuild with SQL Fixes
-- Includes: Normal Operations + Illegal Operations
-- FIXED: Correct column names (flight_date, transaction_type)
-- ========================================

-- ===== DROP ALL EXISTING TABLES FIRST =====
DROP TABLE IF EXISTS `heli_taxi_illegal_transactions`;
DROP TABLE IF EXISTS `heli_taxi_illegal_flights`;
DROP TABLE IF EXISTS `heli_taxi_illegal_vehicles`;
DROP TABLE IF EXISTS `heli_taxi_accounts`;
DROP TABLE IF EXISTS `heli_taxi_exclusive_missions`;
DROP TABLE IF EXISTS `heli_taxi_appointments`;
DROP TABLE IF EXISTS `heli_taxi_transactions`;
DROP TABLE IF EXISTS `heli_taxi_operating_costs`;
DROP TABLE IF EXISTS `heli_taxi_flights`;
DROP TABLE IF EXISTS `heli_taxi_vehicles`;
DROP TABLE IF EXISTS `heli_taxi_company`;
DROP TABLE IF EXISTS `heli_taxi_employees`;

-- ===== NORMAL OPERATIONS TABLES =====

-- Employees Table
-- HINWEIS: Der "illegal" Rang wird hier als normaler Rang gespeichert
-- Gültige Ränge: junior_pilot, pilot, assistant, boss, illegal
CREATE TABLE `heli_taxi_employees` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(60) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `rank` VARCHAR(50) NOT NULL DEFAULT 'junior_pilot',
    `secret_role` VARCHAR(50) NULL DEFAULT NULL,
    `salary` INT NOT NULL DEFAULT 1500,
    `hire_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `status` ENUM('on_duty', 'off_duty', 'break') DEFAULT 'off_duty',
    `total_flights` INT DEFAULT 0,
    `total_distance` FLOAT DEFAULT 0.0,
    `total_earned` INT DEFAULT 0,
    `security_clearance` ENUM('none', 'vip', 'military', 'government', 'top_secret') DEFAULT 'none',
    UNIQUE KEY `identifier` (`identifier`),
    INDEX `idx_rank` (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Company Account Table
CREATE TABLE `heli_taxi_company` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `balance` INT NOT NULL DEFAULT 50000,
    `total_income` INT DEFAULT 0,
    `total_expenses` INT DEFAULT 0,
    `illegal_balance` INT NOT NULL DEFAULT 0,
    `illegal_income` INT DEFAULT 0,
    `illegal_expenses` INT DEFAULT 0,
    `phone_number` VARCHAR(20) DEFAULT '555-8294',
    `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert initial company data
INSERT INTO `heli_taxi_company` (`balance`, `total_income`, `total_expenses`, `illegal_balance`, `illegal_income`, `illegal_expenses`) 
VALUES (50000, 0, 0, 0, 0, 0);

-- Vehicles Table (Normal Helikopter)
CREATE TABLE `heli_taxi_vehicles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `model` VARCHAR(50) NOT NULL,
    `plate` VARCHAR(20) NOT NULL,
    `condition` FLOAT DEFAULT 100.0,
    `fuel` FLOAT DEFAULT 100.0,
    `status` ENUM('available', 'in_use', 'maintenance', 'stored') DEFAULT 'available',
    `purchase_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_used` TIMESTAMP NULL,
    `total_flights` INT DEFAULT 0,
    `total_distance` FLOAT DEFAULT 0.0,
    UNIQUE KEY `plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert starter vehicles (Normal)
INSERT INTO `heli_taxi_vehicles` (`model`, `plate`, `condition`, `fuel`, `status`) VALUES
('frogger', 'HELI001', 100.0, 100.0, 'available'),
('swift', 'HELI002', 100.0, 100.0, 'available');

-- Flights Table (FIXED: flight_date statt date)
CREATE TABLE `heli_taxi_flights` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `pilot_identifier` VARCHAR(60) NOT NULL,
    `pilot_name` VARCHAR(100) NULL,
    `passenger_id` INT NULL DEFAULT NULL,
    `vehicle_model` VARCHAR(50) NULL,
    `vehicle_plate` VARCHAR(20) NULL,
    `start_location` VARCHAR(100),
    `end_location` VARCHAR(100),
    `distance` FLOAT NOT NULL,
    `duration` INT NOT NULL,
    `cost` INT NOT NULL,
    `fuel_consumed` FLOAT DEFAULT 0.0,
    `passenger_rating` INT DEFAULT 0,
    `tip_amount` INT DEFAULT 0,
    `flight_type` VARCHAR(50) DEFAULT 'standard',
    `is_exclusive` BOOLEAN DEFAULT FALSE,
    `flight_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_pilot` (`pilot_identifier`),
    INDEX `idx_passenger` (`passenger_id`),
    INDEX `idx_vehicle` (`vehicle_plate`),
    INDEX `idx_date` (`flight_date`),
    INDEX `idx_flight_type` (`flight_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Operating Costs Requests Table
CREATE TABLE `heli_taxi_operating_costs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `employee_identifier` VARCHAR(60) NOT NULL,
    `employee_name` VARCHAR(100) NOT NULL,
    `cost_type` ENUM('fuel', 'repair', 'maintenance', 'other') NOT NULL,
    `amount` INT NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `status` ENUM('pending', 'approved', 'declined') DEFAULT 'pending',
    `approved_by` VARCHAR(60) NULL,
    `approved_date` TIMESTAMP NULL,
    `request_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_employee` (`employee_identifier`),
    INDEX `idx_status` (`status`),
    INDEX `idx_date` (`request_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Transaction Logs Table (FIXED: transaction_type und transaction_date)
CREATE TABLE `heli_taxi_transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `transaction_type` VARCHAR(50) NOT NULL,
    `amount` INT NOT NULL,
    `description` VARCHAR(255) NOT NULL,
    `performer_identifier` VARCHAR(60),
    `performer_name` VARCHAR(100),
    `transaction_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_type` (`transaction_type`),
    INDEX `idx_date` (`transaction_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert initial transaction
INSERT INTO `heli_taxi_transactions` (`transaction_type`, `amount`, `description`, `performer_identifier`, `performer_name`) 
VALUES ('income', 50000, 'Initial company capital', 'system', 'System');

-- Appointments/Calendar Table
CREATE TABLE `heli_taxi_appointments` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT,
    `appointment_date` DATE NOT NULL,
    `appointment_time` TIME NOT NULL,
    `created_by` VARCHAR(60) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_date` (`appointment_date`),
    INDEX `idx_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Exclusive Missions Table
CREATE TABLE `heli_taxi_exclusive_missions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `mission_type` VARCHAR(50) NOT NULL,
    `pilot_identifier` VARCHAR(60) NOT NULL,
    `pilot_name` VARCHAR(100) NOT NULL,
    `vehicle_model` VARCHAR(50) NOT NULL,
    `vehicle_plate` VARCHAR(20) NOT NULL,
    `start_location` VARCHAR(100),
    `end_location` VARCHAR(100),
    `distance` FLOAT NOT NULL,
    `duration` INT NOT NULL,
    `payment` INT NOT NULL,
    `security_clearance_required` VARCHAR(20) NOT NULL,
    `mission_status` ENUM('pending', 'in_progress', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
    `completion_rating` INT DEFAULT 0,
    `bonus_earned` INT DEFAULT 0,
    `mission_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `completed_date` TIMESTAMP NULL,
    INDEX `idx_pilot` (`pilot_identifier`),
    INDEX `idx_mission_type` (`mission_type`),
    INDEX `idx_status` (`mission_status`),
    INDEX `idx_date` (`mission_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== ILLEGAL OPERATIONS TABLES (KOMPLETT GETRENNT) =====
-- Diese Tabellen sind NUR für Spieler mit Rang "illegal" oder "boss" zugänglich

-- Illegal Accounts Table (Schwarze Kasse pro Spieler)
CREATE TABLE `heli_taxi_accounts` (
    `identifier` VARCHAR(60) PRIMARY KEY,
    `black_cash` INT NOT NULL DEFAULT 0,
    `last_illegal_activity` TIMESTAMP NULL,
    `total_illegal_income` INT DEFAULT 0,
    `total_illegal_expenses` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_last_activity` (`last_illegal_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Illegal Vehicles Table (Army Helikopter - Getrennt von normalen Fahrzeugen)
-- WICHTIG: 2 Starter-Helikopter pro Helipad (6 total für 3 Helipads)
CREATE TABLE `heli_taxi_illegal_vehicles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `model` VARCHAR(50) NOT NULL,
    `plate` VARCHAR(20) NOT NULL,
    `helipad_index` INT NOT NULL,
    `condition` FLOAT DEFAULT 100.0,
    `fuel` FLOAT DEFAULT 100.0,
    `status` ENUM('available', 'in_use', 'maintenance', 'stored') DEFAULT 'available',
    `purchase_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_used` TIMESTAMP NULL,
    `total_flights` INT DEFAULT 0,
    `total_distance` FLOAT DEFAULT 0.0,
    UNIQUE KEY `plate` (`plate`),
    INDEX `idx_helipad` (`helipad_index`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert starter illegal vehicles (2 pro Helipad = 6 total)
-- Grundstamm: 2 Helis pro illegalen Landeplatz
INSERT INTO `heli_taxi_illegal_vehicles` (`model`, `plate`, `helipad_index`, `condition`, `fuel`, `status`) VALUES
('annihilator', 'ARMY001', 1, 100.0, 100.0, 'available'),
('buzzard', 'ARMY002', 1, 100.0, 100.0, 'available'),
('annihilator', 'ARMY003', 2, 100.0, 100.0, 'available'),
('buzzard', 'ARMY004', 2, 100.0, 100.0, 'available'),
('annihilator', 'ARMY005', 3, 100.0, 100.0, 'available'),
('buzzard', 'ARMY006', 3, 100.0, 100.0, 'available');

-- Illegal Flights Table (Separate History für illegale Flüge)
CREATE TABLE `heli_taxi_illegal_flights` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `pilot_identifier` VARCHAR(60) NOT NULL,
    `pilot_name` VARCHAR(100) NOT NULL,
    `vehicle_model` VARCHAR(50) NOT NULL,
    `vehicle_plate` VARCHAR(20) NOT NULL,
    `helipad_index` INT NOT NULL,
    `start_location` VARCHAR(100),
    `end_location` VARCHAR(100),
    `distance` FLOAT NOT NULL,
    `duration` INT NOT NULL,
    `payment` INT NOT NULL,
    `fuel_consumed` FLOAT DEFAULT 0.0,
    `flight_type` VARCHAR(50) DEFAULT 'illegal',
    `flight_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_pilot` (`pilot_identifier`),
    INDEX `idx_helipad` (`helipad_index`),
    INDEX `idx_vehicle` (`vehicle_plate`),
    INDEX `idx_date` (`flight_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Illegal Transactions Table (Separate Logs für illegale Operationen)
CREATE TABLE `heli_taxi_illegal_transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `transaction_type` VARCHAR(50) NOT NULL,
    `amount` INT NOT NULL,
    `description` VARCHAR(255) NOT NULL,
    `performer_identifier` VARCHAR(60),
    `performer_name` VARCHAR(100),
    `transaction_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_type` (`transaction_type`),
    INDEX `idx_performer` (`performer_identifier`),
    INDEX `idx_date` (`transaction_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== RANG ÜBERSICHT =====
-- 
-- NORMALE RÄNGE (Framework: ESX/QB-Core):
-- Grade 0 = junior_pilot (Junior Pilot) - Grundgehalt: $1500
-- Grade 1 = pilot (Pilot) - Grundgehalt: $2500
-- Grade 2 = assistant (Assistent) - Grundgehalt: $3500
-- Grade 3 = boss (Boss) - Grundgehalt: $5000 - Hat Zugang zu ALLEM (Normal + Illegal)
-- Grade 4 = illegal (Illegal Operator) - Grundgehalt: $4000 - Nur illegale Operationen
--
-- BERECHTIGUNGEN:
-- boss: Vollzugriff auf normale UND illegale Operationen
-- illegal: NUR Zugriff auf illegale Operationen (Garagen, Fahrzeuge, etc.)
-- 
-- ========================================
