/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Дорошенко Екатерина
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь

SELECT COUNT (id) AS countu,
sum (payer) AS sump,
avg (payer) AS avgp
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь

SELECT r.race, COUNT (f.id) AS countu,
sum (f.payer) AS sump,
ROUND (avg (f.payer),2) AS avgp
FROM fantasy.users AS f
LEFT JOIN fantasy.race AS r USING (race_id)
GROUP BY r.race;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь

SELECT count (amount) AS c_amount,
sum (amount) AS s_amount,
min (amount) AS min_amount,
max (amount) AS max_amount,
ROUND(avg(amount)::NUMERIC,4) AS avg_amount,
percentile_disc(0.5) WITHIN GROUP (ORDER BY amount) AS mediana,
ROUND(stddev(amount)::NUMERIC,4) AS stddev_amount
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь

SELECT count (amount) AS c_amount,
  (SELECT count (amount) FROM fantasy.events WHERE amount = 0)::numeric/count (amount) AS zero_purchase
FROM fantasy.events;

-- 2.3: Популярные эпические предметы:
-- Напишите ваш запрос здесь

WITH count_id AS (
SELECT item_code, 
COUNT (DISTINCT transaction_id) AS c_transaction_id, --количество продаж
COUNT (DISTINCT id) AS c_id --количество игроков
FROM fantasy.events
WHERE amount > 0
GROUP BY item_code
)
SELECT i.game_items,
c.c_transaction_id,
c.c_transaction_id::numeric/(SELECT SUM(c_transaction_id) FROM count_id) AS sales_share, --доля продаж
c.c_id::numeric/(SELECT count (DISTINCT id) FROM fantasy.events WHERE amount > 0) AS players_share
FROM fantasy.events AS e
LEFT JOIN count_id AS c USING (item_code)
LEFT JOIN fantasy.items AS i USING (item_code)
GROUP BY c.c_transaction_id, c.c_id, i.game_items
ORDER BY i.game_items

-- Часть 2. Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь


WITH count_users AS (
SELECT race_id, --раса 
COUNT (DISTINCT id) AS count_id --общее количество зарегистрированных игроков
FROM fantasy.users
GROUP BY race_id
),
count_events AS (
SELECT u.race_id,
COUNT(DISTINCT e.transaction_id) AS c_transaction_id, --количество покупок
COUNT (DISTINCT id) AS count_id_pay, --количество игроков, которые совершают внутриигровые покупки 
AVG (e.amount) AS avg_amount, --средняя стоимость одной покупки на одного игрока, совершившего внутриигровые покупки
SUM (e.amount) AS sum_amount, --суммарная стоимость всех покупок
COUNT(DISTINCT e.id) FILTER (WHERE u.payer = 1) AS payer_count
FROM fantasy.events AS e
LEFT JOIN fantasy.users AS u USING (id)
WHERE e.amount>0
GROUP BY u.race_id
)
SELECT r.race, 
u.count_id, --общее количество зарегистрированных игроков
e.count_id_pay, --количество игроков, которые совершают внутриигровые покупки 
round(e.count_id_pay::NUMERIC/u.count_id,4) AS buyers_share, --количество игроков, которые совершают внутриигровые покупки, и их доля от общего количества зарегистрированных игроков
round(e.payer_count::NUMERIC/e.count_id_pay,4) AS payers_share, --доля платящих игроков среди игроков, которые совершили внутриигровые покупки
round(e.c_transaction_id::NUMERIC/e.count_id_pay,4) avg_purchases_buyer, --среднее количество покупок на одного игрока, совершившего внутриигровые покупки
round(e.avg_amount::NUMERIC,4) AS avg_purchase_amount, --средняя стоимость одной покупки на одного игрока, совершившего внутриигровые покупки
round(e.sum_amount::NUMERIC/e.count_id_pay,4) AS avg_revenue_buyer --суммарная стоимость всех покупок на одного игрока, совершившего внутриигровые покупк
FROM count_events AS e
LEFT JOIN count_users AS u USING (race_id)
LEFT JOIN fantasy.race AS r USING (race_id)
ORDER BY u.count_id;
