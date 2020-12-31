-- Ле Ни Куанг
-- 2. Вариант 4

\c postgres;
drop database if exists rk2;
create database rk2;
\c rk2;
\! clear


create table region (
    id              serial primary key,
    name            varchar(20) unique,
    describle       text
);

create table sanatorium (
    id              serial primary key,
    region_name     varchar(8) references region(name),
    year            numeric(4),
    describle       text
);

create table vacationer (
    id              serial primary key,
    fio             varchar(20) not null,
    birth_year      numeric(4),
    address         text,
    email           text
);

create table sv (
    sanatorium_id   int references sanatorium(id),
    vacationer_id   int references vacationer(id)
);


insert into region
values
    (default, 'Moscow', 'describle 1....'),
    (default, 'region 2', 'describle 2....'),
    (default, 'region 3', 'describle 3....'),
    (default, 'Saint P.', 'describle 4....'),
    (default, 'region 5', 'describle 5....'),
    (default, 'region 6', 'describle 6....'),
    (default, 'region 7', 'describle 7....'),
    (default, 'region 8', 'describle 8....'),
    (default, 'region 9', 'describle 9....'),
    (default, 'region 10', 'describle 10....');


insert into sanatorium
values
    (default, 'region 2', 1980, 'describle sanatorium 1....'),
    (default, 'region 2', 1982, 'describle sanatorium 2....'),
    (default, 'Moscow', 2012, 'describle sanatorium 3....'),
    (default, 'Saint P.', 1990, 'describle sanatorium 4....'),
    (default, 'region 3', 1985, 'describle sanatorium 5....'),
    (default, 'region 6', 2000, 'describle sanatorium 6....'),
    (default, 'region 2', 2014, 'describle sanatorium 7....'),
    (default, 'Saint P.', 1980, 'describle sanatorium 8....'),
    (default, 'region 9', 1995, 'describle sanatorium 9....'),
    (default, 'region 7', 2005, 'describle sanatorium 10....'),
    (default, 'Saint P.', 1989, 'describle sanatorium 11....'),
    (default, 'region 5', 2003, 'describle sanatorium 12....'),
    (default, 'region 7', 2018, 'describle sanatorium 13....');

insert into vacationer
values
    (default, 'name 1', 1980, 'address 1....', 'name1@email.com'),
    (default, 'name 2', 1982, 'address 2....', 'name2@email.com'),
    (default, 'name 3', 2012, 'address 3....', 'name3@email.com'),
    (default, 'name 4', 1990, 'address 4....', 'name4@email.com'),
    (default, 'name 5', 1985, 'address 5....', 'name5@email.com'),
    (default, 'name 6', 2000, 'address 6....', 'name6@email.com'),
    (default, 'name 7', 2014, 'address 7....', 'name7@email.com'),
    (default, 'name 8', 1980, 'address 8....', 'name8@email.com'),
    (default, 'name 9', 1995, 'address 9....', 'name9@email.com'),
    (default, 'name 10' 2005, 'address 10....', 'name10@email.com'),
    (default, 'name 11', 1989, 'address 11....', 'name11@email.com'),
    (default, 'name 12', 2003, 'address 12....', 'name12@email.com');

insert into sv
values
    (1, 3),
    (1, 4),
    (2, 4),
    (1, 8),
    (4, 2),
    (3, 7),
    (6, 8),
    (11, 12),
    (5, 11),
    (8, 10),
    (8, 9);



-- ALTER TABLE Account ADD PRIMARY KEY (account_id);
alter table region add constraint region_sanatorium_id_fkey
foreign key (sanatorium_id) references sanatorium(id);


-- 1) Инструкция SELECT, использующая поисковое выражение CASE
-- статус санаторий
select id, describle,
    case
        when year < 1990 then 'old'
        when year > 2010 then 'new'
        else 'normal'
    end as status
from sanatorium;


-- 2) Инструкция UPDATE со скалярным подзапросом в предложении SET
-- update статус санаторий
update sanatorium
set describle = (
    select
    case
        when year < 1990 then 'old'
        when year > 2010 then 'new'
        else 'normal'
    end as status
    from sanatorium as sa
    where sa.id = sanatorium.id
);

select * from sanatorium;


-- 3) Инструкцию SELECT, консолидирующую данные с помощью
-- предложения GROUP BY и предложения HAVING
-- get name of new regions
select region_name
from sanatorium
group by region_name
having avg(year) > 1990;


-- Задание 3
create function drop_all_view()
returns int
language sql
as return
$$
select 'drop view ' || table_name || ';'
from information_schema.views
where table_schema not in ('pg_catalog', 'information_schema')
and table_name !~ '^pg_';
$$

call drop_all_view();

create procedure drop_views()
language plpgsql
as
$$
declare
    l_rec record;
    l_stmt text;
begin
    for l_rec in (select schemaname, viewname
                    from pg_views,
                    where schemaname = 'rk2')
    loop
        l_stmt := format('drop view if exists %I.%I cascade', l_vrec.schemaname, vrec.viewname);
        execute l_stmt;
    end loop;
end;
$$

call drop_views();



create view rs as
select region.name, sanatorium.describle
from region join sanatorium
on sanatorium.region_name = region.name;

select * from rs;
drop view rs;



select * from region;
select * from vacationer;
select * from sanatorium;

