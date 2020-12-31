import pandas as pd
import json

# 1. Чтение из XML/JSON документа.
# 2. Обновление XML/JSON документа.
# 3. Запись (Добавление) в XML/JSON документ.


def fetch_table(conn, format='dict', table='account', n=6):
    query = f'select * from {table} limit {n}'
    records = []

    if format == 'tuple':
        with conn.cursor() as cur:
            cur.execute(query)
            records = cur.fetchall()
    else:
        records = pd.read_sql(query, conn)
        if format == 'dict':
            records = records.to_dict(orient='records')
        elif format == 'json':
            records = records.to_json(orient='records', date_format='iso', indent=0)

    return records


def to_str(records, indent=2):
    return json.dumps(records, indent=indent, default=str)


def read_json(records, filter_func=lambda x: True, map_func=lambda x: x):
    result = filter_map(records, filter_func, map_func)
    for i in result:
        print(i)


def update_json(records, update_func, filter_func=None):
    row = records
    if filter_func:
        row = filter(filter_func, row)
    for i in row:
        update_func(i)


def add_json(records, r):
    records.append(r)


def write_json(records, file, indent=2):
    with open(file, 'w') as f:
        f.write(to_str(records, indent))


# select where
def filter_map(self, ff, fm):
    for i in self:
        if ff(i):
            yield fm(i)


def main(conn):
    records = fetch_table(conn)
    # records = json.loads(records)


    read_json(records,
        lambda x: x['last_name'].startswith('М'),
        lambda x: f"{x['last_name']} {x['first_name'][0]}. {x['mid_name'][0]}."
    )


    def update_attr(obj, attr, val):
        obj[attr] = val

    update_json(records,
        lambda x: update_attr(x, 'phone', '0000000000'),
        lambda x: x['account_id'] > 5
    )

    add_json(records, {
        'account_id': 21,
        'first_name': 'Юлий',
        'mid_name': 'Васильевич',
        'last_name': 'Дементьев',
        'gender': 'M',
        'birthday': '1985-04-15',
        'a_role': 'teacher',
        'email': 'mokeermakov@rao.info',
        'phone': '80943007344',
        'salt': '!0*VRn%8',
        'hash': '989abffea9c7fdf21d2a449b360b30d52d299df6'
    })


    print(to_str(records, 4))
    # write_json(records, 'tmp.json')

