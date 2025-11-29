# ShopHub SQL Assignment

Folder structure:
- 01_schema/             -- DDL scripts and ERD reference
- 02_data_cleaning/      -- Data quality checks and cleaning scripts
- 03_queries/            -- All assignment SQL queries (Q6–Q30)
- 04_optimization/       -- EXPLAIN outputs and optimization report

How to use:
1. Open MySQL Workbench and run 01_schema/create_tables.sql to create schema.
2. Import CSV files into respective tables (use LOAD DATA LOCAL INFILE or MySQL Workbench wizard).
3. Run data quality checks in 02_data_cleaning/data_quality_checks.sql.
4. Apply cleaning scripts from 02_data_cleaning/remove_duplicates.sql as needed.
5. Run analysis queries in 03_queries/partA_to_partG.sql.
6. For optimization, run EXPLAIN ANALYZE before/after adding indexes and save outputs to 04_optimization/.

ERD:
See dbdiagram: https://dbdiagram.io/d/692aa93dd6676488badf375f

Author: Yashashri Pawar
PS: sorry for the audio Quality in the Walkthrough video.
