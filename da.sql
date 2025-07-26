-- ✅ 1. Add Function (get_full_name)


CREATE OR REPLACE FUNCTION get_full_name(first_name TEXT, last_name TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN INITCAP(first_name || ' ' || last_name);
END;
$$ LANGUAGE plpgsql;


-- ✅ 2. Create Detailed and Summary Tables
CREATE TABLE detailed_rentals_report (
  customer_id INT,
  customer_name TEXT,
  film_title TEXT,
  category TEXT,
  rental_date TIMESTAMP,
  return_date TIMESTAMP,
  rental_duration INT,
  amount_paid NUMERIC
);

CREATE TABLE summary_rentals_report (
  category TEXT PRIMARY KEY,
  total_revenue NUMERIC,
  total_rentals INT,
  average_rental_duration NUMERIC
);




-- See section D from earlier message for full query
-- This is the raw data pull



-- ✅ 4. Create Trigger Function and Trigger
-- Trigger function
CREATE OR REPLACE FUNCTION update_summary_report()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO summary_rentals_report (category, total_revenue, total_rentals, average_rental_duration)
  SELECT
    NEW.category,
    NEW.amount_paid,
    1,
    NEW.rental_duration
  ON CONFLICT (category) DO UPDATE SET
    total_revenue = summary_rentals_report.total_revenue + EXCLUDED.total_revenue,
    total_rentals = summary_rentals_report.total_rentals + 1,
    average_rental_duration = (
      (summary_rentals_report.average_rental_duration * summary_rentals_report.total_rentals + EXCLUDED.average_rental_duration)
      / (summary_rentals_report.total_rentals + 1)
    );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Actual trigger
CREATE TRIGGER trg_update_summary
AFTER INSERT ON detailed_rentals_report
FOR EACH ROW
EXECUTE FUNCTION update_summary_report();



-- ✅ 5. Create Stored Procedure
CREATE OR REPLACE PROCEDURE refresh_rental_reports()
LANGUAGE plpgsql
AS $$
BEGIN
  TRUNCATE TABLE detailed_rentals_report;
  TRUNCATE TABLE summary_rentals_report;

  INSERT INTO detailed_rentals_report (
    customer_id, customer_name, film_title, category, rental_date, return_date, rental_duration, amount_paid
  )
  SELECT
    c.customer_id,
    get_full_name(c.first_name, c.last_name),
    f.title,
    cat.name,
    r.rental_date,
    r.return_date,
    DATE_PART('day', r.return_date - r.rental_date),
    p.amount
  FROM rental r
  JOIN inventory i ON r.inventory_id = i.inventory_id
  JOIN film f ON i.film_id = f.film_id
  JOIN film_category fc ON f.film_id = fc.film_id
  JOIN category cat ON fc.category_id = cat.category_id
  JOIN customer c ON r.customer_id = c.customer_id
  JOIN payment p ON p.rental_id = r.rental_id;
END;
$$;


dvdrental > Schemas > public > Procedures


CALL refresh_rental_reports();



-- Try 2

DO $$
BEGIN
    EXECUTE '
    CREATE OR REPLACE FUNCTION get_full_name(
        first_name TEXT, 
        last_name TEXT
    )
    RETURNS TEXT AS $func$
    BEGIN
        RETURN INITCAP(first_name) || '' '' || INITCAP(last_name);
    END;
    $func$ LANGUAGE plpgsql;
    ';
END
$$;

CREATE OR REPLACE FUNCTION get_full_name(
    first_name TEXT,
    last_name TEXT
)
RETURNS TEXT AS $$
BEGIN
    RETURN INITCAP(first_name) || ' ' || INITCAP(last_name);
END;
$$ LANGUAGE plpgsql;

