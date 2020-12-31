from peewee import *


db = PostgresqlDatabase(
    None,
    field_types={'gender_t':'gender_t', 'day_t':'day_t', 'role_t':'role_t'}
)


class BaseModel(Model):
    class Meta:
        database = db

class GenderField(Field):
    field_type = 'gender_t'

class DayField(Field):
    field_type = 'day_t'

class RoleField(Field):
    field_type = 'role_t'


class Account(BaseModel):
    account_id = AutoField()
    first_name = FixedCharField(16)
    mid_name = FixedCharField(16, null=True)
    last_name = FixedCharField(16)
    gender = GenderField()
    birthday = DateField(null=True)
    a_role = RoleField()
    email = TextField()
    phone = DecimalField(null=True)
    salt = FixedCharField(8)
    hash = FixedCharField(40)

    @property
    def name(self):
        return f'{self.last_name} {self.first_name[0]} {self.mid_name[0]}'

    def __str__(self):
        email = '{:30s}'.format(self.email)
        return f'{self.account_id}\t{self.name}\t{self.gender}\t{email}\t'\
            f'{self.birthday}\t{self.a_role}\t {self.phone}\t{repr(self.salt)}\t{self.hash}'


class Student(BaseModel):
    student_id = AutoField()
    s_group = FixedCharField(5)
    account = ForeignKeyField(Account, 'account_id')

    def __str__(self):
        return f'{self.student_id}\t{self.account.account_id}\t{self.s_group}'


class Teacher(BaseModel):
    teacher_id = AutoField()
    t_position = FixedCharField(22)
    account = ForeignKeyField(Account, 'account_id')

    def __str__(self):
        return f'{self.teacher_id}\t{self.account.account_id}\t{self.t_position}'


class Course(BaseModel):
    course_id = AutoField()
    course_name = FixedCharField(22)
    teacher = ForeignKeyField(Teacher, 'teacher_id')

    def __str__(self):
        return f'{self.course_id}\t{self.teacher.teacher_id}\t{self.course_name}'


class Lesson(BaseModel):
    l_day = DayField()
    l_time = IntegerField()
    l_place = IntegerField()
    l_type = FixedCharField(3)
    course = ForeignKeyField(Course, 'course_id')

    class Meta:
        primary_key = CompositeKey('l_day', 'l_time', 'l_place')

    def __str__(self):
        return f'{self.l_day} {self.l_time} {self.l_place} {self.l_type} {self.course.course_id}'


class StudentCourse(BaseModel):
    student_id = ForeignKeyField(Student, 'student_id')
    course_id = ForeignKeyField(Course, 'course_id')
    score = IntegerField()
    note = TextField()

    class Meta:
        primary_key = CompositeKey('student_id', 'course_id')

    def __str__(self):
        return f'{self.student.student_id}\t{self.course.course_id}\t{self.score}\t{self.note}'
