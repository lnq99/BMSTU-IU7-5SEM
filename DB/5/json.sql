-- 1. Из таблиц базы данных, созданной в первой лабораторной работе,
-- извлечь данные в XML (MSSQL) или JSON(Oracle, Postgres).
-- Для выгрузки в XML проверить все режимы конструкции FOR XML
select to_json(account)
from account
limit 100;

copy (select to_json(account) from account)
to '/home/ql/csv/account.json';



-- 2. Выполнить загрузку и сохранение XML или JSON файла в таблицу.
-- Созданная таблица после всех манипуляций должна соответствовать
-- таблице базы данных, созданной в первой лабораторной работе.
create table tmp(r json);
copy tmp from '/home/ql/csv/account.json';

create table tmp_account as
select (json_populate_record(null::account, r)).*
from tmp;

select * from tmp_account;

drop table tmp_account;
drop table tmp;



-- 3. Создать таблицу, в которой будет атрибут(-ы) с типом XML или JSON,
-- или добавить атрибут с типом XML или JSON к уже существующей таблице.
-- Заполнить атрибут правдоподобными данными с помощью команд INSERT или UPDATE.
create table tmp_teacher
as select * from teacher;

alter table tmp_teacher
add column ext jsonb;


update tmp_teacher
set ext = (
    select json_build_object('account', to_json(account))
    from account
    where account.account_id = tmp_teacher.account_id
);

update tmp_teacher
set ext = jsonb_set(
    ext,
    '{courses}',
    (select coalesce(jsonb_agg(r), '[]'::jsonb) from (
        select * from course
        where course.teacher_id = tmp_teacher.teacher_id
    ) as r)
);

select * from tmp_teacher;

drop table tmp_teacher;



-- 4.
-- 4.1. Извлечь XML/JSON фрагмент из XML/JSON документа
select ext->'account' from tmp_teacher;

-- 4.2. Извлечь значения конкретных узлов или атрибутов XML/JSON документа
select ext->'account'->'phone' from tmp_teacher;

-- 4.3. Выполнить проверку существования узла или атрибута
select ext->'courses' from tmp_teacher
where ext->'courses'->0 is not null;

-- 4.4. Изменить XML/JSON документ
update tmp_teacher
set ext = jsonb_set(
    ext,
    '{account,phone}',
    '"0000000000"'
)
where teacher_id = 1;

-- 4.5. Разделить XML/JSON документ на несколько строк по узлам
select (jsonb_each(ext->'account')).*
from tmp_teacher
where teacher_id = 1;



/*
References
https://www.postgresql.org/docs/devel/functions-json.html
https://www.youtube.com/watch?v=tMT16q9pqp0&ab_channel=PostgresOpen
*/

select routine_name, parameters.data_type, ordinal_position
from information_schema.routines
join information_schema.parameters
on routines.specific_name = parameters.specific_name
-- where routines.specific_schema='public'
where routine_name like 'json\_%'
order by routines.specific_name, ordinal_position;
