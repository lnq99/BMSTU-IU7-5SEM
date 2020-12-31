from py_linq import Enumerable
from functools import reduce
from datetime import date
import random
import string
import hashlib


def print_all(self):
    if not len(self): return 'empty...\n'
    return reduce(lambda x, y: f'{x}\n{y}', self, '') + '\n'

Enumerable.__str__ = print_all
Enumerable.print = lambda self: print(self)


class Account:
    id = 0
    def __init__(self, first, mid, last, gender, birthday, email, password, phone=None, role='student'):
        Account.id += 1
        self.id = Account.id
        self.first = first
        self.mid = last
        self.last = mid
        self.gender = gender
        self.birthday = birthday
        self.role = role
        self.email = email
        self.phone = phone
        self._gen_password(password)

    def _gen_password(self, s):
        self.salt = ''.join(random.choices(string.printable, k=8))
        self.hash = hashlib.sha1((s + self.salt).encode('utf-8')).hexdigest()

    @property
    def name(self):
        return f'{self.last} {self.first[0]} {self.mid[0]}'

    def __str__(self):
        return f'{self.id}\t{self.name}\t{self.gender}\t{self.email}\t'\
            f'{self.birthday}\t{self.role}\t {self.phone}\t{repr(self.salt)}\t{self.hash}'


class Student:
    id = 0
    def __init__(self, group, acc_id):
        Student.id += 1
        self.id = Student.id
        self.group = group
        self.account_id = acc_id

    def __str__(self):
        return f'{self.id}\t{self.group}\t{self.account_id}'


def main():
    accounts = Enumerable([
        Account('Наина','Игоревна','Якушева','F',date(2000,7,10),'ikolesnikova@gmail.info','pass1','80688838213'),
        Account('Кира','Петровна','Анисимова','F',date(1997,11,16),'viktor_2018@gmail.com','pass2','88532665353'),
        Account('Алина','Робертовна','Горбунова','F',date(1994,4,26),'tsvetkov@hotmail.com','pass3','80354499579'),
        Account('Арефий','Гордеевич','Морозов','M',date(1993,10,22),'bogdan_22@oao.com','pass4','88472345586'),
        Account('Сидор','Харлампович','Петров','M',date(1999,3,25),'drozdovdanila@ao.net','pass5','85427200819')
    ])

    students = Enumerable([
        Student('ИУ7',1),
        Student('ИУ7',2),
        Student('ИУ6',3),
        Student('ИУ7',4),
        Student('ИУ6',5),
    ])

    # print(accounts.select())
    # print(students.select())
    # print('===============')


    accounts.where(lambda x: x.gender == 'F')\
            .select(lambda x: x.name + '\t' + x.email)\
            .print()


    accounts.where(lambda x: x.birthday.year > 1995)\
            .order_by_descending(lambda x: x.birthday)\
            .select(lambda x: x.name + '\t' + str(x.birthday))\
            .print()


    print(students.any(lambda x: x.group == 'ИУ1'))
    students.where(lambda x: x.group == 'ИУ1')\
            .select()\
            .print()


    accounts.group_by(key_names=['gender'], key=lambda x: x.gender)\
            .select(lambda g: {'key':g.key.gender, 'count':g.count()})\
            .print()


    students.where(lambda x: x.group == 'ИУ7')\
            .join(accounts, lambda s: s.id, lambda a: a.id,
                lambda g: f'{str(g[0])}\t{g[1].name}\t{g[1].email}')\
            .print()
