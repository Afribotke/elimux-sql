-- ELIMUX PAYMENTS PART 3: TRIGGERS
-- Run AFTER 07a (Tables) has been executed.
-- Reuses update_updated_at_column() defined in 01c_triggers.sql

CREATE TRIGGER update_subscribers_updated_at
    BEFORE UPDATE ON subscribers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
