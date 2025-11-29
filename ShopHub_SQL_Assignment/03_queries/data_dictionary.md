# SHOPHUB (OLIST) DATA DICTIONARY
Version: 1.0
Author: Yashashri Pawar
Description: Complete documentation of all tables used in the ShopHub Analytics Database.

------------------------------------------------------------
TABLE: customers
------------------------------------------------------------
customer_id                VARCHAR     Primary key, unique per order
customer_unique_id         VARCHAR     Real unique customer identifier
customer_zip_code_prefix   INT         First 5 digits of customer ZIP code
customer_city              VARCHAR     Customer city
customer_state             CHAR(2)     Customer state (e.g., SP, RJ)

------------------------------------------------------------
TABLE: orders
------------------------------------------------------------
order_id                       VARCHAR      Primary key
customer_id                    VARCHAR      FK → customers.customer_id
order_status                   VARCHAR      Current status of order
order_purchase_timestamp       DATETIME     When the order was placed
order_approved_at              DATETIME     When the order was paid
order_delivered_carrier_date   DATETIME     Seller passed package to carrier
order_delivered_customer_date  DATETIME     Order delivered to customer
order_estimated_delivery_date  DATETIME     System-predicted delivery date

------------------------------------------------------------
TABLE: order_items
------------------------------------------------------------
order_id             VARCHAR      FK → orders.order_id
order_item_id        INT          Item line number (composite PK)
product_id           VARCHAR      FK → products.product_id
seller_id            VARCHAR      FK → sellers.seller_id
shipping_limit_date  DATETIME     Deadline for seller to ship
price                DECIMAL      Product price
freight_value        DECIMAL      Shipping charge
PRIMARY KEY (order_id, order_item_id)

------------------------------------------------------------
TABLE: products
------------------------------------------------------------
product_id                  VARCHAR      Primary key
product_category_name       VARCHAR      Product category
product_name_length         INT          Character count of name
product_description_length  INT          Character count of description
product_photos_qty          INT          Number of images
product_weight_g            INT          Weight in grams
product_length_cm           INT          Length in cm
product_height_cm           INT          Height in cm
product_width_cm            INT          Width in cm

------------------------------------------------------------
TABLE: sellers
------------------------------------------------------------
seller_id             VARCHAR      Primary key
seller_zip_code_prefix INT         ZIP code prefix
seller_city           VARCHAR      City 
seller_state          CHAR(2)      State code

------------------------------------------------------------
TABLE: order_payments
------------------------------------------------------------
order_id              VARCHAR      FK → orders.order_id
payment_sequential    INT          Payment number (1 = first)
payment_type          VARCHAR      Method (credit card, boleto, etc.)
payment_installments  INT          Number of installments
payment_value         DECIMAL      Amount paid
PRIMARY KEY (order_id, payment_sequential)

------------------------------------------------------------
TABLE: order_reviews
------------------------------------------------------------
review_id               VARCHAR     Primary key
order_id                VARCHAR     FK → orders.order_id
review_score            INT         Rating (1–5)
review_comment_title    VARCHAR     Short summary
review_comment_message  TEXT        Full feedback
review_creation_date    DATETIME    When customer reviewed
review_answer_timestamp DATETIME    When seller responded

------------------------------------------------------------
TABLE: geolocation
------------------------------------------------------------
geolocation_id               INT AUTO_INCREMENT  Primary key
geolocation_zip_code_prefix  INT                 ZIP prefix
geolocation_lat              DECIMAL             Latitude
geolocation_lng              DECIMAL             Longitude
geolocation_city             VARCHAR             City
geolocation_state            CHAR(2)             State code

------------------------------------------------------------
END OF DATA DICTIONARY
------------------------------------------------------------
