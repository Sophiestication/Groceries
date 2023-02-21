DROP TABLE IF EXISTS autocomplete;

CREATE VIRTUAL TABLE autocomplete USING fts4(name, prefix="1,2,4", languageid="language", tokenize="unicode61");

DROP TRIGGER IF EXISTS groceries_insert_trigger;
DROP TRIGGER IF EXISTS groceries_update_trigger;
DROP TRIGGER IF EXISTS groceries_delete_trigger;

INSERT INTO autocomplete (docid, name, language) select id AS docid, name, language FROM groceries;

INSERT OR REPLACE INTO recently_used_groceries SELECT grocery_id, CURRENT_TIMESTAMP FROM shoppinglist_items WHERE grocery_id IS NOT NULL;
INSERT OR REPLACE INTO recently_used_groceries SELECT id, CURRENT_TIMESTAMP FROM groceries WHERE favorite=1;
CREATE INDEX IF NOT EXISTS groceries_name_index on groceries(name, language);

CREATE TRIGGER groceries_insert_trigger AFTER INSERT ON groceries
	BEGIN
		INSERT INTO autocomplete (docid, name, language) VALUES (new.id, new.name, new.language);
		UPDATE groceries SET persistent_id=(select hex(randomblob(16))) WHERE id=new.id AND persistent_id IS NULL;
	END;
CREATE TRIGGER groceries_update_trigger AFTER UPDATE ON groceries
	BEGIN
		DELETE FROM autocomplete WHERE docid=old.id AND language=old.language;
		INSERT INTO autocomplete (docid, name, language) VALUES (new.id, new.name, new.language);
	END;
CREATE TRIGGER groceries_delete_trigger AFTER DELETE ON groceries
	BEGIN
		UPDATE shoppinglist_items SET grocery_id=NULL WHERE grocery_id=old.id;
		DELETE FROM autocomplete WHERE docid=old.id  AND language=old.language;
	END;