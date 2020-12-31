CREATE TABLE Account (
	account_id	SERIAL,
	first_name	VARCHAR(16)	NOT NULL,
	mid_name	VARCHAR(16),
	last_name	VARCHAR(16)	NOT NULL,
	gender		gender_t,
	birthday	DATE,
	acc_role	role_t		NOT NULL,
	email		TEXT		NOT NULL,
	phone		DECIMAL(11),
	salt		CHAR(8)		NOT NULL,
	hash		CHAR(40)	NOT NULL
	-- PRIMARY KEY	(account_id)
);

CREATE TABLE Student (
	student_id	SERIAL,
	st_group	CHAR(5)		NOT NULL,
	account_id	INT
	-- PRIMARY KEY	(student_id),
	-- FOREIGN KEY (account_id) REFERENCES Account(account_id)
);

CREATE TABLE Teacher (
	teacher_id	SERIAL,
	t_position	CHAR(22),
	account_id	INT			NOT NULL
	-- PRIMARY KEY	(teacher_id),
	-- FOREIGN KEY (teacher_id) REFERENCES Account(account_id)
);

CREATE TABLE Course (
	course_id	SERIAL,
	cousre_name	VARCHAR(50)	NOT NULL,
	teacher_id	INT			NOT NULL
	-- PRIMARY KEY	(course_id),
	-- FOREIGN KEY (teacher_id) REFERENCES Teacher(teacher_id)
);

CREATE TABLE Lesson (
	l_day		day_t,
	l_time		INT,
	l_place		INT,
	l_type		CHAR(3),
	course_id	INT			NOT NULL
	-- PRIMARY KEY	(l_day, l_time, l_place),
	-- FOREIGN KEY (course_id) REFERENCES Course(course_id)
);

CREATE TABLE StudentCourse (
	student_id	INT,
	course_id	INT,
	score		INT			DEFAULT 0
	-- PRIMARY KEY	(student_id, course_id),
	-- FOREIGN KEY (student_id) REFERENCES Student(student_id),
	-- FOREIGN KEY (course_id) REFERENCES Course(course_id),
);


ALTER TABLE Account ADD PRIMARY KEY (account_id);
ALTER TABLE Student ADD PRIMARY KEY (student_id);
ALTER TABLE Teacher ADD PRIMARY KEY (teacher_id);
ALTER TABLE Course ADD PRIMARY KEY (course_id);
ALTER TABLE Lesson ADD PRIMARY KEY (l_day, l_time, l_place);
ALTER TABLE StudentCourse ADD PRIMARY KEY (student_id, course_id);


ALTER TABLE Student ADD CONSTRAINT student_account_id_fkey FOREIGN KEY (account_id) REFERENCES Account(account_id);
ALTER TABLE Teacher ADD CONSTRAINT teacher_account_id_fkey FOREIGN KEY (account_id) REFERENCES Account(account_id);
ALTER TABLE Course ADD CONSTRAINT course_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES Teacher(teacher_id);
ALTER TABLE Lesson ADD CONSTRAINT lesson_course_id_fkey FOREIGN KEY (course_id) REFERENCES Course(course_id);
ALTER TABLE StudentCourse ADD CONSTRAINT studentcourse_student_id_fkey FOREIGN KEY (student_id) REFERENCES Student(student_id);
ALTER TABLE StudentCourse ADD CONSTRAINT studentcourse_course_id_fkey FOREIGN KEY (course_id) REFERENCES Course(course_id);


ALTER TABLE Account ADD CONSTRAINT unique_account UNIQUE (email, phone);

-- ALTER TABLE Account ALTER COLUMN email TYPE text;



COPY Account FROM '/home/ql/5/DB/1/csv/account.csv' DELIMITER ',' CSV HEADER;
COPY Student FROM '/home/ql/5/DB/1/csv/student.csv' DELIMITER ',' CSV HEADER;
COPY Teacher FROM '/home/ql/5/DB/1/csv/teacher.csv' DELIMITER ',' CSV HEADER;
COPY Course  FROM '/home/ql/5/DB/1/csv/course.csv'  DELIMITER ',' CSV HEADER;
-- COPY Lesson  FROM '/home/ql/5/DB/1/csv/lesson.csv' DELIMITER ',' CSV HEADER;
-- COPY StudentCourse FROM '/home/ql/5/DB/1/csv/student_course.csv' DELIMITER ',' CSV HEADER;

-- BEGIN;
-- CREATE TEMP TABLE tmp_1 ON COMMIT DROP
-- AS SELECT * FROM Lesson WITH NO DATA;

-- COPY tmp_1 FROM '/home/ql/5/DB/1/csv/lesson.csv' DELIMITER ',' CSV HEADER;

-- INSERT INTO Lesson
-- SELECT DISTINCT ON (l_day, l_time, l_place) * FROM tmp_1;
-- COMMIT;


-- BEGIN;
-- CREATE TEMP TABLE tmp_2 ON COMMIT DROP
-- AS SELECT * FROM StudentCourse WITH NO DATA;

-- COPY tmp_2 FROM '/home/ql/5/DB/1/csv/student_course.csv' DELIMITER ',' CSV HEADER;

-- INSERT INTO StudentCourse
-- SELECT DISTINCT ON (student_id, course_id) * FROM tmp_2;
-- COMMIT;
