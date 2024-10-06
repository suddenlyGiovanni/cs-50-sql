from cs50 import SQL

password = input("Enter a password: ")

db = SQL("sqlite:///dont-panic.db")

db.execute(
    """
    UPDATE  main.users
    SET  password = ?
    WHERE username = 'admin';
    """,
    password
)
