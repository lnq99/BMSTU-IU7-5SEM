from py_linq import Enumerable
from psycopg2 import connect
import datetime


# Вариант 4

def cur_exec(cur, query):
    cur.execute(query)
    return cur.fetchall()


def print_(tb):
    for i in tb: print(i)
    print()


def new_event(id_em, e_date, e_day, e_time, e_type):
    return {
        'id_em'  : id_em,
        'e_date' : e_date,
        'e_day'  : e_day,
        'e_time' : e_time,
        'e_type' : e_type
    }

def new_employee(id, fio, birthday, department):
    return {
        'id'  : id,
        'fio' : fio,
        'birthday'  : birthday,
        'department' : department
    }


def main1(conn):
    # 1. Найти сотрудников, опоздавших сегодня меньше чем на 5 минут
    q1 = '''
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
    '''

    # 2. Найти сотрудников, которые выходили больше чем на 10 минут
    q2 = '''
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
    '''

    # 3. Найти сотрудников бухгалтерии, приходящих на работу раньше 8:00
    q3 = '''
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
    '''

    print('1.1')
    with conn.cursor() as cur:
        print_(cur_exec(cur, q1))

    print('1.2')
    with conn.cursor() as cur:
        print_(cur_exec(cur, q2))

    print('1.3')
    with conn.cursor() as cur:
        print_(cur_exec(cur, q3))



def main2(conn):
    cur = conn.cursor()
    events = cur_exec(cur, 'select * from events')
    employees = cur_exec(cur, 'select * from employees')
    cur.close()
    
    events = Enumerable([new_event(*i) for i in events])
    employees = Enumerable([new_employee(*i) for i in employees])

    # print_(events)
    # print_(employees)

    # 1. Найти сотрудников, опоздавших сегодня меньше чем на 5 минут
    t1 = (events.where(lambda x: x['e_type'] == 1)
                .group_by(['id_em', 'e_date'], lambda x: (x['id_em'], str(x['e_date'])))
                .select(lambda g: {'id_em': g.key.id_em, 'e_date': g.first()['e_date'], 'min': g.min(lambda x: x['e_time'])})
    )

    t2 = (t1.where(lambda x: x['min'] > datetime.time(9,0) and x['min'] < datetime.time(9,5)
                and x['e_date'] == datetime.datetime.today().date())
            .select(lambda x: x['id_em'])
    )

    q1 = (employees.where(lambda x: x['id'] in t2)
                    .select(lambda x: (x['id'], x['fio']))
    )

    print('2.1')
    print_(q1)


    # 2. Найти сотрудников, которые выходили больше чем на 10 минут

    # читайте коментарий пожалуйста

    # t0 = (events.order_by(lambda x: (x['id_em'], x['e_date'])))
    # l = len(t0)
    # for i in range(0, l-1, 1):
    #     if t0[i]['id_em'] == t0[i+1]['id_em']:
    #         if t0[i]['e_type'] == 2:
    #             t0[i]['diff'] = t0[i+1]['e_time'] - t0[i]['e_time']
    #         else:
    #             t0[i]['diff'] = 0
    #     else:
    #         if t0[i]['e_type'] == 2:
    #             t0[i]['diff'] = datetime.time(17) - t0[i]['e_time']
    # print_(t0)

    t1 = (events.group_by(['id_em', 'e_date'], lambda x: (x['id_em'], str(x['e_date'])))
                .select(lambda g: {'id_em': g.key.id_em, 'e_type': g.first()['e_type'], 'out_time': g.min(lambda x: x['e_time'])})
    )



    t2 = (t1.where(lambda x: x['e_type'] == 2 and x['out_time'] > datetime.timedelta(minutes=10))
            .select(lambda x: x['id_em'])
    )

    q2 = (employees.where(lambda x: x['id'] in t2)
                    .select(lambda x: (x['id'], x['fio']))
    )

    print('2.2')
    print_(q2)


    # 3. Найти сотрудников бухгалтерии, приходящих на работу раньше 8:00
    t1 = (events.where(lambda x: x['e_type'] == 1)
                .group_by(['id_em', 'e_date'], lambda x: (x['id_em'], str(x['e_date'])))
                .select(lambda g: {'id_em': g.key.id_em, 'e_date': g.first()['e_date'], 'min': g.min(lambda x: x['e_time'])})
    )

    t2 = (t1.where(lambda x: x['min'] < datetime.time(8,0))
            .select(lambda x: x['id_em'])
    )

    q3 = (employees.where(lambda x: x['id'] in t2 and x['department'] == 'Бухгалтерия')
                    .select(lambda x: (x['id'], x['fio']))
    )

    print('2.3')
    print_(q3)



if __name__ == "__main__":
    dbinfo = {
        'database':'rk3',
        'user':'postgres',
        'password':'pg123',
        'host':'localhost',
        'port':'5432'
    }

    with connect(**dbinfo) as conn:
        main1(conn)
        main2(conn)
