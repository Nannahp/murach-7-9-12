-- Chap 7
-- ex 1 
use ap;

SELECT DISTINCT vendor_name
FROM vendors JOIN invoices
ON vendors.vendor_id = invoices.vendor_id
ORDER BY vendor_name;


SELECT DISTINCT vendor_name
FROM vendors
WHERE vendor_id IN (SELECT DISTINCT invoices.vendor_id FROM invoices)
ORDER BY vendor_name;


-- ex 2
SELECT invoice_number, invoice_total
FROM invoices
WHERE payment_total >
(SELECT AVG(payment_total)
FROM invoices WHERE payment_total > 0)
ORDER BY invoice_total DESC;

-- 3
SELECT account_number, account_description
FROM general_ledger_accounts gla
WHERE NOT EXISTS(
	SELECT account_number
    FROM invoice_line_items ili
	WHERE ili.account_number = gla.account_number)
ORDER BY account_number;

-- 4
SELECT vendor_name, i.invoice_id, invoice_sequence, line_item_amount
FROM vendors v
JOIN invoices i ON v.vendor_id = i.vendor_id
JOIN invoice_line_items ili ON i.invoice_id = ili.invoice_id
WHERE i.invoice_id IN (
	SELECT DISTINCT invoice_id
    FROM invoice_line_items
    WHERE invoice_sequence > 1)
ORDER BY vendor_name, invoice_id, invoice_sequence;

-- 5
SELECT SUM(invoice_max) FROM
(SELECT vendor_id, MAX(invoice_total) AS invoice_max
FROM invoices
WHERE invoice_total - credit_total - payment_total > 0
GROUP BY vendor_id) t;

-- 6
SELECT vendor_name as 'NAME', vendor_city as 'CITY', vendor_state as 'STATE'
FROM vendors
WHERE (vendor_state, vendor_city) NOT IN
(
	SELECT vendor_state, vendor_city
	FROM vendors
	GROUP BY vendor_state, vendor_city
	HAVING COUNT(*) > 1
)
ORDER BY vendor_state, vendor_city;

-- 7
SELECT vendor_name, invoice_number, invoice_date, invoice_total
FROM invoices i JOIN vendors v
ON i.vendor_id = v.vendor_id
WHERE invoice_date = (
	SELECT MIN(invoice_date)
	FROM invoices
	WHERE vendor_id = i.vendor_id
)
ORDER BY vendor_name;

-- 8
-- Differences: 7) we compare a list of invoice_dates with another list 
-- which we get from the subqeury. 
-- 8)  we create a temporary table (not a subquery) and join this with the other tables. ,
-- then compare the invoice_dates. 
SELECT v.vendor_name, i.invoice_number, i.invoice_date, i.invoice_total
FROM invoices i
JOIN vendors v ON i.vendor_id = v.vendor_id
JOIN (
    SELECT vendor_id, MIN(invoice_date) AS min_invoice_date
    FROM invoices
    GROUP BY vendor_id
) AS min_dates ON i.vendor_id = min_dates.vendor_id
WHERE i.invoice_date = min_dates.min_invoice_date
ORDER BY v.vendor_name;

-- 9 CTE : Almost like view, but created within the same query. A view is SAVEPOINT
-- stored in the database so that it can be reused. The scope of the CTE is
-- only within the query in which it is created. 
WITH min_date AS
( SELECT vendor_id, MIN(invoice_date) as min_invoice_date
	FROM invoices
    GROUP BY vendor_id
)
SELECT vendor_name, i.invoice_number, i.invoice_date, i.invoice_total
FROM invoices i JOIN vendors v
ON i.vendor_id = v.vendor_id
JOIN min_date md
ON i.vendor_id = md.vendor_id
WHERE i.invoice_date = md.min_invoice_date
ORDER BY vendor_name;



-- ----------------KAPITEL 9 ------------
-- 1
SELECT invoice_total,
		ROUND(invoice_total,1),
		ROUND(invoice_total,0),
		TRUNCATE(invoice_total,0)
FROM invoices;

-- 2
use ex;
SELECT start_date,
		DATE_FORMAT(start_date, '%b/%d/%y'),
        DATE_FORMAT(start_date, '%c-%e-%y'),
        DATE_FORMAT(start_date, '%h, %i, %p')
FROM DATE_SAMPLE;

-- 3
use ap;
SELECT vendor_name,
		UPPER(vendor_name),
        vendor_phone,
        SUBSTRING(vendor_phone, -4)
FROM vendors;

-- 4
SELECT invoice_number,
		invoice_date,
        DATE_ADD(invoice_date, INTERVAL 30 DAY),
        payment_date,
        DATEDIFF(payment_date, invoice_date) as days_to_pay,
        EXTRACT(MONTH FROM invoice_date),
        EXTRACT(YEAR FROM invoice_date)
FROM invoices
WHERE invoice_date BETWEEN '2014-5-01' AND '2014-05-31';

-- 5
use ex;
SELECT emp_name,
	substring_index(emp_name, ' ', 1) as first_name,
    substring_index(emp_name, ' ', -1) as last_name
FROM String_Sample;
        
SELECT  -- chatgpt
    emp_name,
    REGEXP_SUBSTR(emp_name, '^[^\s]+') AS first_name,
    REGEXP_SUBSTR(emp_name, '[^\s]+$') AS last_name
FROM String_Sample;

-- 6
use ap;
SELECT invoice_number,
		(invoice_total - credit_total - payment_total ) as balance_due,
        RANK() OVER (ORDER BY (invoice_total - credit_total - payment_total ) DESC ) as balance_rank
FROM invoices
WHERE (invoice_total - credit_total - payment_total )> 0;

-- -------------------------- KAPITEL 12 -------------
-- 1

CREATE VIEW open_items AS
SELECT vendor_name,
		invoice_number, 
        invoice_total,
        (invoice_total - payment_total-credit_total) as balance_due
FROM vendors v JOIN invoices i on v.vendor_id = i.vendor_id
WHERE  (invoice_total - payment_total-credit_total)  > 0
ORDER BY vendor_name;

-- 2
SELECT * FROM open_items
WHERE balance_due >1000;

-- 3

CREATE OR REPLACE VIEW open_items_summary AS
SELECT vendor_name,
		COUNT(*) as open_item_count,
        SUM(balance_due) as open_item_total
FROM open_items
WHERE balance_due >0
GROUP BY vendor_name
ORDER BY  SUM(balance_due);

-- 4
SELECT * FROM open_items_summary
LIMIT 5;

-- 5
CREATE OR REPLACE VIEW vendor_adress AS
SELECT 	vendor_id, 
		vendor_address1,
		vendor_address2, 
        vendor_city, 
        vendor_state
FROM vendors;

-- 6
UPDATE vendor_adress
SET vendor_address1 =' ',
	vendor_address2 = 'Ste 260'
WHERE vendor_id = 4;


