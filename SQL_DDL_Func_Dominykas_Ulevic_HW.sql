-- task 1
CREATE SCHEMA IF NOT EXISTS core;
DROP VIEW IF EXISTS core.sales_revenue_by_category_qtr;
-- The view dynamically calculates the current quarter from CURRENT_DATE.
-- date_trunc('quarter', CURRENT_DATE) returns the first day of the current quarter.
-- The upper boundary is three months after the quarter start.
-- Inner joins include only films that have rental and payment records.
-- Therefore categories with no sales are automatically excluded.
-- SUM(payment.amount) calculates total revenue per category.
CREATE VIEW core.sales_revenue_by_category_qtr AS
SELECT SUM(p.amount) AS total_sales_revenue,
    c.name
FROM category AS c
    INNER JOIN film_category AS fc ON fc.category_id = c.category_id
    INNER JOIN film AS f ON f.film_id = fc.film_id
    INNER JOIN inventory AS i ON i.film_id = f.film_id
    INNER JOIN rental AS r ON r.inventory_id = i.inventory_id
    INNER JOIN payment AS p ON p.rental_id = r.rental_id
WHERE p.payment_date >= date_trunc('quarter', CURRENT_DATE)
    AND p.payment_date < date_trunc('quarter', CURRENT_DATE) + INTERVAL '3 months'
GROUP BY c.name;
-- check
SELECT *
FROM core.sales_revenue_by_category_qtr;
-- task 2
/*
 This SQL-language function accepts the first day of a quarter.
 
 The parameter is needed because the view always uses the real current
 quarter, while the DVD Rental database contains historical data.
 
 The function calculates the quarter end by adding three months.
 Only categories with payment records in that period are returned.
 
 If the supplied date is not the first day of a quarter, the function
 returns no rows. SQL-language functions do not support RAISE EXCEPTION;
 that validation is handled by the WHERE condition.
 */
CREATE OR REPLACE FUNCTION core.get_sales_revenue_by_category_qtr(p_quarter_start date) RETURNS TABLE(
        category text,
        total_sales_revenue numeric
    ) LANGUAGE SQL AS $$
SELECT c.name::text AS category,
    SUM(p.amount)::numeric AS total_sales_revenue
FROM category AS c
    INNER JOIN film_category AS fc ON fc.category_id = c.category_id
    INNER JOIN film AS f ON f.film_id = fc.film_id
    INNER JOIN inventory AS i ON i.film_id = f.film_id
    INNER JOIN rental AS r ON r.inventory_id = i.inventory_id
    INNER JOIN payment AS p ON p.rental_id = r.rental_id
WHERE p.payment_date >= p_quarter_start
    AND p.payment_date < p_quarter_start + INTERVAL '3 months'
    AND p_quarter_start = date_trunc('quarter', p_quarter_start)::date
GROUP BY c.name
ORDER BY c.name;
$$;
--check
SELECT *
FROM core.get_sales_revenue_by_category_qtr(DATE '2017-01-01');
SELECT *
FROM core.get_sales_revenue_by_category_qtr(DATE '2017-04-01');
/*
 Function: most_popular_films_by_countries
 
 Purpose:
 Returns the most popular film for each requested country.
 
 Input:
 p_country_names is an array of country names, for example:
 ARRAY['Afghanistan', 'Brazil', 'United States'].
 
 Popularity definition:
 Popularity is measured by the number of rentals made by customers
 from each country. The film with the highest rental count is selected.
 
 Logic:
 1. unnest() converts the input array into individual country rows.
 2. Country, city, address, and customer tables identify customers
 who belong to each requested country.
 3. Rental, inventory, and film tables identify rented films.
 4. COUNT(r.rental_id) counts rentals for each film and country.
 5. The correlated MAX() subquery finds the highest rental count
 separately for each country.
 6. Films whose count equals that maximum are returned.
 
 Ties:
 If multiple films have the same highest rental count in one country,
 all tied films are returned.
 
 Invalid input:
 If the array is NULL or empty, RAISE EXCEPTION stops the function
 and reports an error.
 
 Missing data:
 If a requested country does not exist or has no matching customers
 and rentals, no row is returned for that country.
 */
DROP FUNCTION IF EXISTS core.most_popular_films_by_countries(text []);
CREATE OR REPLACE FUNCTION core.most_popular_films_by_countries(p_country_names text []) RETURNS TABLE (
        country text,
        film text,
        rating mpaa_rating,
        language text,
        length smallint,
        release_year year
    ) LANGUAGE plpgsql AS $$ BEGIN IF p_country_names IS NULL
    OR cardinality(p_country_names) = 0 THEN RAISE EXCEPTION 'Country array cannot be NULL or empty';
END IF;
RETURN QUERY WITH film_counts AS (
    SELECT co.country::text AS country,
        f.title::text AS film,
        f.rating,
        l.name::text AS language,
        f.length,
        f.release_year,
        COUNT(r.rental_id) AS rental_count
    FROM unnest(p_country_names) AS requested(country_name)
        JOIN public.country AS co ON LOWER(co.country) = LOWER(requested.country_name)
        JOIN public.city AS ci ON ci.country_id = co.country_id
        JOIN public.address AS ad ON ad.city_id = ci.city_id
        JOIN public.customer AS cu ON cu.address_id = ad.address_id
        JOIN public.rental AS r ON r.customer_id = cu.customer_id
        JOIN public.inventory AS i ON i.inventory_id = r.inventory_id
        JOIN public.film AS f ON f.film_id = i.film_id
        JOIN public.language AS l ON l.language_id = f.language_id
    GROUP BY co.country,
        f.title,
        f.rating,
        l.name,
        f.length,
        f.release_year
)
SELECT fc.country::text,
    fc.film::text,
    fc.rating,
    fc.language::text,
    fc.length,
    fc.release_year
FROM film_counts AS fc
WHERE fc.rental_count = (
        SELECT MAX(fc2.rental_count)
        FROM film_counts AS fc2
        WHERE fc2.country = fc.country
    )
ORDER BY fc.country,
    fc.film;
END;
$$;
SELECT *
FROM core.most_popular_films_by_countries(ARRAY [ 'Brazil', 'United States']);
-- the Afghanistan seemed suspiciuos, therefore the next query checks if there is that much popular films in this coutry
SELECT COUNT(r.rental_id) AS rental_count,
    f.title
FROM public.film AS f
    JOIN public.inventory AS i ON i.film_id = f.film_id
    JOIN public.rental AS r ON r.inventory_id = i.inventory_id
    JOIN public.customer AS cu ON cu.customer_id = r.customer_id
    JOIN public.address AS a ON a.address_id = cu.address_id
    JOIN public.city AS ci ON ci.city_id = a.city_id
    JOIN public.country AS c ON c.country_id = ci.country_id
WHERE c.country = 'Afghanistan'
GROUP BY f.title
ORDER BY rental_count DESC,
    f.title;
-- proved
-- task 4
DROP FUNCTION IF EXISTS core.films_in_stock_by_title(text);
-- This function returns films whose titles match a partial search pattern.
-- The input 'love' is converted to '%love%' so that any characters may
-- appear before or after the searched word.
--
-- ILIKE performs case-insensitive pattern matching:
-- 'love', 'Love', and 'LOVE' produce the same matches.
--
-- ROW_NUMBER() generates a sequential row number for every result.
-- Multiple matching films and inventory/rental records are returned.
--
-- The search may become slower for large tables when the pattern begins
-- with '%', because a normal index cannot efficiently search from the
-- beginning of the title. The query first filters films by title before
-- returning related rental and customer information.
--
-- If the input is NULL or empty, the function raises an exception.
-- If no film matches the pattern, the function returns no rows and raises
-- a notice explaining which pattern was searched.
CREATE OR REPLACE FUNCTION core.films_in_stock_by_title(p_title_pattern text) RETURNS TABLE (
        row_num bigint,
        film_title text,
        language text,
        customer_name text,
        rental_date timestamp
    ) LANGUAGE plpgsql AS $$
DECLARE v_pattern text;
v_rows integer;
BEGIN IF p_title_pattern IS NULL
OR btrim(p_title_pattern) = '' THEN RAISE EXCEPTION 'Title pattern cannot be NULL or empty';
END IF;
v_pattern := '%' || p_title_pattern || '%';
RETURN QUERY
SELECT ROW_NUMBER() OVER (
        ORDER BY f.title,
            r.rental_date
    )::bigint,
    f.title::text,
    l.name::text,
    COALESCE(
        c.first_name || ' ' || c.last_name,
        '-'
    )::text,
    r.rental_date::timestamp
FROM film AS f
    JOIN language AS l ON l.language_id = f.language_id
    JOIN inventory AS i ON i.film_id = f.film_id
    JOIN store AS s ON s.store_id = i.store_id
    JOIN customer AS c ON c.store_id = s.store_id
    JOIN rental AS r ON r.customer_id = c.customer_id
WHERE f.title ILIKE v_pattern
ORDER BY f.title,
    r.rental_date;
GET DIAGNOSTICS v_rows = ROW_COUNT;
IF v_rows = 0 THEN RAISE NOTICE 'No films found matching: %',
v_pattern;
END IF;
END;
$$;
SELECT *
FROM core.films_in_stock_by_title('love');
-- task 5
DROP FUNCTION IF EXISTS core.new_movie(text, year, text);
CREATE FUNCTION core.new_movie(
    p_title text,
    p_release_year year DEFAULT EXTRACT(
        YEAR
        FROM CURRENT_DATE
    )::year,
    p_language_name text DEFAULT 'Klingon'
) RETURNS TABLE (
    film_id bigint,
    title text,
    release_year year,
    language_id smallint,
    rental_duration smallint,
    rental_rate numeric,
    replacement_cost numeric
) LANGUAGE plpgsql AS $$
DECLARE v_language_id smallint;
BEGIN
SELECT l.language_id INTO v_language_id
FROM public.language AS l
WHERE LOWER(l.name) = LOWER(p_language_name);
IF v_language_id IS NULL THEN RAISE EXCEPTION 'Language does not exist: %',
p_language_name;
END IF;
IF EXISTS (
    SELECT 1
    FROM public.film AS f
    WHERE LOWER(f.title) = LOWER(p_title)
) THEN RAISE EXCEPTION 'Film already exists: %',
p_title;
END IF;
RETURN QUERY
INSERT INTO public.film (
        title,
        description,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost,
        last_update
    )
VALUES (
        p_title,
        'Description not provided',
        p_release_year,
        v_language_id,
        3,
        4.99,
        19.99,
        CURRENT_TIMESTAMP
    )
RETURNING film.film_id::bigint,
    film.title::text,
    film.release_year,
    film.language_id,
    film.rental_duration,
    film.rental_rate,
    film.replacement_cost;
END;
$$;