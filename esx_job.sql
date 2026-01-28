-- Heli-Taxi Job für ESX
-- Führe diese SQL-Befehle in deiner Datenbank aus (z.B. phpMyAdmin, HeidiSQL)

-- 1. Job erstellen
INSERT INTO `jobs` (`name`, `label`) VALUES
('helitaxi', 'Heli-Taxi');

-- 2. Ränge erstellen
INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
('helitaxi', 0, 'junior_pilot', 'Junior Pilot', 1500, '{}', '{}'),
('helitaxi', 1, 'pilot', 'Pilot', 2500, '{}', '{}'),
('helitaxi', 2, 'assistant', 'Assistent', 3500, '{}', '{}'),
('helitaxi', 3, 'boss', 'Boss', 5000, '{}', '{}'),
('helitaxi', 4, 'illegal', 'Illegal Operator', 4000, '{}', '{}');

-- SPIELER JOB ZUWEISEN:
-- Variante 1 - Via SQL:
-- UPDATE users SET job = 'helitaxi', job_grade = 3 WHERE identifier = 'DEIN_IDENTIFIER';
--
-- Variante 2 - Via Server Konsole:
-- setjob [ID] helitaxi [grade]
--
-- Grades:
-- 0 = Junior Pilot
-- 1 = Pilot  
-- 2 = Assistent
-- 3 = Boss
-- 4 = Illegal (Zugang zu illegalen Operationen)

