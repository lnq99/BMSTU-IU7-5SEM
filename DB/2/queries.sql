-- 1. Инструкция SELECT, использующая предикат сравнения
SELECT student_id, T1.birthday, teacher_id, T2.birthday
FROM (student JOIN account ON student.account_id = account.account_id) AS T1
JOIN (teacher JOIN account ON teacher.account_id = account.account_id) AS T2
ON T1.birthday = T2.birthday
ORDER BY T1.birthday;



-- 2. Инструкция SELECT, использующая предикат BETWEEN.
SELECT student.student_id, course_name, score
FROM (studentcourse JOIN student ON student.student_id = studentcourse.student_id)
JOIN course ON studentcourse.course_id = course.course_id
WHERE score BETWEEN 95 AND 100;



-- 3. Инструкция SELECT, использующая предикат LIKE.
SELECT phone
FROM student JOIN account ON student.account_id = account.account_id
WHERE text(phone) LIKE '%8_8_8_8%';



-- 4. Инструкция SELECT, использующая предикат IN с вложенным подзапросом.
SELECT teacher.teacher_id
FROM course JOIN teacher ON course.teacher_id = teacher.teacher_id
WHERE course_id IN
    (
        SELECT DISTINCT course.course_id
        FROM course JOIN lesson ON course.course_id = lesson.course_id
        WHERE l_day = 'Вс'
    ) AND course_name LIKE 'Computer%';



-- 5. Инструкция SELECT, использующая предикат EXISTS с вложенным подзапросом.
SELECT course_id, course_name
FROM course
WHERE EXISTS
    (
        SELECT *
        FROM lesson
        WHERE course.course_id = lesson.course_id AND l_day = 'Вс' AND l_time = 1
    );



-- 6. Инструкция SELECT, использующая предикат сравнения с квантором.
SELECT account_id, email
FROM account
WHERE a_role = 'student' AND length(email) > ALL
    (
        SELECT length(email)
        FROM account
        WHERE a_role = 'teacher'
    );



-- 7. Инструкция SELECT, использующая агрегатные функции в выражениях столбцов.
SELECT s_group, sum(average), count(student_id), avg(average) AS average
FROM
    (
        SELECT student.student_id, student.s_group, avg(score) AS average
        FROM student JOIN studentcourse ON student.student_id = studentcourse.student_id
        GROUP BY student.student_id
    ) AS T 
GROUP BY s_group
ORDER BY average DESC;



-- 8. Инструкция SELECT, использующая скалярные подзапросы в выражениях столбцов.
SELECT student_id,
    (
        SELECT count(score) FROM studentcourse WHERE studentcourse.student_id = student.student_id
    ),
    (
        SELECT avg(score) FROM studentcourse WHERE studentcourse.student_id = student.student_id
    )
FROM student;



-- 9. Инструкция SELECT, использующая простое выражение CASE.
SELECT course.course_id, course_name, l_day, l_time, l_place,
    CASE l_day
        WHEN 'Пн' THEN 'Close'
        WHEN 'Вт' THEN 'Close'
        ELSE 'Open'
    END
FROM course JOIN lesson ON course.course_id = lesson.course_id;



-- 10. Инструкция SELECT, использующая поисковое выражение CASE.
SELECT student_id, course_id,
    CASE
        WHEN score >= 85 THEN 'Отлично'
        WHEN score >= 71 THEN 'Хорошо'
        WHEN score >= 60 THEN 'Удовлетворительно'
        ELSE 'Неудовлетворительно'
    END AS result
FROM studentcourse;



-- 11. Создание новой временной локальной таблицы из результирующего набора данных инструкции SELECT.
SELECT last_name, first_name, mid_name, phone
INTO TEMP iu1
FROM student JOIN account ON student.account_id = account.account_id
WHERE s_group = 'ИУ1';

SELECT * FROM iu1;
DROP TABLE iu1;



-- 12. Инструкция SELECT, использующая вложенные коррелированные подзапросы
-- в качестве производных таблиц в предложении FROM.
(
    SELECT student.student_id, s_group, cnt "N course", average
    FROM student JOIN
        (
            SELECT student_id, count(score) AS cnt, avg(score) AS average
            FROM studentcourse
            GROUP BY student_id
            ORDER BY average DESC, cnt DESC
        ) AS score ON student.s_group = 'ИУ1' AND student.student_id = score.student_id
    LIMIT 3
)
UNION
(
    SELECT student.student_id, s_group, cnt, average
    FROM student JOIN
        (
            SELECT student_id, count(score) AS cnt, avg(score) AS average
            FROM studentcourse
            GROUP BY student_id
            ORDER BY average DESC, cnt DESC
        ) AS score ON student.s_group = 'ИУ2' AND student.student_id = score.student_id
    LIMIT 3
);



-- 13. Инструкция SELECT, использующая вложенные подзапросы с уровнем вложенности 3.
-- teachers teach most courses
SELECT teacher_id, last_name, first_name, mid_name
FROM teacher JOIN account ON teacher.account_id = account.account_id
WHERE teacher_id IN
    (
        SELECT teacher_id
        FROM course
        GROUP BY teacher_id
        HAVING count(course_id) =
            (
                SELECT max(cnt)
                FROM
                    (
                        SELECT count(course_id) as cnt
                        FROM course
                        GROUP BY teacher_id
                    ) AS T
            )
    );



-- 14. Инструкция SELECT, консолидирующая данные с помощью предложения GROUP BY, но без предложения HAVING.
SELECT student.student_id, min(score), max(score), avg(score)
FROM student JOIN studentcourse ON student.student_id = studentcourse.student_id
WHERE student.s_group = 'МТ1'
GROUP BY student.student_id;



-- 15. Инструкция SELECT, консолидирующая данные с помощью предложения GROUP BY и предложения HAVING.
SELECT student.student_id, min(score), max(score), avg(score) AS average
FROM student JOIN studentcourse ON student.student_id = studentcourse.student_id
WHERE student.s_group = 'МТ1'
GROUP BY student.student_id
HAVING avg(score) < 50;



-- 16. Однострочная инструкция INSERT, выполняющая вставку в таблицу одной строки значений.
INSERT INTO studentcourse (student_id, course_id, score)
VALUES (1000, 4, 40)
ON CONFLICT (student_id, course_id)
DO UPDATE SET score = 40;

SELECT *
FROM studentcourse
WHERE student_id = 1000;

-- ?
INSERT INTO student
VALUES (DEFAULT, 'IU7', 30);
INSERT INTO student
VALUES (12001, 'IU7', 15);

SELECT *
FROM student
WHERE student_id > 11990;



-- 17. Многострочная инструкция INSERT, выполняющая вставку в таблицу результирующего набора данных вложенного подзапроса.
INSERT INTO lesson (l_day, l_time, l_place, l_type, course_id)
SELECT
    'Вт', l_time, l_place, l_type, course_id
FROM lesson
WHERE l_day = 'Пн' AND l_type = 'лек' AND course_id IN (
    SELECT course_id
        FROM course
        WHERE course_name LIKE 'Computer Science%'
)
ON CONFLICT
DO NOTHING;



-- 18. Простая инструкция UPDATE.
UPDATE account
SET phone = 83333333333
WHERE account_id = 10;

SELECT phone
FROM account
WHERE account_id = 10;



-- 19. Инструкция UPDATE со скалярным подзапросом в предложении SET.
UPDATE studentcourse
SET score =
    (
        SELECT avg(score)
        FROM studentcourse
        WHERE student_id = 1
    )
WHERE student_id = 1;

SELECT *
FROM studentcourse
WHERE student_id = 1;



-- 20. Простая инструкция DELETE.
DELETE FROM student
WHERE student_id = 16000;

SELECT *
FROM student
WHERE student_id > 11995;



-- 21. Инструкция DELETE с вложенным коррелированным подзапросом в предложении WHERE.
DELETE FROM student
WHERE student_id NOT IN
    (
        SELECT DISTINCT student_id
        FROM studentcourse
    );



-- 22. Инструкция SELECT, использующая простое обобщенное табличное выражение
WITH IU3 (student_id, score)
AS
    (
        SELECT G.student_id, avg(score)
        FROM (SELECT * FROM student WHERE s_group = 'ИУ3') AS G
        JOIN studentcourse
        ON G.student_id = studentcourse.student_id
        GROUP BY G.student_id
    )
SELECT avg(score)
FROM IU3;



-- 23. Инструкция SELECT, использующая рекурсивное обобщенное табличное выражение.
CREATE TABLE filesystem (f_path text PRIMARY KEY, is_directory boolean);

SELECT * FROM filesystem;
DROP TABLE filesystem;

INSERT INTO filesystem
VALUES
    ('/', true),
    ('/home', true),
    ('/home/Desktop', true),
    ('/home/Desktop/1.mp3', false),
    ('/home/Desktop/2.mp3', false),
    ('/home/Download', true),
    ('/home/Download/1.txt', false),
    ('/home/Download/2.txt', false);


WITH RECURSIVE FS(f_path, is_directory, f_level)
AS
    (
        (
            SELECT f_path, is_directory, 0 AS f_level
            FROM filesystem AS F
            WHERE f_path = '/'
        )
        UNION
        (
            SELECT F.f_path, F.is_directory, f_level + 1
            FROM
                filesystem AS F JOIN FS
                ON FS.is_directory AND F.f_path SIMILAR TO FS.f_path || '/?[^/]+'
        )
    )
SELECT *
FROM FS;

DROP TABLE filesystem;



-- 24. Оконные функции. Использование конструкций MIN/MAX/AVG OVER()
SELECT student_id, s_group, average,
    rank() OVER(PARTITION BY s_group ORDER BY average DESC) as rank_score,
    avg(average) OVER(PARTITION BY s_group) as avg_score,
    min(average) OVER(PARTITION BY s_group) as min_score,
    max(average) OVER(PARTITION BY s_group) as max_score
FROM
(
    SELECT S.student_id, s_group, avg(score) AS average
    FROM student AS S JOIN studentcourse AS SC ON S.student_id = SC.student_id
    GROUP BY S.student_id
) AS T
ORDER BY s_group, rank_score;



-- 25. Оконные фнкции для устранения дублей
SELECT student_id, s_group
INTO TABLE temp_table
FROM student
WHERE s_group = 'ФН1'
UNION ALL
SELECT student_id, s_group
FROM
(
    SELECT S.student_id, s_group, avg(score) as averege
    FROM student AS S JOIN studentcourse AS SC ON S.student_id = SC.student_id
    GROUP BY S.student_id
) AS T
WHERE averege > 60 AND s_group LIKE 'ФН%';

SELECT * FROM temp_table;
SELECT DISTINCT * FROM temp_table;
DROP TABLE temp_table;


DELETE FROM temp_table
WHERE ctid IN
(
    SELECT student_id, ctid
    FROM
    (
        SELECT student_id, ctid,
            row_number() OVER(PARTITION BY student_id ORDER BY student_id) AS row_num
        FROM temp_table
    ) AS T
    WHERE row_num > 1
);



-- Дополнительное задание
CREATE TABLE Table1 (id int, var1 text, valid_from date, valid_to date);
CREATE TABLE Table2 (id int, var2 text, valid_from date, valid_to date);

INSERT INTO Table1
VALUES
    (1, 'A', '2018-09-01', '2018-09-15'),
    (1, 'B', '2018-09-16', '5999-12-31');

INSERT INTO Table2
VALUES
    (1, 'A', '2018-09-01', '2018-09-18'),
    (1, 'B', '2018-09-19', '5999-12-31');

SELECT * FROM Table1;
SELECT * FROM Table2;
DROP TABLE Table1;
DROP TABLE Table2;

SELECT *
FROM Table1 AS T1 JOIN Table2 AS T2 ON T1.id = T2.id;

SELECT *
FROM Table1 AS T1 JOIN Table2 AS T2 ON T1.id = T2.id
    AND T1.valid_from < T2.valid_to AND T2.valid_from < T1.valid_to;


SELECT T1.id, var1, var2,
    CASE
        WHEN T1.valid_from > T2.valid_from THEN T1.valid_from
        ELSE T2.valid_from
    END AS valid_from_dttm,
    CASE
        WHEN T1.valid_to < T2.valid_to THEN T1.valid_to
        ELSE T2.valid_to
    END AS valid_to_dttm

FROM Table1 AS T1 JOIN Table2 AS T2 ON T1.id = T2.id
    AND T1.valid_from < T2.valid_to AND T2.valid_from < T1.valid_to;
