/*
 Inserting the films to the film table
 
 */
BEGIN;
INSERT INTO public.film (
        title,
        description,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost,
        rating,
        last_update
    ) -- not hardcoded id version
SELECT 'Forrest Gump',
    'The life story of a kind-hearted man who experiences important events in American history.',
    1994,
    l.language_id,
    1,
    4.99,
    19.99,
    'PG-13',
    CURRENT_DATE
FROM public.language AS l
WHERE l.name = 'English' -- Cheking whether the film already exists
    AND NOT EXISTS (
        SELECT 1
        FROM public.film AS f
        WHERE LOWER(f.title) = LOWER('Forrest Gump')
            AND f.release_year = 1994
    )
RETURNING film_id,
    title,
    release_year,
    rental_duration,
    rental_rate;
COMMIT;
-- check
SELECT film_id,
    title,
    release_year,
    rental_duration,
    rental_rate
FROM public.film
WHERE LOWER(TRIM(title)) = LOWER(TRIM('Forrest Gump'))
    AND release_year = 1994;
BEGIN;
INSERT INTO public.film (
        title,
        description,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost,
        rating,
        last_update
    ) -- not hardcoded id version
SELECT 'The Great Gatsby',
    'A mysterious millionaire hosts lavish parties while pursuing a lost love.',
    2013,
    l.language_id,
    2,
    9.99,
    19.99,
    'PG-13',
    CURRENT_DATE
FROM public.language AS l
WHERE l.name = 'English' -- Cheking whether the film already exists
    AND NOT EXISTS (
        SELECT 1
        FROM public.film AS f
        WHERE LOWER(f.title) = LOWER('The Great Gatsby')
    )
RETURNING film_id,
    title,
    release_year,
    rental_duration,
    rental_rate;
COMMIT;
BEGIN;
INSERT INTO public.film (
        title,
        description,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost,
        rating,
        length,
        last_update
    ) -- not hardcoded id version
SELECT 'Django Unchained',
    'A freed slave joins a bounty hunter to rescue his wife.',
    2012,
    l.language_id,
    3,
    19.99,
    19.99,
    'R',
    165,
    CURRENT_DATE
FROM public.language AS l
WHERE l.name = 'English' -- Cheking whether the film already exists
    AND NOT EXISTS (
        SELECT 1
        FROM public.film AS f
        WHERE LOWER(f.title) = LOWER('Django Unchained')
    )
RETURNING film_id,
    title,
    release_year,
    length,
    rental_rate;
COMMIT;
-- update of the missing values
BEGIN;
UPDATE public.film
SET length = 142,
    last_update = CURRENT_DATE
WHERE title = 'Forrest Gump'
RETURNING film_id,
    title,
    release_year,
    length,
    last_update;
COMMIT;
BEGIN;
UPDATE public.film
SET length = 143,
    last_update = CURRENT_DATE
WHERE title = 'The Great Gatsby'
RETURNING film_id,
    title,
    release_year,
    length,
    last_update;
COMMIT;
/*
 Inserting the actorts to the actor table
 
 */
-- check actors who altready exists
SELECT actor_id,
    first_name,
    last_name
FROM public.actor
WHERE (
        first_name = 'Tom'
        AND last_name = 'Hanks'
    )
    OR (
        first_name = 'Robin'
        AND last_name = 'Wright'
    )
    OR (
        first_name = 'Gary'
        AND last_name = 'Sinise'
    )
    OR (
        first_name = 'Mykelti'
        AND last_name = 'Williamson'
    )
    OR (
        first_name = 'Sally'
        AND last_name = 'Field'
    )
    OR (
        first_name = 'Haley Joel'
        AND last_name = 'Osment'
    );
-- no data has founded
-- inserting new actors 1 part
BEGIN;
INSERT INTO public.actor (
        first_name,
        last_name,
        last_update
    )
VALUES ('Tom', 'Hanks', CURRENT_DATE),
    ('Robin', 'Wright', CURRENT_DATE),
    ('Gary', 'Sinise', CURRENT_DATE),
    ('Mykelti', 'Williamson', CURRENT_DATE),
    ('Sally', 'Field', CURRENT_DATE),
    ('Haley Joel', 'Osment', CURRENT_DATE)
RETURNING actor_id,
    first_name,
    last_name,
    last_update;
COMMIT;
-- inserting 2 part of actors
BEGIN;
INSERT INTO public.actor (
        first_name,
        last_name,
        last_update
    )
SELECT actor_data.first_name,
    actor_data.last_name,
    CURRENT_DATE
FROM (
        VALUES ('Leonardo', 'DiCaprio'),
            ('Carey', 'Mulligan'),
            ('Tobey', 'Maguire'),
            ('Joel', 'Edgerton'),
            ('Elizabeth', 'Debicki'),
            ('Isla', 'Fisher'),
            ('Jamie', 'Foxx'),
            ('Christoph', 'Waltz'),
            ('Kerry', 'Washington'),
            ('Samuel L.', 'Jackson'),
            ('Walton', 'Goggins')
    ) AS actor_data(first_name, last_name) -- cheking dublicates
WHERE NOT EXISTS (
        SELECT 1
        FROM public.actor AS a
        WHERE LOWER(a.first_name) = LOWER(actor_data.first_name)
            AND LOWER(a.last_name) = LOWER(actor_data.last_name)
    )
RETURNING actor_id,
    first_name,
    last_name,
    last_update;
COMMIT;
-- connecting films with actors
BEGIN;
INSERT INTO public.film_actor (film_id, actor_id, last_update)
SELECT f.film_id,
    a.actor_id,
    CURRENT_DATE
FROM (
        VALUES ('Forrest Gump', 1994, 'Tom', 'Hanks'),
            ('Forrest Gump', 1994, 'Robin', 'Wright'),
            ('Forrest Gump', 1994, 'Gary', 'Sinise'),
            ('Forrest Gump', 1994, 'Mykelti', 'Williamson'),
            ('Forrest Gump', 1994, 'Sally', 'Field'),
            ('Forrest Gump', 1994, 'Haley Joel', 'Osment'),
            ('The Great Gatsby', 2013, 'Leonardo', 'DiCaprio'),
            ('The Great Gatsby', 2013, 'Carey', 'Mulligan'),
            ('The Great Gatsby', 2013, 'Tobey', 'Maguire'),
            ('The Great Gatsby', 2013, 'Joel', 'Edgerton'),
            ('The Great Gatsby', 2013, 'Elizabeth', 'Debicki'),
            ('The Great Gatsby', 2013, 'Isla', 'Fisher'),
            ('Django Unchained', 2012, 'Jamie', 'Foxx'),
            ('Django Unchained', 2012, 'Christoph', 'Waltz'),
            ('Django Unchained', 2012, 'Leonardo', 'DiCaprio'),
            ('Django Unchained', 2012, 'Kerry', 'Washington'),
            ('Django Unchained', 2012, 'Samuel L.', 'Jackson'),
            ('Django Unchained', 2012, 'Walton', 'Goggins')
    ) AS selected_cast(
        film_title,
        film_year,
        actor_first_name,
        actor_last_name
    )
    INNER JOIN public.film AS f ON f.title = selected_cast.film_title
    AND f.release_year = selected_cast.film_year
    INNER JOIN public.actor AS a ON LOWER(a.first_name) = LOWER(selected_cast.actor_first_name)
    AND LOWER(a.last_name) = LOWER(selected_cast.actor_last_name)
WHERE NOT EXISTS (
        SELECT 1
        FROM public.film_actor AS fa
        WHERE fa.film_id = f.film_id
            AND fa.actor_id = a.actor_id
    )
RETURNING film_id,
    actor_id,
    last_update;
COMMIT;
SELECT film_id,
    title,
    release_year
FROM film
ORDER BY last_update DESC
LIMIT 3
SELECT store_id
FROM public.store
ORDER BY store_id;
BEGIN;
INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT f.film_id,
    s.store_id,
    CURRENT_DATE
FROM public.film AS f
    CROSS JOIN (
        SELECT MIN(store_id) AS store_id
        FROM public.store
    ) AS s
WHERE (
        f.title = 'Forrest Gump'
        AND f.release_year = 1994
    )
    OR (
        f.title = 'The Great Gatsby'
        AND f.release_year = 2013
    )
    OR (
        f.title = 'Django Unchained'
        AND f.release_year = 2012
    )
    AND NOT EXISTS (
        SELECT 1
        FROM public.inventory AS i
        WHERE i.film_id = f.film_id
            AND i.store_id = s.store_id
    )
RETURNING inventory_id,
    film_id,
    store_id,
    last_update;
Commit;
-- identify customer with more that 43 orders and payments
SELECT c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT r.rental_id) AS rental_amount,
    COUNT(DISTINCT p.payment_id) AS payment_amount
FROM customer c
    LEFT JOIN rental r ON r.customer_id = c.customer_id
    LEFT JOIN payment p ON p.customer_id = c.customer_id
GROUP BY c.customer_id,
    c.first_name,
    c.last_name
HAVING COUNT(DISTINCT r.rental_id) >= 43
    AND COUNT(DISTINCT p.payment_id) >= 43
ORDER BY c.customer_id -- selecting one id from previous customer_id = 1
    BEGIN;
UPDATE customer
SET first_name = 'Dominykas',
    last_name = 'Ulevic',
    email = 'du.email@example.com',
    address_id = (
        SELECT address_id
        FROM public.address
        ORDER BY address_id
        LIMIT 1
    ), last_update = CURRENT_DATE
WHERE customer_id = 1
RETURNING customer_id,
    first_name,
    last_name,
    email,
    address_id,
    last_update;
COMMIT;
-- check 
select *
FROM customer
WHERE customer_id = 1 -- inspecting customer_id = 1 activity
SELECT c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT r.rental_id) AS rental_amount,
    COUNT(DISTINCT p.payment_id) AS payment_amount
FROM customer c
    LEFT JOIN rental r ON r.customer_id = c.customer_id
    LEFT JOIN payment p ON p.customer_id = c.customer_id
WHERE c.customer_id = 1
GROUP BY c.customer_id,
    c.first_name,
    c.last_name
ORDER BY c.customer_id -- result both 64
    -- deleting payments
    BEGIN;
DELETE FROM public.payment
WHERE customer_id = 1
RETURNING payment_id,
    customer_id,
    rental_id,
    amount,
    payment_date;
COMMIT;
-- deleting rentals
BEGIN;
DELETE FROM public.rental
WHERE customer_id = 1
RETURNING rental_id,
    customer_id,
    inventory_id,
    rental_date;
COMMIT;
-- check with same query
-- adding films rental
BEGIN;
INSERT INTO rental (
        rental_date,
        inventory_id,
        customer_id,
        staff_id,
        last_update
    )
SELECT TIMESTAMP '2017-06-01 10:00:00',
    i.inventory_id,
    c.customer_id,
    s.staff_id,
    CURRENT_DATE
FROM public.film AS f
    INNER JOIN public.inventory AS i ON i.film_id = f.film_id
    INNER JOIN public.staff AS s ON s.store_id = i.store_id
    INNER JOIN public.customer AS c ON customer_id = 1
WHERE f.title IN (
        'Forrest Gump',
        'The Great Gatsby',
        'Django Unchained'
    )
    AND s.staff_id = (
        SELECT MIN(s2.staff_id)
        FROM public.staff AS s2
        WHERE s2.store_id = i.store_id
    )
RETURNING rental_id,
    inventory_id,
    customer_id,
    staff_id;
COMMIT;
-- inserting the payments fot rentings
BEGIN;
INSERT INTO payment (
        customer_id,
        staff_id,
        rental_id,
        amount,
        payment_date
    )
SELECT c.customer_id,
    s.staff_id,
    r.rental_id,
    f.rental_rate,
    TIMESTAMP '2017-06-01 10:00:00'
FROM public.film AS f
    INNER JOIN public.inventory AS i ON i.film_id = f.film_id
    INNER JOIN public.staff AS s ON s.store_id = i.store_id
    INNER JOIN rental AS r ON r.inventory_id = i.inventory_id
    INNER JOIN public.customer AS c ON c.customer_id = 1
WHERE f.title IN (
        'Forrest Gump',
        'The Great Gatsby',
        'Django Unchained'
    )
    AND s.staff_id = (
        SELECT MIN(s2.staff_id)
        FROM public.staff AS s2
        WHERE s2.store_id = i.store_id
    )
RETURNING customer_id,
    staff_id,
    rental_id,
    amount COMMIT;
-- final check
SELECT f.title,
    f.release_year,
    i.store_id,
    r.rental_id,
    p.payment_id,
    p.amount
FROM public.film AS f
    INNER JOIN public.inventory AS i ON i.film_id = f.film_id
    INNER JOIN public.rental AS r ON r.inventory_id = i.inventory_id
    INNER JOIN public.payment AS p ON p.rental_id = r.rental_id
WHERE f.title IN (
        'Forrest Gump',
        'The Great Gatsby',
        'Django Unchained'
    )
ORDER BY f.title;