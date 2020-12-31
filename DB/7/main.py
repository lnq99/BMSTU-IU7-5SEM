import sys


if __name__ == '__main__':

    args = sys.argv[1:]

    dbinfo = {
        'database':'university',
        'user':'postgres',
        'password':'pg123',
        'host':'localhost',
        'port':'5432'
    }


    if not args or args[0] == '1':
        from to_obj import main
        main()

    elif args[0] == '2':
        from to_json import main
        from psycopg2 import connect
        with connect(**dbinfo) as conn:
            main(conn)

    elif args[0] == '3':
        from to_sql import db, main
        db.init(**dbinfo)
        main()
        db.close()


'''
https://viralogic.github.io/py-enumerable/
https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/linq/standard-query-operators-overview
'''
