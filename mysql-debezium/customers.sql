use demo;
drop table IF EXISTS customers;
create table customers (
	id INT PRIMARY KEY,
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	email VARCHAR(50),
	gender VARCHAR(50),
	comments VARCHAR(90)
);
insert into customers (id, first_name, last_name, email, gender, comments) values (1, 'Bibby', 'Argabrite', 'bargabrite0@google.com.hk', 'Female', 'Reactive exuding productivity');
insert into customers (id, first_name, last_name, email, gender, comments) values (2, 'Auberon', 'Sulland', 'asulland1@slideshare.net', 'Male', 'Organized context-sensitive Graphical User Interface');
insert into customers (id, first_name, last_name, email, gender, comments) values (3, 'Marv', 'Dalrymple', 'mdalrymple2@macromedia.com', 'Male', 'Versatile didactic pricing structure');
insert into customers (id, first_name, last_name, email, gender, comments) values (4, 'Nolana', 'Yeeles', 'nyeeles3@drupal.org', 'Female', 'Adaptive real-time archive');
insert into customers (id, first_name, last_name, email, gender, comments) values (5, 'Modestia', 'Coltart', 'mcoltart4@scribd.com', 'Female', 'Reverse-engineered non-volatile success');
insert into customers (id, first_name, last_name, email, gender, comments) values (6, 'Bram', 'Acaster', 'bacaster5@pagesperso-orange.fr', 'Male', 'Robust systematic support');
insert into customers (id, first_name, last_name, email, gender, comments) values (7, 'Marigold', 'Veld', 'mveld6@pinterest.com', 'Female', 'Sharable logistical installation');
insert into customers (id, first_name, last_name, email, gender, comments) values (8, 'Ruperto', 'Matteotti', 'rmatteotti7@diigo.com', 'Male', 'Diverse client-server conglomeration');
