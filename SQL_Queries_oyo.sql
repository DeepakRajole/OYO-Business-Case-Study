-- load the excel data into sql database 
SELECT * FROM dbo.Oyo_City_csv
SELECT * FROM dbo.Oyo_Sales_csv

--Data Preprocessing 
	
-- Add a new column 'Price' of type float, allowing null values
ALTER TABLE dbo.Oyo_Sales_csv
ADD Price FLOAT NULL;

-- Update the 'Price' column by adding 'amount' and 'discount'
UPDATE dbo.Oyo_Sales_csv
SET Price = amount + discount;

-- Add a new column 'no_of_nights' of type int, allowing null values
ALTER TABLE dbo.Oyo_Sales_csv
ADD no_of_nights INT NULL;

-- Update the 'no_of_nights' column with the difference in days between 'check_in' and 'check_out'
UPDATE dbo.Oyo_Sales_csv
SET no_of_nights = DATEDIFF(day, check_in, check_out);

-- Add a new column 'rate' of type float, allowing null values
ALTER TABLE dbo.Oyo_Sales_csv
ADD rate FLOAT NULL;

-- Update the 'rate' column, calculating the rate per night and per room if applicable
UPDATE dbo.Oyo_Sales_csv
SET rate = ROUND(
    CASE
        WHEN no_of_rooms = 1 THEN Price / no_of_nights
        ELSE Price / no_of_nights / no_of_rooms
    END, 2
);

--Queries
-- Number of hotels in different cities
SELECT city, COUNT(hotel_id) AS [no of hotels]
FROM dbo.Oyo_City_csv
GROUP BY city
ORDER BY 2 DESC;

-- Average room rates of different cities
SELECT b.city, ROUND(AVG(a.rate), 2) AS [average room rates]
FROM dbo.Oyo_Sales_csv AS a
INNER JOIN dbo.Oyo_City_csv AS b
ON a.hotel_id = b.hotel_id
GROUP BY b.city
ORDER BY 2 DESC;

-- Cancellation rates of different cities
SELECT b.city AS City, 
       FORMAT(100.0 * SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(date_of_booking), 'f1') AS [% Cancellation Rate]
FROM dbo.Oyo_Sales_csv AS a
INNER JOIN dbo.Oyo_City_csv AS b
ON a.hotel_id = b.hotel_id
GROUP BY b.city
ORDER BY 2 DESC;

-- Number of bookings of different cities in Jan, Feb, and Mar
SELECT b.city AS [City], DATENAME(month, date_of_booking) AS [Months], COUNT(date_of_booking) AS [No of bookings]
FROM dbo.Oyo_Sales_csv AS a
INNER JOIN dbo.Oyo_City_csv AS b
ON a.hotel_id = b.hotel_id
GROUP BY b.city, DATEPART(month, date_of_booking), DATENAME(month, date_of_booking)
ORDER BY 1, DATEPART(month, date_of_booking);

SELECT b.city AS [City], DATENAME(month, date_of_booking) AS [Months], COUNT(date_of_booking) AS [No of bookings]
FROM dbo.Oyo_Sales_csv AS a
INNER JOIN dbo.Oyo_City_csv AS b
ON a.hotel_id = b.hotel_id
GROUP BY b.city, DATENAME(month, date_of_booking)
ORDER BY 1, 2;

-- Frequency of early bookings prior to check-in the hotel
SELECT DATEDIFF(day, date_of_booking, check_in) AS [Days before check-in], 
       COUNT(1) AS [Frequency_Early_Bookings_Days]
FROM dbo.Oyo_Sales_csv
GROUP BY DATEDIFF(day, date_of_booking, check_in);

-- Frequency of bookings of number of rooms in Hotel
SELECT no_of_rooms, COUNT(1) AS [frequency_of_bookings]
FROM dbo.Oyo_Sales_csv
GROUP BY no_of_rooms
ORDER BY no_of_rooms;

-- Net revenue to company (considering some bookings cancelled) and Gross revenue to company
SELECT b.city, SUM(a.amount) AS [gross revenue], 
       SUM(CASE WHEN a.status IN ('No Show', 'Stayed') THEN a.amount END) AS [net revenue]
FROM dbo.Oyo_Sales_csv AS a
INNER JOIN dbo.Oyo_City_csv AS b
ON a.hotel_id = b.hotel_id
GROUP BY b.city
ORDER BY 1;

-- Discount offered by different cities
select 
    b.city as City, 
    format(100.0 * sum(case when status = 'Cancelled' then 1 else 0 end) / count(date_of_booking),'f1') as [% Cancellation Rate]
from
    dbo.Oyo_Sales_csv as a
inner join 
    dbo.Oyo_City_csv as b on a.hotel_id = b.hotel_id
group by 
    b.city
order by 
    2 desc;

--How many new customers made bookings in February?
	WITH Cust_jan AS (
    SELECT DISTINCT customer_id
    FROM dbo.Oyo_Sales_csv
    WHERE MONTH(date_of_booking) = 1
),
Repeat_cust_feb AS (
    SELECT DISTINCT s.customer_id
    FROM dbo.Oyo_Sales_csv AS s
    INNER JOIN Cust_jan AS b ON b.customer_id = s.customer_id
    WHERE MONTH(date_of_booking) = 2
),
Total_cust_feb AS (
    SELECT DISTINCT customer_id
    FROM dbo.Oyo_Sales_csv
    WHERE MONTH(date_of_booking) = 2
),
New_cust_feb AS (
    SELECT customer_id
    FROM Total_cust_feb AS a
    EXCEPT
    SELECT customer_id
    FROM Repeat_cust_feb AS b
)

SELECT COUNT(c.customer_id) AS [repeat customer in feb]
FROM New_cust_feb AS c
ORDER BY 1;

-- NEW CUSTOMERS ON JAN MONTH - 719
-- REPEAT CUSTOMER ON FEB MONTH - 133
-- NEW CUSTOMERS ON feb MONTH - 566
-- total customer on feb month - 699 (566 + 133)
--Cust_jan: Identifies distinct customer_ids who booked in January (MONTH(date_of_booking) = 1).
--Repeat_cust_feb: Filters customers who booked again in February (MONTH(date_of_booking) = 2) by joining with Cust_jan.
--Total_cust_feb: Lists all distinct customer_ids who booked in February.
--New_cust_feb: Identifies new customers in February by subtracting repeat customers (EXCEPT clause).


Insights:

1. Banglore , gurgaon & delhi were popular in the bookings, whereas Kolkata is less popular in bookings
2. Nature of Bookings:

• Nearly 50 % of the bookings were made on the day of check in only.
• Nearly 85 % of the bookings were made with less than 4 days prior to the date of check in.
• Very few no.of bookings were made in advance(i.e over a 1 month or 2 months).
• Most of the bookings involved only a single room.
• Nearly 80% of the bookings involved a stay of 1 night only.

3. Oyo should acquire more hotels in the cities of Pune, kolkata & Mumbai. Because their average room rates are comparetively higher so more revenue will come.

4. The % cancellation Rate is high on all 9 cities except pune ,so Oyo should focus on finding reasons about cancellation.


