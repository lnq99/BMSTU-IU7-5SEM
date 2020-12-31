from model import *

# 1. Однотабличный запрос на выборку.
# 2. Многотабличный запрос на выборку.
# 3. Три запроса на добавление, изменение и удаление данных в базе данных.
# 4. Получение доступа к данным, выполняя только хранимую процедуру.



def print_records(records):
    for i in records.tuples():
        print(*i, sep='\t')
    print()


def print_table(t, n=5):
    print(f'==== {t.__name__} ====')
    t = t.select().limit(n)
    print_records(t)


def print_all():
    for t in (Account, Student, Teacher, Course, Lesson, StudentCourse):
        print_table(t)


def main():
    # print_all()

    print_records(
        Student.select(Student.s_group, fn.Count(Student).alias('count'))
                .group_by(Student.s_group)
                .order_by(Student.s_group)
                .limit(10))


    print_records(
        Course.select(StudentCourse, Course.course_name)
                .join(StudentCourse)
                .where(StudentCourse.score.between(71,84))
                .limit(10))


    (StudentCourse.insert_many([
                    {'student_id':1, 'course_id':1, 'score':0},
                    {'student_id':1, 'course_id':3, 'score':20}
                ])
                .on_conflict(
                    conflict_target=('student_id', 'course_id'),
                    update={StudentCourse.score: 100})
                .execute())

    (StudentCourse.update(score=50)
                .where((StudentCourse.student_id==1) & (StudentCourse.course_id==1))
                .execute())

    (StudentCourse.delete()
                .where((StudentCourse.student_id==1) & (StudentCourse.course_id==2))
                .execute())


    db.execute_sql('call enrol_course(1,4)')


    print_records(StudentCourse.select().where(StudentCourse.student_id==1))

