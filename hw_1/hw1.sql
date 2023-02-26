DROP TABLE IF EXISTS office;

CREATE TABLE office (
	worker_id serial PRIMARY KEY,
	chief_id int,
	worker_name text
);

INSERT INTO office(chief_id, worker_name) 
VALUES 
	(-1, 'Saveliy Grigoryev'), 
	(1, 'Kirill Gavrilov'), 
	(1, 'Ainur Ibatov'),
	(2, 'Egor Postnikov'),
	(7, 'Petr Petrov'),
	(7, 'Dmitriy Ivanov'),
	(1, 'Nikolay Bukharev'),
	(6, 'Ivan Makarov'),
	(4, 'Prokhor Prokhorov'),
	(4, 'Vadim Vadimov');

--COPY office FROM 'C:/postgres_files/graph.csv' WITH (FORMAT csv);

-- Задание 1
DO $$
DECLARE
	new_worker_chef_id int := 5;
	new_worker_name text := 'Nikita Stroganov';
BEGIN
	INSERT INTO office(chief_id, worker_name) VALUES (new_worker_chef_id, new_worker_name);
END $$;

--Задание 2
DO $$
DECLARE
	new_chief_id int := 9;
	selected_worker_name text := 'Dmitriy Ivanov';
BEGIN
	UPDATE office SET chief_id = new_chief_id WHERE worker_name = selected_worker_name;
END $$;

--Задание 3
DO $$
DECLARE
	department_id int := 4;
BEGIN
	DROP TABLE IF EXISTS task_3;
	CREATE TABLE task_3 AS
		SELECT * FROM office WHERE worker_id = department_id OR chief_id = department_id;
END $$;
SELECT * FROM task_3;

--Задание 4
SELECT of1.worker_id, of1.chief_id, of1.worker_name
FROM 
	office of1
LEFT JOIN
	office of2
ON 
	of1.worker_id = of2.chief_id
WHERE
	of2.chief_id IS NULL;

--Задание 5
DO $$
DECLARE
	selected_worker_id int := 10;
BEGIN
	DROP TABLE IF EXISTS task_5;
	CREATE TABLE task_5 AS
		WITH RECURSIVE chief_chain AS (
			SELECT * FROM office WHERE worker_id = selected_worker_id
			UNION ALL
			SELECT of1.worker_id, of1.chief_id, of1.worker_name
			FROM 
				office of1
			INNER JOIN 
				chief_chain c_c 
			ON of1.worker_id = c_c.chief_id
		)
		SELECT * FROM chief_chain;
END $$;
SELECT * FROM task_5;

--Задание 6
DO $$
DECLARE
	department_id int := 7;
BEGIN
	DROP TABLE IF EXISTS task_6;
	CREATE TABLE task_6 AS
		WITH RECURSIVE subordinate AS (
			SELECT * FROM office WHERE worker_id = department_id
			UNION ALL
			SELECT of1.worker_id, of1.chief_id, of1.worker_name
			FROM
				office of1
			INNER JOIN
				subordinate sub
			ON of1.chief_id = sub.worker_id
		)
		SELECT COUNT(*) FROM subordinate;
END $$;
SELECT * FROM task_6;

--Задание 7
--true - корректный граф подчинения
--false - некорректный
DROP TABLE IF EXISTS task_7;
CREATE TABLE task_7 AS
	WITH RECURSIVE subordinate AS (
		SELECT * FROM office WHERE chief_id = -1
		UNION ALL
		SELECT of1.worker_id, of1.chief_id, of1.worker_name
		FROM
			office of1
		INNER JOIN
			subordinate sub
		ON of1.chief_id = sub.worker_id
	), subordinate_count(subordinates) AS (
		SELECT COUNT(*) FROM subordinate
	), supervisor(supervisors) AS (
		SELECT COUNT(*) FROM office WHERE chief_id = -1
	), all_workers(workers) AS (
		SELECT COUNT(*) FROM office
	)
	SELECT * FROM subordinate_count, supervisor, all_workers;
SELECT subordinates = workers AND supervisors = 1 FROM task_7;

--Задание 8
DO $$
DECLARE
	selected_worker_id int := 8;
BEGIN
	DROP TABLE IF EXISTS task_8;
	CREATE TABLE task_8 AS
		WITH RECURSIVE chief_chain AS (
			SELECT * FROM office WHERE worker_id = selected_worker_id
			UNION ALL
			SELECT of1.worker_id, of1.chief_id, of1.worker_name
			FROM 
				office of1
			INNER JOIN 
				chief_chain c_c 
			ON of1.worker_id = c_c.chief_id
		)
		SELECT * FROM chief_chain;
END $$;
SELECT COUNT(*) FROM task_8;

--Задание 9
WITH RECURSIVE office_level AS (
	SELECT ARRAY[office.worker_id] AS path_to_root, office.worker_id, office.chief_id, office.worker_name 
	FROM office 
	WHERE office.chief_id = -1
	
	UNION ALL
	
	SELECT lv.path_to_root || of1.worker_id, of1.worker_id, of1.chief_id, of1.worker_name
	FROM
		office of1
	INNER JOIN
		office_level lv
	ON of1.chief_id = lv.worker_id
)
SELECT REPEAT('-', 2 * ARRAY_LENGTH(office_level.path_to_root, 1) - 2) || office_level.worker_name FROM office_level
ORDER BY path_to_root;


--Задание 10
DO $$
DECLARE
	worker_a int := 1;
	worker_b int := 4;
BEGIN
	DROP TABLE IF EXISTS task_10;
	CREATE TABLE task_10 AS (
	WITH RECURSIVE office_level AS (
		SELECT 1 AS level, office.worker_id, office.chief_id FROM office WHERE office.chief_id = -1
		UNION ALL
		SELECT lv.level + 1, of1.worker_id, of1.chief_id
		FROM
			office of1
		INNER JOIN
			office_level lv
		ON of1.chief_id = lv.worker_id
	), path_a AS (
		SELECT * FROM office_level WHERE office_level.worker_id = worker_a
		UNION ALL
		SELECT lv.level, lv.worker_id, lv.chief_id
		FROM
			office_level lv
		INNER JOIN
			path_a
		ON lv.worker_id = path_a.chief_id
	), path_b AS (
		SELECT * FROM office_level WHERE office_level.worker_id = worker_b
		UNION ALL
		SELECT lv.level, lv.worker_id, lv.chief_id
		FROM
			office_level lv
		INNER JOIN
			path_b
		ON lv.worker_id = path_b.chief_id
	), lca AS (
		SELECT path_a.level, path_a.worker_id
		FROM
			path_a
		INNER JOIN
			path_b
		ON path_a.worker_id = path_b.worker_id
		ORDER BY level DESC
		LIMIT 1
	), path_a_to_lca AS (
		SELECT path_a.level, path_a.worker_id FROM path_a, lca
		WHERE path_a.level >= lca.level
		ORDER BY path_a.level DESC
	), path_b_to_lca AS (
		SELECT path_b.level, path_b.worker_id FROM path_b, lca
		WHERE path_b.level > lca.level
		ORDER BY path_b.level ASC
	) SELECT worker_id FROM path_a_to_lca UNION ALL SELECT worker_id FROM path_b_to_lca);
END $$;
SELECT * FROM task_10;
