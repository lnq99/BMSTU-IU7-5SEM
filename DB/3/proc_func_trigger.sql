-- A. Четыре функции
-- 1) Скалярную функцию
-- получить средний балл студента по идентификатору
create or replace function avg_score(id integer)
returns numeric
as
$$
select avg(score)
from studentcourse
where student_id = id
$$
language sql;

select avg_score(20);
select avg_score(10);

drop function avg_score;



-- 2) Подставляемую табличную функцию
-- получить список студентов группы по имени
create or replace function group_list(group_name text)
returns table
(
    id          int,
    first_name  varchar(16),
    mid_name    varchar(16),
    last_name   varchar(16),
    email       text
)
as
$$
select student_id, first_name, mid_name, last_name, email
from student join account
on student.account_id = account.account_id
where s_group = group_name
$$
language sql;

select * from group_list('ИУ1');
drop function group_list(text);



create or replace function timetable(st_id int)
returns table
(
    l_day       day_t,
    l_time      int,
    l_place     int,
    l_type      char(3),
    course_id   int
)
as
$$
select l_day, l_time, l_place, l_type, studentcourse.course_id
from lesson join studentcourse
on lesson.course_id = studentcourse.course_id
where student_id = st_id
$$
language sql;

explain analyse
select * from timetable(200);
drop timetable;



create or replace function group_avg(group_name char(5))
returns table
(
    student_id      int,
    avg_score       numeric
)
as
$$
-- explain
select g.student_id, avg(score) as avg_score
from (select * from student where s_group = group_name) as g
join studentcourse
on g.student_id = studentcourse.student_id
group by g.student_id;

-- explain
-- select g.student_id, avg(score) as avg_score
-- from student as g
-- join studentcourse
-- on g.student_id = studentcourse.student_id
-- where s_group = group_name
-- group by g.student_id;
$$
language sql;

select * from group_avg('ИУ1');
drop function group_avg(varchar);



-- 3) Многооператорную табличную функцию
-- перечислить средний балл студентов в группе
create or replace function group_avg(group_name char(5))
returns table
(
    student_id      int,
    avg_score       numeric
)
as
$$
begin
    execute format('
    create or replace view v_group as
    (
        select g.student_id, avg(score) as avg_score
        from student as g
        join studentcourse
        on g.student_id = studentcourse.student_id
        where s_group = %L
        group by g.student_id
    );', group_name);

    return query (
        -- select g.student_id, avg(score) as avg_score
        -- from (select * from student where s_group = group_name) as g
        -- join studentcourse
        -- on g.student_id = studentcourse.student_id
        -- group by g.student_id
        select * from v_group
    );
end;
$$
language plpgsql;

select * from group_avg('ИУ1');
drop function group_avg(varchar);



-- 4) Рекурсивную функцию или функцию с рекурсивным ОТВ
create table filesystem (f_path text primary key, is_directory boolean default false);
select * from filesystem;
drop table filesystem;

insert into filesystem
values
    ('/', true),
    ('/home', true),
    ('/home/Desktop', true),
    ('/home/Desktop/1.mp3', false),
    ('/home/Desktop/2.mp3', false),
    ('/home/Download', true),
    ('/home/Download/1.txt', false),
    ('/home/Download/2.txt', false),
    ('/etc', true),
    ('/etc/postgresql', true)
on conflict
do nothing;


create or replace function ls(f_base_path text)
returns table (f_path text, f_type char, f_level int)
as
$$
with recursive fs(f_path, is_directory, f_level)
as
(
    (
        select f_path, is_directory, 0 as f_level
        from filesystem as f
        where f_path = f_base_path
    )
    union
    (
        select f.f_path, f.is_directory, f_level + 1
        from
            filesystem as f join fs
            on fs.is_directory and f.f_path similar to fs.f_path || '/?[^/]+'
    )
)
select f_path,
    case is_directory
        when true then 'd'
        else '-'
    end as f_type,
    f_level
from fs
$$
language sql;

select * from ls('/');
select * from ls('/home/Desktop');




-- B. Четыре хранимых процедуры
-- 1) Хранимую процедуру без параметров или с параметрами
-- copy distinct from csv
drop table filesystem;
create table filesystem (f_path text primary key, is_directory boolean default false);


create or replace procedure copy_from_csv (tb text, csv_path text)
as
$$
begin
    execute format('
        create temp table tmp on commit drop
        as select * from %I with no data;
        copy tmp from %L delimiter '','' csv header;
        insert into %1$I
        select distinct on (f_path) * from tmp;',
        tb, csv_path);
end;
$$
language plpgsql;

call copy_from_csv('filesystem', '/home/ql/csv/fs.csv');


copy filesystem from '/home/ql/csv/fs.csv' delimiter ',' csv header;
drop procedure copy_from_csv;
drop table filesystem;



-- 2) Рекурсивную хранимую процедуру или хранимую процедур с рекурсивным ОТВ
-- create table f_result(f_path text, is_directory boolean, f_level int);
-- найти файл по имени файла
create or replace procedure find_result
(dir text, pattern text, depth int default 10, is_base_dir boolean default true)
as
$$
declare
    rec record;
begin
    if (is_base_dir)
    then
        drop table if exists f_result;
        create table f_result(f_path text primary key, is_directory boolean, f_level int);

        insert into f_result
        select f_path, is_directory, 0 as f_level
        from filesystem as f
        where f_path = dir;
    end if;

    insert into f_result
    select f.f_path, f.is_directory, f_level + 1
    from
        filesystem as f join f_result
        on f_result.is_directory and f.f_path similar to f_result.f_path || '/?[^/]+'
    on conflict do nothing;
    
    if (depth > 0)
    then call find_result(dir, pattern, depth-1, false);
    end if;

    if (is_base_dir)
    then
        delete from f_result
        where is_directory or f_path not similar to pattern;
    end if;
end;
$$
language plpgsql;

call find_result('/home', '%.txt');
select * from f_result;

drop table f_result;
drop procedure find_result;



-- 3) Хранимую процедуру с курсором
-- Сессия закрылась, оценить студентов по предметам
alter table studentcourse add column if not exists note text;

create or replace procedure add_score(c_id int)
as
$$
declare cur cursor for
            select score from studentcourse
            where course_id = c_id;
        -- rec record;

begin
    for rec in cur loop
        update studentcourse 
        set note = case
            when score >= 85 then 'Отлично'
            when score >= 71 then 'Хорошо'
            when score >= 60 then 'Удов.'
            else 'Неудов.'
        end
        where current of cur;
    end loop;
end;
$$
language plpgsql;

call add_score(10);

select * from studentcourse
where course_id between 10 and 11;



-- 4) Хранимую процедуру доступа к метаданным
-- показать всю таблицу и информацию о ней
create table result (rec text);

create or replace procedure show_table_info()
as
$$
declare cur cursor for
    select table_catalog, table_schema, table_name, pg_table_size(table_name::text)
    from information_schema.tables
    where table_schema not in ('pg_catalog', 'information_schema')
    and table_type = 'BASE TABLE';

begin
    for rec in cur loop
        insert into result 
        values (rec);
    end loop;
end
$$
language plpgsql;


call show_table_info();
select * from result;
drop table result;


select * from information_schema.columns;
select * from pg_tables;



-- C. Два DML триггера
-- 1) Триггер AFTER
-- Уведомление об изменении адреса электронной почты
create or replace function notice_update()
returns trigger
as
$$
begin
    raise notice '% -> %', old.email, new.email;
    return new;
end;
$$
language plpgsql;

drop function notice_update;


create trigger account_update
after update of email
on account
for each row
execute function notice_update();


select email from account
where account_id = 1;

update account
set email = '123@gmail.com'
where account_id = 1;



-- 2) Триггер INSTEAD OF
-- Вместо удаление информацию о курсе в таблице studentcoure,
-- изменить поле note на deleted
create or replace function change_course_note_deleted()
returns trigger
as
$$
begin
    update studentcourse
    set note = 'deleted'
    where student_id = old.student_id
    and course_id = old.course_id;
    return old;
end;
$$
language plpgsql;

drop function change_course_note_deleted;


create trigger studentcourse_delete
instead of delete
on sc
for each row
execute function change_course_note_deleted();

drop trigger studentcourse_delete
on sc;



create or replace view sc as
select student_id, course_id, score
from studentcourse;

drop view sc;

insert into studentcourse
values (1, 1, 20), (1, 2, 25);


select * from studentcourse
where student_id = 1;

select * from sc
where student_id = 1;

delete from sc
where student_id = 1 and course_id = 615;




-----------------------
create or replace function check_name()
returns trigger
as
$$
begin
    if (new.first_name ~ '.*[0-9\.]+.*' or
        new.last_name ~ '.*[0-9\.]+.*' or
        new.mid_name ~ '.*[0-9\.]+.*' )
    then
        raise exception 'Invalid name!';
    else
        return new;
    end if;
end;
$$
language plpgsql;

create trigger account_insert
before insert on account
for each row
execute function check_name();

insert into account
values
(
    16000,
    'first_0_name',
    'mid_name',
    'last_name',
    'M',
    '1999-09-19',
    'student',
    'email@email.com',
    NULL,
    'C-]xOjiV',
    'e5ba8375fdd5bbb2cd9645b3bd1dd673607603a9'
);

select * from account
where account_id = 16000;
select 'first_0_name' ~ '.*[0-9\.]+.*';


delete from account where account_id = 16000;

drop trigger account_insert on account;


/*
Reference
https://carto.com/help/working-with-data/sql-stored-procedures/
https://www.postgresqltutorial.com/postgresql-plpgsql/
https://www.postgresql.org/docs/current/information-schema.html
https://www.postgresql.org/docs/current/catalogs.html
https://dba.stackexchange.com/questions/194684/in-postgresql-what-is-the-difference-between-a-stored-procedure-and-other-typ
https://dba.stackexchange.com/questions/8119/function-performance/8189#8189

\dt+

ALTER TABLE table_name
ENABLE/DISABLE TRIGGER trigger_name | ALL
*/
