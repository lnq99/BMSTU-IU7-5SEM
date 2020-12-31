from psycopg2 import connect
import pandas as pd
import json
import datetime
import time


def record_mod(r):
    r['phone'] = str(int(r['phone']))
    r['birthday'] = str(r['birthday'])


def fetch_table(conn, table='account', offset=0, limit=5):
    query = f'select * from {table} limit {limit} offset {offset}'
    records = []

    records = pd.read_sql(query, conn)
    records = records.to_dict(orient='records')
    for i in records:
        record_mod(i)
    return records


def write_json(records, file, indent=2):
    with open(file, 'w') as f:
        s = json.dumps(records, indent=indent, default=str)
        f.write(s)


def gen_json(records, id, tbname):
    t = datetime.datetime.now()
    file = f'data/in/{id}_{tbname}_{t}.json'
    write_json(records, file)


def main(conn):
    for i in range(3):
        account = fetch_table(conn, 'account', i*5, 5)
        gen_json(account, i, 'account')
        time.sleep(10)



if __name__ == "__main__":
    dbinfo = {
        'database':'university',
        'user':'postgres',
        'password':'pg123',
        'host':'localhost',
        'port':'5432'
    }

    with connect(**dbinfo) as conn:
        main(conn)


# Разработать подход к логированию загруженных файлов.
