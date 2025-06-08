import psycopg2
import threading
import time


DB_CONFIG = {
    "dbname": "lab1-counter-db", # назва БД
    "user": "user", # користувач
    "password": "password", # пароль
    "host": "localhost",
    "port": 5432
}

THREADS = 10 # Кількість паралельних потоків
ITERATIONS = 10000 # Кількість оновлень в кожному потоці
TOTAL_EXPECTED = THREADS * ITERATIONS  # Очікуване максимальне значення каунтера

def lost_update():
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    for _ in range(ITERATIONS):
        # Поточне значення каунтера
        cursor.execute("SELECT counter FROM user_counter WHERE user_id = 1")
        counter = cursor.fetchone()[0]
        counter += 1 
        # Записує оновлене значення назад
        cursor.execute("UPDATE user_counter SET counter = %s WHERE user_id = 1", (counter,))
        conn.commit()

    cursor.close()
    conn.close()

def in_place_update():
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    for _ in range(ITERATIONS):
        # Оновлює каунтер без попереднього SELECT
        cursor.execute("UPDATE user_counter SET counter = counter + 1 WHERE user_id = 1")
        conn.commit()

    cursor.close()
    conn.close()

def row_level_locking():
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    for _ in range(ITERATIONS):
        # Блокує рядок для читання та оновлення
        cursor.execute("SELECT counter FROM user_counter WHERE user_id = 1 FOR UPDATE")
        counter = cursor.fetchone()[0]
        counter += 1
        # Записує оновлене значення назад
        cursor.execute("UPDATE user_counter SET counter = %s WHERE user_id = 1", (counter,))
        conn.commit()

    cursor.close()
    conn.close()

def optimistic_locking():
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    for _ in range(ITERATIONS):
        while True:
            # Поточне значення каунтера та його версію
            cursor.execute("SELECT counter, version FROM user_counter WHERE user_id = 1")
            counter, version = cursor.fetchone()
            counter += 1
            new_version = version + 1

            # Оновилює рядок, якщо версія не змінилася
            cursor.execute(
                "UPDATE user_counter SET counter = %s, version = %s WHERE user_id = 1 AND version = %s",
                (counter, new_version, version)
            )
            conn.commit()
            # Якщо оновлення відбулося - вихід з циклу
            if cursor.rowcount > 0:
                break

    cursor.close()
    conn.close()

# Функція скидання каунтера і версії 
def reset_counter():
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    # counter=0 та version=0 для user_id=1
    cursor.execute("UPDATE user_counter SET counter = 0, version = 0 WHERE user_id = 1")
    conn.commit()
    cursor.close()
    conn.close()

# Функція запуску тесту. update_func - функції збільшення каунтера
def run_test(update_func):
    reset_counter()
    threads = []
    start_time = time.time()

    for i in range(THREADS):
        t = threading.Thread(target=update_func, args=(i,))
        t.start()
        threads.append(t)

    # Завершення потоків
    for t in threads:
        t.join()

    elapsed = time.time() - start_time

    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    cursor.execute("SELECT counter FROM user_counter WHERE user_id = 1")
    final_counter = cursor.fetchone()[0]
    cursor.close()
    conn.close()

    lost = TOTAL_EXPECTED - final_counter  # Втрати оновлень

    return elapsed, final_counter, lost

# Результат
for func, name in [(lost_update, "Lost Update"),
                   (in_place_update, "In-Place Update"),
                   (row_level_locking, "Row-Level Locking"),
                   (optimistic_locking, "Optimistic Locking")]:
    elapsed_time, final_count, lost_count = run_test(func)
    print(f"[{name}] Time: {elapsed_time:.2f}s | Final Counter: {final_count} | Lost: {lost_count}")

