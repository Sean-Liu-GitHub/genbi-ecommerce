-- create dataset
CREATE SCHEMA IF NOT EXISTS `genbi-ecommerce.raw_thelook` OPTIONS(location="US");

-- snapshot tables from bigquery public dataset
CREATE OR REPLACE TABLE `genbi-ecommerce.raw_thelook.orders` AS
SELECT * FROM `bigquery-public-data.thelook_ecommerce.orders`;

CREATE OR REPLACE TABLE `genbi-ecommerce.raw_thelook.order_items` AS
SELECT * FROM `bigquery-public-data.thelook_ecommerce.order_items`;

CREATE OR REPLACE TABLE `genbi-ecommerce.raw_thelook.users` AS
SELECT * FROM `bigquery-public-data.thelook_ecommerce.users`;

CREATE OR REPLACE TABLE `genbi-ecommerce.raw_thelook.products` AS
SELECT * FROM `bigquery-public-data.thelook_ecommerce.products`;

CREATE OR REPLACE TABLE `genbi-ecommerce.raw_thelook.inventory_items` AS
SELECT * FROM `bigquery-public-data.thelook_ecommerce.inventory_items`;

CREATE OR REPLACE TABLE `genbi-ecommerce.raw_thelook.events` AS
SELECT * FROM `bigquery-public-data.thelook_ecommerce.events`;

CREATE OR REPLACE TABLE `genbi-ecommerce.raw_thelook.distribution_centers` AS
SELECT * FROM `bigquery-public-data.thelook_ecommerce.distribution_centers`;

