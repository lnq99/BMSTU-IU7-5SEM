create language plpython3u;
select * from pg_language;


-- 1) Определяемую пользователем скалярную функцию
create or replace function student_name(id int)
returns text
as $$
    student = plpy.execute('select * from student')
    account = plpy.execute('select account_id, first_name, mid_name, last_name from account')

    account_id = -1

    for i in student:
        if i['student_id'] == id:
            account_id = i['account_id']

    if account_id == -1:
        return 'Not found!'

    for i in account:
        if i['account_id'] == account_id:
            return '{} {} {}'.format(i['last_name'], i['first_name'], i['mid_name'])
$$ language plpython3u;


select student_name(5);
drop function student_name;



-- 2) Пользовательскую агрегатную функцию
create or replace function pymax(x int[])
returns int
as $$
    m = x[0]
    for i in x:
        if i > m:
            m = i
    return m
$$ language plpython3u;

select pymax(array[1, 2, 5, 3, -6]);
drop function pymax;



-- 3) Определяемую пользователем табличную функцию
create or replace function timetable(st_id int)
returns table (
    l_day       day_t,
    l_time      int,
    l_place     int,
    l_type      char(3),
    course_id   int
)
as $$
    studentcourse = plpy.execute('select * from studentcourse')
    lesson = plpy.execute('select * from lesson')

    co_id = set()
    res = []

    for i in studentcourse:
        if i['student_id'] == st_id:
            co_id.add(i['course_id'])

    for i in lesson:
        if i['course_id'] in co_id:
            res.append((i['l_day'], i['l_time'], i['l_place'], i['l_type'], i['course_id']))

    return res
$$
language plpython3u;

explain analyse
select * from timetable(200);



-- 4) Хранимую процедуру
create or replace procedure enrol_course(st_id int, co_id int)
as $$
    course = plpy.execute('select course_id from course where course_id = {} limit 1'.format(co_id))
    student = plpy.execute('select student_id from student where student_id = {} limit 1'.format(st_id))

    query = 'insert into studentcourse values ({}, {}, 0) on conflict do nothing'.format(st_id, co_id)

    if course.nrows() and student.nrows():
        plpy.execute(query)
$$
language plpython3u;
call enrol_course(1, 1);

select * from studentcourse where student_id = 1;
delete from studentcourse where student_id = 1 and course_id in (1, 2);



-- 5) Триггер
create or replace function check_automat()
returns trigger
as $$
    n = TD['new']
    plpy.info(n)
    query = """
            update studentcourse
            set note = Null
            where student_id = {}
            and course_id = {};
        """.format(n['student_id'], n['course_id'])
    if n['score'] >= 67:
        query = query.replace('Null', "'автомат'")
    plpy.execute(query)
$$
language plpython3u;

create trigger studentcousre_score_update
after update of score
on studentcourse
for each row
execute function check_automat();

drop trigger studentcousre_score_update on studentcourse;

select * from studentcourse where student_id = 1;
insert into studentcourse values (1, 1);
update studentcourse set score = 67 where student_id = 1 and course_id = 1;
delete from studentcourse where student_id = 1 and course_id in (1, 2);



-- 6) Определяемый пользователем тип данных
create type password_t as (
    hash    char(40),
    salt    char(8)
)

drop type if exists password_t;

create or replace function create_password(pw text)
returns password_t
as $$
    import random
    import string
    import hashlib

    salt = ''.join(random.choices(string.printable, k=8))

    hash = hashlib.sha1((pw + salt).encode('utf-8')).hexdigest()

    return (hash, salt)
$$
language plpython3u;


drop function create_password;

select create_password('pass123');



/*
Reference + Useful link
https://stackoverflow.com/questions/30781161/what-does-plpy-noticemsg-do
https://gist.github.com/rturowicz/5232050
https://www.postgresql.org/docs/current/plpython-trigger.html
*/
