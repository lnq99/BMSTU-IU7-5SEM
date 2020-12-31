drop table if exists events;
drop table if exists employees;


create table events
(
    id_em   int,
    e_date  date,
    e_day   varchar(3),
    e_time  time,
    e_type  int,
    primary key (id_em, e_date, e_time)
);

create table employees
(
    id      serial  primary key,
    fio     text,
    birthday    date,
    department  text
);


insert into events
values
    (1, '14-12-2018', 'sat', '9:00', 1),
    (1, '14-12-2018', 'sat', '9:20', 2),
    (1, '14-12-2018', 'sat', '9:25', 1),
    (2, '14-12-2018', 'sat', '9:05', 1)
on conflict do nothing;


insert into employees
(fio, birthday, department)
values
    ('Иванов Иван Иванович', '25-09-199d7', 'Бухгалтерия');


select * from events;
select * from employees;


create or replace function not_go_to_work(d date)
returns table (fio text, department text)
as
$$
select fio, department
from employees
where id not in (
    select distinct id_em
    from events
    where e_date = d and e_type = 1
)
$$
language sql;

select * from not_go_to_work('14-12-2018');
select * from not_go_to_work('12-12-2018');


-- 1. Найти сотрудников, опоздавших сегодня меньше чем на 5 минут
select id, fio
from employees
where id in (
    select id_em
    from (
        select id_em, e_date, min(e_time)
        from events
        where e_type = 1
        group by id_em, e_date
    ) as t1
    where min > '9:00' and min < '9:05'
    and e_date = current_date
);


-- 2. Найти сотрудников, которые выходили больше чем на 10 минут
select id, fio
from employees
where id in (
    select id_em
    from (
        select id_em, e_type,
            lead(e_time, 1, '17:00') over (partition by id_em, e_date order by e_time) - e_time as out_time
        from events
    ) as t1
    where e_type = 2 and out_time > '0:10'
);


-- 3. Найти сотрудников бухгалтерии, приходящих на работу раньше 8:00
select id, fio
from employees
where department = 'Бухгалтерия' and
id in (
    select id_em
    from (
        select id_em, e_date, min(e_time)
        from events
        where e_type = 1
        group by id_em, e_date
    ) as t1
    where min < '8:00'
);