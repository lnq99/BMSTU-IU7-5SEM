drop table if exists events;

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
    id  serial  primary key,
    fio text,
    birthday    date,
    department  text
);


insert into events
values
    (1, '14-12-2018', 'sat', '9:00', 1),
    (1, '14-12-2018', 'sat', '9:20', 2),
    (1, '14-12-2018', 'sat', '9:25', 1),
    (2, '14-12-2018', 'sat', '9:05', 1),
    (2, '12-12-2018', 'sat', '9:10', 1),
    (2, '15-11-2018', 'sat', '9:05', 1),
    (2, '14-11-2018', 'sat', '8:55', 1),
    (2, '14-11-2018', 'sat', '9:25', 2),
    (2, '14-11-2018', 'sat', '9:50', 1),
    (2, '14-11-2017', 'sat', '9:05', 1),
    (2, '14-11-2017', 'sat', '9:15', 2),
    (2, '14-11-2017', 'sat', '10:15', 1)
on conflict do nothing;


insert into employees
(fio, birthday, department)
values
    ('Иванов Иван Иванович', '25-09-1990', 'ИТ'),
    ('Петров Петр Петрович', '12-11-1987', 'ИТ');


create or replace function n_late(d date, t time default '9:00')
returns bigint
as
$$
select count(*) from (
    select min(e_time)
    from events
    where e_date = d and e_type = 1
    group by id_em, e_date
) as events_min_time
where min > t
$$
language sql;

select n_late('14-12-2018');

drop function n_late;




select distinct department
from (
    select id_em, e_week, count(*)
    from (
        select id_em, e_date, min(e_time), date_part('week', e_date) as e_week
        from events
        where e_type = 1
        group by id_em, e_date
    ) as t1
    where min > '9:00'
    group by id_em, e_week
) as t2
join employees on t2.id_em = employees.id and t2.count > 3;


select date_part('year', avg(age))
from (
    select age(birthday)
    from employees
    where id in (
        select distinct id_em
        from (
            select id_em, e_date, sum(working_time) as working_time
            from (
                select id_em, e_date, e_type,
                    case e_type
                    when 1 then lead(e_time, 1, '17:00') over (partition by id_em, e_date order by e_time) - e_time
                    when 2 then '0'
                    end as working_time
                from events
            ) as t1
            group by id_em, e_date
        ) as t2
        where working_time < '8:00'
    )
) as t3;


select department, count(*)
from (
    select distinct id_em
    from (
        select id_em, e_date, min(e_time)
        from events
        where e_type = 1
        group by id_em, e_date
    ) as t1
    where min > '9:00'
) as t2
join employees on t2.id_em = employees.id
group by department;