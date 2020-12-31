\c postgres;
drop database if exists rk2;
create database rk2;
\c rk2;
\! clear


create table worker (
    id              serial primary key,
    department_id   int,
    position        varchar(20),
    name            varchar(20),
    salary          int
    -- foreign key (department_id) references department(id)
);

create table department (
    id              serial primary key,
    name            varchar(8),
    phone           decimal(11),
    manager_id      int references worker(id)
);

create table medicament (
    id              serial primary key,
    name            varchar(20),
    intruction      text,
    price           int
);

create table worker_medicament (
    worker_id       int references worker(id),
    medicament_id   int references medicament(id)
);


insert into worker
values
    (default, 1, 'teacher', 'name 1', 800),
    (default, 2, 'manager', 'name 2', 1000);


-- ALTER TABLE Account ADD PRIMARY KEY (account_id);
alter table worker add constraint worker_department_id_fkey
foreign key (department_id) references department(id);


select name,
    case position
        when 'teacher' then 1
        when 'manager' then 0
        else 2
    end as result
from worker;

select id,
    avg(salary) over (partition by position ORDER BY id ASC) as avg_salary
from worker;

-- explain analyse
select position, avg(salary) as avg_s
from worker
group by position
having  avg(salary) > 800;





-- create extension dblink;

create procedure show_table(db text, tb text)
returns table
language sql
as return
$$
select ta
$$;


select * from worker;
select * from medicament;
select * from department;


-- COPY Account FROM '/home/ql/5/DB/1/csv/account.csv' DELIMITER ',' CSV HEADER;

-- BEGIN;
-- CREATE TEMP TABLE tmp_1 ON COMMIT DROP
-- AS SELECT * FROM Lesson WITH NO DATA;

-- COPY tmp_1 FROM '/home/ql/5/DB/1/csv/lesson.csv' DELIMITER ',' CSV HEADER;

-- INSERT INTO Lesson
-- SELECT DISTINCT ON (l_day, l_time, l_place) * FROM tmp_1;
-- COMMIT;