import psycopg2
import os
from func import *


def usage():
    print('''
========================================
0.  Exit
1.  Выполнить скалярный запрос
2.  Выполнить запрос с несколькими соединениями (JOIN)
3.  Выполнить запрос с ОТВ(CTE) и оконными функциями
4.  Выполнить запрос к метаданным
5.  Вызвать скалярную функцию (3)
6.  Вызвать многооператорную или табличную функцию (3)
7.  Вызвать хранимую процедуру (3)
8.  Вызвать системную функцию или процедуру
9.  Создать таблицу в базе данных, соответствующую тематике БД
10. Выполнить вставку данных в созданную таблицу с использованием инструкции INSERT или COPY
========================================''')


def main_loop(conn):
    fs = FunctionStore(conn)
    fs.add('1', f1).add('2', f2).add('3', f3).add('4', f4).add('5', f5)
    fs.add('6', f6).add('7', f7).add('8', f8).add('9', f9).add('10', f10)

    choice = 1
    while (choice and choice != '0'):
        usage()
        choice = input('Input: ').strip()
        os.system('clear')
        print()
        fs.exec(choice)


#========================================
if __name__ == '__main__':
    with psycopg2.connect(
        database='university',
        user='postgres',
        password='pg123',
        host='localhost',
        port='5432'
    ) as conn:
        main_loop(conn)
