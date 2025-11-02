USE sakila;

-- 1) Copies of "Hunchback Impossible" in inventory
-- (subquery version)
SELECT COUNT(*) AS copies
FROM inventory
WHERE film_id = (
  SELECT film_id FROM film WHERE title = 'Hunchback Impossible'
);


-- 2) Films longer than the average film length
SELECT film_id, title, length
FROM film
WHERE length > (SELECT AVG(length) FROM film)
ORDER BY length DESC, title;


-- 3) Actors who appear in "Alone Trip" (subquery for film_id)
SELECT a.actor_id, a.first_name, a.last_name
FROM actor a
WHERE a.actor_id IN (
  SELECT fa.actor_id
  FROM film_actor fa
  WHERE fa.film_id = (SELECT film_id FROM film WHERE title = 'Alone Trip')
)
ORDER BY a.last_name, a.first_name;


-- ======================
-- ======= BONUS ========
-- ======================

-- B1) All movies categorized as Family films
-- (join)
SELECT f.film_id, f.title
FROM film f
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c ON c.category_id = fc.category_id
WHERE c.name = 'Family'
ORDER BY f.title;


-- B2) Name & email of customers from Canada
-- (subquery version)
SELECT first_name, last_name, email
FROM customer
WHERE address_id IN (
  SELECT address_id
  FROM address
  WHERE city_id IN (
    SELECT city_id
    FROM city
    WHERE country_id = (
      SELECT country_id FROM country WHERE country = 'Canada'
    )
  )
)
ORDER BY last_name, first_name;

-- B3) Films starred by the most prolific actor
-- Step 1: find actor(s) with the max film count, then list their films
WITH actor_counts AS (
  SELECT actor_id, COUNT(*) AS films_done
  FROM film_actor
  GROUP BY actor_id
),
top_actor AS (
  SELECT actor_id
  FROM actor_counts
  WHERE films_done = (SELECT MAX(films_done) FROM actor_counts)
)
SELECT a.actor_id, a.first_name, a.last_name, f.film_id, f.title
FROM top_actor ta
JOIN film_actor fa ON fa.actor_id = ta.actor_id
JOIN film f ON f.film_id = fa.film_id
JOIN actor a ON a.actor_id = ta.actor_id
ORDER BY a.last_name, f.title;


-- B4) Films rented by the most profitable customer
-- (customer with the largest total payments)
WITH customer_totals AS (
  SELECT customer_id, SUM(amount) AS total_paid
  FROM payment
  GROUP BY customer_id
),
top_customer AS (
  SELECT customer_id
  FROM customer_totals
  WHERE total_paid = (SELECT MAX(total_paid) FROM customer_totals)
)
SELECT tc.customer_id, f.film_id, f.title, r.rental_date
FROM top_customer tc
JOIN rental r    ON r.customer_id = tc.customer_id
JOIN inventory i ON i.inventory_id = r.inventory_id
JOIN film f      ON f.film_id = i.film_id
ORDER BY r.rental_date DESC, f.title;


-- B5) Clients (customers) who spent more than the average total per client
-- Return customer_id and total_amount_spent
WITH totals AS (
  SELECT customer_id, SUM(amount) AS total_amount_spent
  FROM payment
  GROUP BY customer_id
),
avg_total AS (
  SELECT AVG(total_amount_spent) AS avg_spent FROM totals
)
SELECT t.customer_id, t.total_amount_spent
FROM totals t, avg_total a
WHERE t.total_amount_spent > a.avg_spent
ORDER BY t.total_amount_spent DESC;
