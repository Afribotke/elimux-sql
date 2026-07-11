-- ELIMUX INSTITUTION ONBOARDING PART 3: TRIGGERS
-- Run AFTER 08a (Tables) has been executed.
-- Reuses update_updated_at_column() defined in 01c_triggers.sql

CREATE TRIGGER update_institution_applications_updated_at
    BEFORE UPDATE ON institution_applications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_program_applications_updated_at
    BEFORE UPDATE ON program_applications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
