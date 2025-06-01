-- Database: lab1-counter-db

-- DROP DATABASE IF EXISTS "lab1-counter-db";

CREATE DATABASE "lab1-counter-db"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Russian_Ukraine.1251'
    LC_CTYPE = 'Russian_Ukraine.1251'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

CREATE TABLE user_counter (
    user_id INT PRIMARY KEY,
    counter INT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 0
);

-- Стартовий запис, заповнити таблицю
INSERT INTO user_counter (user_id, counter, version) VALUES (1, 0, 0);


