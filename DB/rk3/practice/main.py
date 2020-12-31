import psycopg2
import datetime
from py_linq import Enumerable

'''
Разработать приложение, выполняющее запросы к БД.
Запросы реализовать в виде SQL команд (Обработка на уровне БД)
и лямбда-выражений (Обработка на уровне приложения):
- Найти отделы, в которых хоть один сотрудник опаздывает больше 3-х раз в неделю.
- Найти средний возраст сотрудников, не находящихся на рабочем месте 8 часов в день.
- Вывести все отделы и количество сотрудников хоть раз опоздавших за всю историю учета.
'''

class Event:
    def __init__(self, id_em, date, day, time, e_type):
        self.id_em = id_em
        self.date = date
        self.day = day
        self.time = time
        self.type = e_type

    def __str__(self):
        return f'{self.id_em}\t{self.date}\t{self.time}\t{self.type}'


class Employee:
    def __init__(self, id, fio, birthday, department):
        self.id = id
        self.fio = fio
        self.birthday = birthday
        self.department = department

    def __str__(self):
        return f'{self.id}\t{self.fio}\t{self.birthday}\t{self.department}'



def cur_exec(cur, query):
    cur.execute(query)
    return cur.fetchall()


def print_(tb):
    for i in tb: print(i)
    print()


def main1(conn):
    q1 = '''
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
    '''

    q2 = '''
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
    '''

    q3 = '''
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
    group by department
    '''

    with conn.cursor() as cur:
        print_(cur_exec(cur, q1))

    with conn.cursor() as cur:
        print_(cur_exec(cur, q2))

    with conn.cursor() as cur:
        print_(cur_exec(cur, q3))


def main2(conn):
    cur = conn.cursor()
    events = cur_exec(cur, 'select * from events')
    employees = cur_exec(cur, 'select * from employees')
    cur.close()

    events = Enumerable([Event(*i) for i in events])
    employees = Enumerable([Employee(*i) for i in employees])

    print_(events)
    print_(employees)

    t1 = (events.where(lambda x: x.type == 1)
                .group_by(key_names=['id_em', 'date'], key=lambda x: (x.id_em, str(x.date)))
                .select(lambda g: {'id_em':g.key.id_em, 'date':g.first().date, 'min':g.min(lambda x: x.time)})
    )

    t2 = (t1.where(lambda x: x['min'] > datetime.time(9,0))
            .group_by(key_names=['id_em', 'week'], key=lambda x: (x['id_em'], x['date'].isocalendar()[1]))
            .select(lambda g: {'id_em':g.key.id_em, 'week':g.key.week, 'count':g.count()})
            .distinct(lambda x: x['id_em'])
    )

    q1 = (t2.where(lambda x: x['count'] > 1)
            .join(employees, lambda x: x['id_em'], lambda x: x.id,
                lambda g: {'department':g[1].department})
            .select()
    
    )

    print_(q1)



if __name__ == '__main__':
    dbinfo = {
        'database':'rk3',
        'user':'postgres',
        'password':'pg123',
        'host':'localhost',
        'port':'5432'
    }

    with psycopg2.connect(**dbinfo) as conn:
        main1(conn)
        main2(conn)