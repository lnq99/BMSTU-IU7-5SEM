import pandas as pd

pd.set_option('display.max_rows', 20)
pd.set_option('display.max_columns', 10)
pd.set_option('display.max_colwidth', 100)
pd.set_option('display.width', 150)


class FunctionStore:
    def __init__(self, conn):
        self.data = {}
        self.conn = conn

    def add(self, func_name, func):
        if func_name in self.data:
            print('Replace function', func_name)
        self.data[func_name] = func
        return self

    def exec(self, func_name, *args):
        if func_name in self.data:
            self.data[func_name](self.conn, *args)
        elif func_name != '0':
            print('Invalid input!')


def read_sql(func):
    def new_func(conn, *args):
        print(pd.read_sql(func(conn, *args), conn))
    return new_func


# 1. Выполнить скалярный запрос
@read_sql
def f1(conn, student_id = 10):
    return f'''
    select avg(score)
    from studentcourse
    where student_id = {student_id};
    '''


# 2. Выполнить запрос с несколькими соединениями (JOIN)
@read_sql
def f2(conn, group_name='ИУ1'):
    return f'''
    select student.student_id, min(score), max(score), avg(score)
    from student join studentcourse on student.student_id = studentcourse.student_id
    where student.s_group = '{group_name}'
    group by student.student_id;
    '''


# 3. Выполнить запрос с ОТВ(CTE) и оконными функциями
@read_sql
def f3(conn, teacher_id=40):
    return f'''
    with courses
    as (
        select course_id from course
        where course.teacher_id = {teacher_id}
    )
    select lesson.*,
        min(l_time) over(partition by l_day) as min_time,
        max(l_time) over(partition by l_day) as max_time
    from lesson join courses on lesson.course_id = courses.course_id;
    '''


# 4. Выполнить запрос к метаданным
@read_sql
def f4(conn, pattern='jsonb\_%'):
    return f'''
    select routine_name, parameters.data_type, ordinal_position
    from information_schema.routines
    join information_schema.parameters
    on routines.specific_name = parameters.specific_name
    where routine_name like '{pattern}'
    order by routines.specific_name, ordinal_position;
    '''


# 5. Вызвать скалярную функцию (3)
@read_sql
def f5(conn, student_id = 10):
    return f'''
    select student_name({student_id});
    '''


# 6. Вызвать многооператорную или табличную функцию (3)
@read_sql
def f6(conn, student_id = 10):
    return f'''
    select * from timetable({student_id});
    '''


# 7. Вызвать хранимую процедуру (3)
def f7(conn, course_id=10):
    return f'''
    call add_score({course_id});
    '''


# 8. Вызвать системную функцию или процедуру
@read_sql
def f8(conn):
    return '''
    select current(), current_database(), pg_database_size(current_database());
    '''


# 9. Создать таблицу в базе данных, соответствующую тематике БД
@read_sql
def f9(conn):
    return '''
    drop table if exists teacher_list_course;
    create table teacher_list_course(
        teacher_id int primary key,
        courses jsonb
    );
    select * from teacher_list_course;
    '''


# 10. Выполнить вставку данных в созданную таблицу с использованием инструкции INSERT или COPY
@read_sql
def f10(conn):
    return '''
    insert into teacher_list_course
    select teacher_id, (
        select coalesce(jsonb_agg(r), '[]'::jsonb)
        from (
            select * from course
            where course.teacher_id = teacher.teacher_id
        ) as r
    ) as courses
    from teacher
    on conflict do nothing;
    select * from teacher_list_course;
    '''




# Useful link
'''
https://www.python.org/dev/peps/pep-0318/
'''

'''
select student_id,
    (select count(score) from studentcourse where studentcourse.student_id = student.student_id),
    (select avg(score) from studentcourse where studentcourse.student_id = student.student_id)
from student
'''