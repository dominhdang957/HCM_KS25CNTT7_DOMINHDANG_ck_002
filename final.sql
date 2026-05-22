CREATE DATABASE management_safe_db;
USE management_safe_db;

CREATE TABLE customers (
	customer_id VARCHAR(10) PRIMARY KEY ,
    customer_name VARCHAR(20) NOT NULL,
    phone VARCHAR(11) UNIQUE NOT NULL,
    email VARCHAR(255),
    join_date DATE DEFAULT(CURRENT_DATE)
);

CREATE TABLE insurance_packages (
	package_id VARCHAR(10) PRIMARY KEY ,
    package_name VARCHAR(50) NOT NULL,
    max_limit DECIMAL(15,0) DEFAULT 0,
    base_premium DECIMAL(15,0),
    CONSTRAINT ck_max_limit CHECK(max_limit > 0)
);

CREATE TABLE policies (
	policy_id VARCHAR(10) PRIMARY KEY ,
    customer_id VARCHAR(10) NOT NULL,
    package_id VARCHAR(10) NOT NULL,
    start_date DATE,
    end_date DATE,
    status ENUM('Active','Expired','Cancelled'),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (package_id) REFERENCES insurance_packages(package_id)
);

CREATE TABLE claims (
	claim_id VARCHAR(10) PRIMARY KEY ,
    policy_id VARCHAR(10) NOT NULL,
    claim_date DATE,
    claim_amount DECIMAL(15,0) DEFAULT 0,
    status ENUM('Pending','Approved','Rejected'),
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id),
    CONSTRAINT ck_claim_amount CHECK(claim_amount > 0)
);

CREATE TABLE claim_processing_log (
	log_id VARCHAR(10) PRIMARY KEY ,
    claim_id VARCHAR(10) NOT NULL,
    action_detail TEXT NOT NULL,
    recorded_at DATETIME DEFAULT (CURRENT_TIMESTAMP),
    processor VARCHAR(50) NOT NULL,
    FOREIGN KEY (claim_id) REFERENCES claims(claim_id)
);

INSERT INTO customers 
VALUES 
('C001','Nguyen Hoang Long',09044535545,'long.nh@gmail.com','2024-01-15'),
('C002','Tran Thi Kim Anh',090777755545,'anh.th@gmail.com','2024-03-10'),
('C003','Le Hoang Nam',09333344545,'nam.nh@gmail.com','2025-05-20'),
('C004','Pham Minh Duc',04488585545,'duc.nh@gmail.com','2025-08-12'),
('C005','Hoang Thu Thao',090999995,'thao.nh@gmail.com','2026-05-1');

INSERT INTO insurance_packages
VALUES
('PKG01','Bảo hiểm sức khỏe Gold',5000000000,5000000),
('PKG02','Bảo hiểm oto Liberty',10000000000,15000000),
('PKG03','Bảo hiểm nhân thọ An Bình',20000000000,25000000),
('PKG04','Bảo hiểm du lịch quốc tế',1000000000,1000000),
('PKG05','Bảo hiểm tai nạn 24/7',2000000000,2000000);

INSERT INTO policies 
VALUES 
('POL101','C001','PKG01','2024-01-15','2025-01-15','Expired'),
('POL102','C002','PKG02','2024-03-10','2026-03-10','Active'),
('POL103','C003','PKG03','2025-05-20','2035-05-20','Active'),
('POL104','C004','PKG04','2025-08-12','2025-09-12','Expired'),
('POL105','C005','PKG05','2026-01-01','2027-01-01','Active');

INSERT INTO claims 
VALUES 
('CLM901','POL102','2024-06-15',12000000,'Approved'),
('CLM902','POL103','2025-10-20',50000000,'Pending'),
('CLM903','POL101','2024-11-05',5500000,'Approved'),
('CLM904','POL105','2026-01-15',2000000,'Rejected'),
('CLM905','POL102','2025-02-10',120000000,'Approved');

INSERT INTO claim_processing_log 
VALUES 
('L001','CLM901','Đã nhận hồ sơ hiện trường','2024-06-15 09:00','Admin_01'),
('L002','CLM901','Chấp nhận bồi thường xe tai nạn','2024-06-20 14:30','Admin_01'),
('L003','CLM902','Đã thẩm định hồ sơ bệnh án','2025-10-21 10:00','Admin_02'),
('L004','CLM904','Từ chối do lỗi cố ý của khách hàng','2026-01-16 16:00','Admin_03'),
('L005','CLM905','Đã thanh toán qua chuyển khoản','2025-02-15 08:30','Accountant_01');

SELECT * FROM policies;
-- câu 1
SELECT * FROM policies WHERE  YEAR(end_date) = 2026;



-- câu 2 
SELECT * FROM customers;
SELECT customer_id,customer_name,phone,email FROM customers
WHERE customer_name LIKE '%Hoang%' AND YEAR(join_date) >= 2025;

-- câu 3 
SELECT * FROM claim_processing_log;
SELECT * FROM claims;

SELECT CPL.claim_id,CPL.action_detail,C.claim_amount FROM claim_processing_log CPL
JOIN claims C ON C.claim_id = CPL.claim_id
ORDER BY C.claim_amount DESC
LIMIT 3 
OFFSET 1;

-- truy vấn dữ liêu nâng cao
-- câu 1
SELECT * FROM customers;
SELECT * FROM policies;
SELECT C.customer_name,IP.package_name,P.start_date FROM customers C
JOIN  policies P ON P.customer_id = C.customer_id
JOIN insurance_packages IP ON IP.package_id = P.package_id;

-- câu 2 
SELECT * FROM customers;
SELECT * FROM claims;

SELECT C.customer_name,CL.claim_amount FROM customers C
JOIN  policies P ON P.customer_id = C.customer_id
JOIN claims CL ON CL.policy_id = P.policy_id 
WHERE CL.status = 'Approved' AND CL.claim_amount > 50000000;

-- CÂU 3
SELECT * FROM insurance_packages;
SELECT * FROM policies;
SELECT  IP.package_name,COUNT(P.customer_id)  FROM insurance_packages IP
JOIN policies P ON P.package_id = IP.package_id 
GROUP BY package_name;

-- INDEX VÀ VIEW
-- câu 1
CREATE INDEX idx_policy_status_date ON policies(start_date,status);

-- câu 2
SELECT * FROM insurance_packages;
CREATE VIEW  vw_customer_summary 
AS
SELECT customer_name,COUNT(policy_id) total_policy,SUM(base_premium) total_payment
FROM customers C
JOIN policies P ON P.customer_id = C.customer_id
JOIN insurance_packages IP ON IP.package_id = P.package_id
GROUP BY customer_name;

SELECT * FROM vw_customer_summary;

SELECT * FROM claims;
SELECT * FROM claim_processing_log;
-- PHẦN 5 TRIGGER 
DELIMITER //
CREATE TRIGGER tg_after_claim_approved
AFTER UPDATE ON claims
FOR EACH ROW

BEGIN 
		DECLARE v_count INT;
        SELECT COUNT(*) INTO v_count FROM claims WHERE NEW.status = 'Approved';
        IF v_count > 0 THEN UPDATE claim_processing_log SET action_detail = 'Payment processed to customer' WHERE claim_id = NEW.claim_id;
        END IF;
END //
DELIMITER ;
DROP TRIGGER tg_after_claim_approved;
UPDATE claims SET status = 'Approved' WHERE claim_id = 'CLM902';

-- CÂu 2
SELECT * FROM policies;
DELIMITER //
CREATE TRIGGER tg_before_policies_delete
BEFORE DELETE ON policies
FOR EACH ROW

BEGIN 
    IF OLD.status = 'Active' THEN 
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bạn không thể xóa hợp đồng đang hoạt động';
    END IF;
END //
DELIMITER ;
DELETE FROM policies 
WHERE policy_id = 'POL101';

-- phân 6 
-- Câu 1
SELECT * FROM claim_processing_log;
	SELECT * FROM claims;
    SELECT * FROM insurance_packages;
DELIMITER //
CREATE PROCEDURE sp_check_claim_limit (
IN p_claim_id VARCHAR(10),
OUT p_message VARCHAR(255)
)
BEGIN 
	DECLARE p_price_amount DECIMAL(15,0);
    SELECT claim_amount INTO p_price_amount FROM claims WHERE claim_id = p_claim_id;
END //
DELIMITER ;

-- câu 2
DELIMITER //
CREATE PROCEDURE sp_cancel_policy ()
BEGIN 
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT ='ĐÃ ROLLBACK VỀ LẠI TỪ ĐẦU';
    END ;
	START TRANSACTION;
    UPDATE policies 
    SET status = 'Cancelled';
    UPDATE claim_processing_log 
    SET action_detail = 'Customer requested cancellation';
    COMMIT;
END //
DELIMITER ;