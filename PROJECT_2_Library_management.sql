CREATE DATABASE Library_Management_Project2;

USE Library_Management_Project2;

DROP TABLE IF EXISTS books;
CREATE TABLE books
(isbn	VARCHAR(20) PRIMARY KEY,
book_title VARCHAR(75),
category VARCHAR(25),	
rental_price FLOAT,
`status` VARCHAR(10),
author VARCHAR(40),
publisher VARCHAR(45)
);

DROP TABLE IF EXISTS branch;
CREATE TABLE branch
(branch_id VARCHAR(15) PRIMARY KEY , 
 manager_id	VARCHAR(15), 
 branch_address VARCHAR(50),
 contact_no VARCHAR(15)
 );


CREATE TABLE employees
(emp_id VARCHAR(15) PRIMARY KEY, 
emp_name VARCHAR(50),
position VARCHAR(25), 	
salary int, 
branch_id VARCHAR(15) 
);


CREATE TABLE issued_status
(issued_id VARCHAR(15) PRIMARY KEY, 
issued_member_id VARCHAR(15),
issued_book_name VARCHAR(75), 	
issued_date	DATE, 
issued_book_isbn VARCHAR(20), 
issued_emp_id VARCHAR(15)
);

CREATE TABLE members
(member_id VARCHAR(15) PRIMARY KEY, 
member_name VARCHAR(50), 
member_address VARCHAR(50), 	
reg_date DATE
);

CREATE TABLE return_status
(return_id VARCHAR(15) PRIMARY KEY,
 issued_id VARCHAR(15),	
 return_book_name VARCHAR(75),	
 return_date DATE,	
 return_book_isbn VARCHAR(20)
 );


-- ASSIGNING FOREIGN KEYS to issued_status

ALTER TABLE issued_status
ADD CONSTRAINT fk_members 
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id);

ALTER TABLE issued_status
ADD CONSTRAINT fk_emp
FOREIGN KEY(issued_book_isbn)
REFERENCES books(isbn);

ALTER TABLE issued_status
ADD CONSTRAINT fk_employee
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id);

ALTER TABLE employees 
ADD CONSTRAINT fk_branch
FOREIGN KEY(branch_id)
REFERENCES branch(branch_id);

ALTER TABLE return_status
ADD CONSTRAINT fk_issued
FOREIGN KEY(issued_id)
REFERENCES issued_status(issued_id);

SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

-- Project Task

/*1. Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 
'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')" */

INSERT INTO books(isbn, book_title, category, rental_price, `status`, author, publisher)
	VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 
		   6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');


-- Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '125 Oak st'
WHERE member_id = 'C103';


/* 3. Delete a Record from the Issued Status Table -- 
Objective: Delete the record with issued_id = 'IS121' from the issued_status table. */

DELETE 
FROM issued_status
WHERE issued_id = 'IS121';


/*Task 4: Retrieve All Books Issued by a Specific Employee -- 
Objective: Select all books issued by the employee with emp_id = 'E101'. */

SELECT issued_book_name 
FROM issued_status
WHERE issued_emp_id = 'E101';

/*Task 5: List Members Who Have Issued More Than One Book -- 
Objective: Use GROUP BY to find members who have issued more than one book.*/

SELECT issued_emp_id, COUNT(*) AS issue_per_emp
FROM issued_status
GROUP BY issued_emp_id
HAVING (COUNT(*)  > 1) 
ORDER BY issue_per_emp;


/*Task 6: Create Summary Tables: Used CTAS to generate new tables 
based on query results - each book and total book_issued_cnt** */
SELECT * FROM books;
SELECT * FROM issued_status;

DROP TABLE IF EXISTS summary_table;
CREATE TABLE summary_table AS
(SELECT books.isbn, books.book_title, COUNT(issue.issued_id) AS issue_count
 FROM issued_status as issue
 JOIN books as books
 ON issue.issued_book_isbn = books.isbn
 GROUP BY books.isbn, books.book_title
);
SELECT * 
FROM summary_table;

-- Task 7. Retrieve All Books in a Specific Category:
 -- Check for all the categories available.
SELECT category
FROM books
GROUP BY category;

SELECT book_title
FROM books 
WHERE category = 'Classic';


-- Task 8: Find Total Rental Income by Category:

SELECT * FROM books;
SELECT * FROM issued_status;

SELECT b.category, SUM(b.rental_price) as Income_per_cat, COUNT(iss.issued_id) as issue_per_cat
FROM books as b
JOIN issued_status as iss
ON b.isbn = iss.issued_book_isbn
GROUP BY b.category;

-- 9.List Members Who Registered in the Last 180 Days:
SELECT *
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL  180 day; 

INSERT INTO members(member_id, member_name, member_address, reg_date)
VALUES( 'C120', 'Alexendar V', '604 N 31 Ave', '2025-06-10');


-- 10. List Employees with Their Branch Manager's Name and their branch details:
SELECT * 
FROM employees;

SELECT *
FROM branch;

SELECT e1.emp_id,e1.emp_name, e1.position,e1.salary, b.*, e2.emp_name as Manager
FROM employees as e1
JOIN branch as b
ON e1.branch_id = b.branch_id
JOIN employees AS e2
ON b.manager_id = e2.emp_id;


-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:
CREATE TABLE Expensive_books as
(
SELECT *
FROM books 
WHERE rental_price > 7);
select * from Expensive_books;

-- Task 12: Retrieve the List of Books Not Yet Returned

SELECT *
FROM issued_status as issue
LEFT JOIN return_status as rs
ON issue.issued_id = rs.issued_id
WHERE rs.issued_id IS NULL ;


/*Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue. */

SELECT t2.issued_member_id,t1.member_name, t4.book_title, t2.issued_date, 
DATEDIFF(CURRENT_DATE, t2.issued_date) as overdue_days
FROM members as t1
JOIN issued_status as t2
	ON t1.member_id = t2.issued_member_id
JOIN books as t4
	ON t2.issued_book_isbn = t4.isbn
LEFT JOIN return_status AS t3
	ON t2.issued_id = t3.issued_id
WHERE t3.return_id IS NULL 
	AND DATEDIFF(CURRENT_DATE, t2.issued_date) > 30;
	  

/*Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned 
(based on entries in the return_status table).*/

SELECT b.book_title, b.`status`, i.issued_id, rs.return_id
FROM books as b
JOIN issued_status as i 
	on b.isbn = i.issued_book_isbn
left JOIN return_status as rs
	On i.issued_id = rs.issued_id;

DELIMITER $$
CREATE TRIGGER update_status_books
AFTER INSERT ON return_status
FOR EACH ROW 
BEGIN 
	UPDATE books as b
    JOIN issued_status as i
		ON b.isbn = i.issued_book_isbn
	SET `status` = 'Yes'
	WHERE i.issued_id = NEW.issued_id;
END $$
DELIMITER ;

INSERT INTO return_status(return_id, issued_id, return_book_name, return_date, return_book_isbn)
VALUES('RS145', 'IS135', NULL, '2024-07-20', NULL);



/*Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, 
showing the number of books issued, the number of books returned, 
and the total revenue generated from book rentals. */

CREATE TABLE branch_reports AS(
SELECT  br.branch_id as Branch,COUNT(iss.issued_id) No_of_issue, 
		COUNT(rs.return_id) No_of_return, SUM(rental_price) Revenue
FROM issued_status as iss
JOIN employees as emp
	ON emp.emp_id = iss.issued_emp_id
JOIN branch as br
	ON emp.branch_id = br.branch_id
JOIN books as bk
	ON bk.isbn = iss.issued_book_isbn
LEFT JOIN return_status as rs
	ON iss.issued_id = rs.issued_id
GROUP BY br.branch_id );

SELECT * FROM branch_reports;

/*Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members 
containing members who have issued at least one book in the last 2 months. */

CREATE TABLE active_members AS(
SELECT iss.issued_member_id
FROM issued_status as iss
JOIN members as mem
	ON iss.issued_member_id = mem.member_id
    WHERE DATE_SUB('2024-04-13', INTERVAL 60 DAY)
GROUP BY iss.issued_member_id);

-- OR 
CREATE TABLE active_members2 AS(
SELECT * FROM members
WHERE member_id IN(SELECT DISTINCT issued_member_id
				FROM issued_status
				WHERE '2024-04-13' - interval 2 month < issued_date));


/*Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch.*/

WITH top_3_employees AS(
SELECT emp_name,br.*, COUNT(iss.issued_id) as no_of_books_issued,
  DENSE_RANK( ) OVER( ORDER BY COUNT(iss.issued_id) DESC) AS `RANK`
FROM employees as emp
JOIN issued_status as iss
	ON emp.emp_id = iss.issued_emp_id
JOIN branch as br
	ON emp.branch_id = br.branch_id
    GROUP BY 1,2 
)

SELECT *
FROM top_3_employees
HAVING `RANK` <=3;


/*Task 19: Stored Procedure Objective: 
Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the 
library based on its issuance. The procedure should function as follows: 
The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books 
table should be updated to 'no'. If the book is not available (status = 'no'), 
the procedure should return an error message indicating that the book is currently not available.*/

DELIMITER $$
DROP PROCEDURE if exists add_book_issuance;
CREATE PROCEDURE add_book_issuance(p_issued_id VARCHAR(15), p_issued_member_id VARCHAR(15),
 p_issued_book_name VARCHAR(75), p_issued_book_isbn VARCHAR(20),p_issued_emp_id VARCHAR(15))

BEGIN
DECLARE
	v_status VARCHAR(10);

	SELECT `status`
		INTO v_status
    FROM books
	WHERE isbn = p_issued_book_isbn;
    
    IF v_status = 'yes' THEN
		INSERT INTO issued_status(issued_id,issued_member_id,issued_book_name,issued_date,issued_book_isbn,issued_emp_id)
        VALUES(p_issued_id, p_issued_member_id, p_issued_book_name, CURRENT_DATE(), p_issued_book_isbn, p_issued_emp_id);
        
        SELECT CONCAT('The book titled ', p_issued_book_name, ' with isbn: ', p_issued_book_isbn,' is successfully issued !') AS message;
        
        UPDATE books
        SET `status` = 'no'
        WHERE isbn = p_issued_book_isbn;
	
    ELSE
		SELECT CONCAT('Sorry! The book with titled ',p_issued_book_name, ' is currently unavailable') AS message;
	END IF;
END $$
DELIMITER ;


CALL add_book_issuance('IS145', 'C107','Where the Wild Things Are', '978-0-06-025492-6', 'E104');

CALL add_book_issuance('IS146', 'C107','The Diary of a Young Girl', '978-0-375-41398-8', 'E104');

CALL add_book_issuance('IS147', 'C105','To Kill a Mockingbird', '978-0-06-112008-4', 'E104');

SELECT *
FROM issued_status;


/*Task 20: Create Table As Select (CTAS) 
Objective: Create a CTAS (Create Table As Select) query to 
identify overdue books and calculate fines. Description: Write a CTAS query to create a new table that 
lists each member and the books they have issued but not returned within 30 days. 
The table should include: The number of overdue books. The total fines, with each day's 
fine calculated at $0.50. The number of books issued by each member. The resulting table 
should show: Member ID Number of overdue books Total fines*/

CREATE TABLE fines_for_overdue(
SELECT iss.issued_member_id, COUNT(*) AS NO_OF_OVERDUE_BOOKS, SUM(datediff(CURRENT_DATE, iss.issued_date)) as Sum_of_overdue_days, 
SUM(datediff(CURRENT_DATE, iss.issued_date))* 0.5 AS fines_per_member
FROM members as mem
JOIN issued_status as iss
	ON mem.member_id = iss.issued_member_id
LEFT JOIN return_status as rs
	ON rs.issued_id = iss.issued_id
WHERE rs.return_id IS NULL AND 
		(CURRENT_DATE() - INTERVAL 30 DAY )> 30
GROUP BY iss.issued_member_id);
    
ALTER TABLE fines_for_overdue
RENAME TO overdue_books_fines;
