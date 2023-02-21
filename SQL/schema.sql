CREATE TABLE aisles (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	persistent_id TEXT,
	name TEXT,
	image TEXT,
	custom INTEGER DEFAULT 0,
	sort_order INTEGER,
	modification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS aisle_sort_order_index on aisles(sort_order);
CREATE INDEX IF NOT EXISTS aisle_persistent_id_index on aisles(persistent_id);

CREATE TABLE groceries (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	persistent_id TEXT,
	aisle_id INTEGER,
	language INTEGER,
	generic INTEGER,
	custom INTEGER,
	favorite INTEGER,
	name TEXT NOT NULL,
	note TEXT,
	quantity TEXT,
	unit_id INTEGER,
	modification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS groceries_name_index on groceries(name, language);

CREATE TABLE recently_used_groceries (
	grocery_id INTEGER PRIMARY KEY,
	last_used_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS recently_used_groceries_index on groceries(last_used_date);

CREATE TABLE units (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	persistent_id TEXT,
	custom INTEGER DEFAULT 0,
	name TEXT,
	plural_name TEXT,
	short_name TEXT,
	plural_short_name TEXT,
	sort_order INTEGER,
	modification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS units_sort_order_index on units(sort_order);
CREATE INDEX IF NOT EXISTS units_custom_index on units(custom);

CREATE INDEX IF NOT EXISTS units_persistent_id_index on units(persistent_id);

CREATE TABLE shoppinglists (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	persistent_id TEXT NOT NULL,
	service_id TEXT,
	source_id TEXT,
	name TEXT,
	sort_order INTEGER,
	modification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS shoppinglists_persistent_id_index on shoppinglists(persistent_id);

CREATE TABLE shoppinglist_items (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	persistent_id TEXT NOT NULL,
	shoppinglist_id INTEGER NOT NULL,
	aisle_id INTEGER,
	grocery_id INTEGER,
	name TEXT,
	note TEXT,
	checked INTEGER DEFAULT 0,
	quantity TEXT,
	unit_id INTEGER,
	sort_order INTEGER,
	modification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	checked_modification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	aisle_modification_date TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
	quantity_modification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS shoppinglist_items_index on shoppinglist_items(shoppinglist_id);
CREATE INDEX IF NOT EXISTS shoppinglist_items_grocery_id_index on shoppinglist_items(grocery_id);

CREATE TABLE shoppinglist_aisle_layout (
	shoppinglist_id INTEGER NOT NULL,
	aisle_id INTEGER NOT NULL,
	sort_order INTEGER NOT NULL,
	PRIMARY KEY(shoppinglist_id, aisle_id)
);

CREATE INDEX shoppinglist_aisle_layout_index on shoppinglist_aisle_layout(shoppinglist_id);

CREATE TABLE deleted_shoppinglist_items (
	persistent_id TEXT PRIMARY KEY NOT NULL,
	shoppinglist_id INTEGER NOT NULL,
	deletion_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS deleted_shoppinglist_items_shoppinglist_index on deleted_shoppinglist_items(shoppinglist_id);

/* Trigger */
CREATE TRIGGER groceries_insert_trigger AFTER INSERT ON groceries
WHEN new.persistent_id IS NULL
	BEGIN
		UPDATE groceries SET persistent_id=(select hex(randomblob(16))) WHERE id=new.id;
	END;
CREATE TRIGGER shoppinglists_insert_trigger AFTER INSERT ON shoppinglists
WHEN new.persistent_id IS NULL
	BEGIN
		UPDATE shoppinglists SET persistent_id=(select hex(randomblob(16))) WHERE id=new.id;
	END;
CREATE TRIGGER shoppinglist_items_insert_trigger AFTER INSERT ON shoppinglist_items
WHEN new.persistent_id IS NULL
	BEGIN
		UPDATE shoppinglist_items SET persistent_id=(select hex(randomblob(16))) WHERE id=new.id;
	END;
CREATE TRIGGER aisles_insert_trigger AFTER INSERT ON aisles
WHEN new.persistent_id IS NULL
	BEGIN
		UPDATE aisles SET persistent_id=(select hex(randomblob(16))) WHERE id=new.id;
	END;
CREATE TRIGGER units_insert_trigger AFTER INSERT ON units
WHEN new.persistent_id IS NULL
	BEGIN
		UPDATE units SET persistent_id=(select hex(randomblob(16))) WHERE id=new.id;
	END;

CREATE TRIGGER aisles_delete_trigger AFTER DELETE ON aisles
	BEGIN
		UPDATE groceries SET aisle_id=NULL WHERE aisle_id=old.id;
		UPDATE shoppinglist_items SET aisle_id=NULL WHERE aisle_id=old.id;
	END;
CREATE TRIGGER groceries_delete_trigger AFTER DELETE ON groceries
	BEGIN
		UPDATE shoppinglist_items SET grocery_id=NULL WHERE grocery_id=old.id;
	END;
CREATE TRIGGER units_delete_trigger AFTER DELETE ON units
	BEGIN
		UPDATE groceries SET unit_id=NULL, quantity=NULL WHERE unit_id=old.id;
		UPDATE shoppinglist_items SET unit_id=NULL, quantity=NULL WHERE unit_id=old.id;
	END;
CREATE TRIGGER shoppinglist_delete_trigger AFTER DELETE ON shoppinglists
	BEGIN
		DELETE FROM shoppinglist_items WHERE shoppinglist_id=old.id;
		DELETE FROM deleted_shoppinglist_items WHERE shoppinglist_id=old.id;
	END;
CREATE TRIGGER shoppinglist_items_delete_trigger AFTER DELETE ON shoppinglist_items
	BEGIN
		INSERT OR REPLACE INTO deleted_shoppinglist_items (persistent_id, shoppinglist_id) VALUES (old.persistent_id, old.shoppinglist_id);
	END;

CREATE TRIGGER aisles_modification_trigger AFTER UPDATE OF name, image ON aisles
WHEN (old.name!=new.name OR old.image!=new.image)
	BEGIN
		UPDATE aisles SET modification_date=CURRENT_TIMESTAMP WHERE id=old.id;
	END;

CREATE TRIGGER units_modification_trigger AFTER UPDATE OF name, plural_name, short_name, plural_short_name ON units
	BEGIN
		UPDATE units SET modification_date=CURRENT_TIMESTAMP WHERE id=old.id;
	END;

CREATE TRIGGER shoppinglists_modification_trigger AFTER UPDATE OF name ON shoppinglists
WHEN (old.name!=new.name)
	BEGIN
		UPDATE shoppinglists SET modification_date=CURRENT_TIMESTAMP WHERE id=old.id;
	END;

CREATE TRIGGER shoppinglist_items_modification_trigger AFTER UPDATE OF name, note, checked ON shoppinglist_items
WHEN (old.name!=new.name OR old.note!=new.note OR (old.note IS NULL AND new.note IS NOT NULL))
	BEGIN
		UPDATE shoppinglist_items SET modification_date=CURRENT_TIMESTAMP WHERE id=old.id;
	END;
CREATE TRIGGER shoppinglist_items_checked_modification_trigger AFTER UPDATE OF checked ON shoppinglist_items
WHEN (old.checked!=new.checked OR (old.checked IS NULL AND new.checked IS NOT NULL) OR (old.checked IS NOT NULL AND new.checked IS NULL))
	BEGIN
		UPDATE shoppinglist_items SET checked_modification_date=CURRENT_TIMESTAMP WHERE id=old.id;
	END;
CREATE TRIGGER shoppinglist_items_aisle_modification_trigger AFTER UPDATE OF aisle_id ON shoppinglist_items
WHEN (old.aisle_id!=new.aisle_id OR (old.aisle_id IS NULL AND new.aisle_id IS NOT NULL) OR (old.aisle_id IS NOT NULL AND new.aisle_id IS NULL))
	BEGIN
		UPDATE shoppinglist_items SET aisle_modification_date=CURRENT_TIMESTAMP WHERE id=old.id;
	END;
CREATE TRIGGER shoppinglist_items_quantity_modification_trigger AFTER UPDATE OF quantity, unit_id ON shoppinglist_items
WHEN (old.quantity!=new.quantity OR (old.quantity IS NULL AND new.quantity IS NOT NULL) OR (old.quantity IS NOT NULL AND new.quantity IS NULL) OR old.unit_id!=new.unit_id OR (old.unit_id IS NULL AND new.unit_id IS NOT NULL) OR (old.unit_id IS NOT NULL AND new.unit_id IS NULL))
	BEGIN
		UPDATE shoppinglist_items SET quantity_modification_date=CURRENT_TIMESTAMP WHERE id=old.id;
	END;