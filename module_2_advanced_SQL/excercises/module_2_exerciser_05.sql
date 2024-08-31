/* 1. Напишите запрос, который сгенерирует 100 строк с числами таким образом:
       * первое число равно 1,
       * каждое следующее число равно сумме номера текущей строки и номеров всех
         предыдущих строк. */

WITH RECURSIVE numbers AS (SELECT 1 as row_num, 1 as row_sum
                           UNION ALL
                           SELECT row_num + 1, row_sum + (row_num + 1) as row_sum
                           FROM NUMBERS
                           WHERE row_num < 100)
SELECT row_num, row_sum
FROM numbers;

/* 2. Напишите запрос, который сгенерирует строки с числами Фибоначчи, начиная с 0 и до
значения не более 2000. Если вы не знакомы с последовательностью чисел Фибоначчи,
загляните в подсказку. Назовите таблицу (CTE) numbers. Для наименований столбцов используйте:
    * fibonacci_number — столбец с числами Фибоначчи;
    * temp_number — столбец c промежуточными значениями вычислений, который не должен
      выводиться в итоговом наборе строк. */

WITH RECURSIVE numbers AS (SELECT 0 AS fibonacci_number, 1 AS temp_number
                           UNION ALL
                           SELECT temp_number,
                                  fibonacci_number + temp_number
                           FROM numbers
                           WHERE temp_number < 2000)
SELECT fibonacci_number
FROM numbers;
