-- Program Categories Seed (matches live production data)
-- Table: program_categories (id UUID PRIMARY KEY, name, description, icon, color, is_active)
-- Inserted via REST API on 2026-07-07, verified in production

INSERT INTO program_categories (id, name, description, icon, color, is_active) VALUES
('f642d6e0-b02a-4790-ba3e-08cc70a8122c', 'Agriculture & Environment', 'Agriculture, forestry, environmental science, and veterinary medicine', 'leaf', '#22C55E', true),
('95f8121d-8f2d-4b2a-be2f-edbb4a64aa74', 'Architecture & Design', 'Architecture, urban planning, construction, and real estate', 'building-2', '#F97316', true),
('aa86ac4d-c563-4d2e-a669-174ca536b940', 'Arts & Humanities', 'Literature, history, philosophy, languages, and creative arts', 'book-open', '#F59E0B', true),
('44815317-38ab-4e8b-b611-d94f3eb918c0', 'Aviation & Maritime', 'Aviation, marine engineering, and maritime transport', 'plane', '#0EA5E9', true),
('cbe38c0f-0066-4b0c-bab0-ee464630cf28', 'Business & Management', 'Finance, marketing, HR, entrepreneurship, and business administration', 'briefcase', '#3B82F6', true),
('bfbb67a5-9b0d-4357-8511-77b4b4b217e4', 'Data & Analytics', 'Data science, analytics, statistics, and business intelligence', 'bar-chart-3', '#6366F1', true),
('68b64d3b-9a9b-4f3e-8afe-27570989f193', 'Education & Teaching', 'Teacher training, educational leadership, and special education', 'chalkboard', '#6366F1', true),
('50594df3-1187-461b-bf79-6a28a2057f7e', 'Engineering & Technology', 'Civil, mechanical, electrical, software, and all engineering disciplines', 'cpu', '#10B981', true),
('6516890b-7779-4387-929a-e10a4b092a61', 'Finance & Accounting', 'Banking, accounting, investment, and financial management', 'landmark', '#059669', true),
('5e265770-a6c3-4d1a-9182-7075b8950281', 'Hospitality & Tourism', 'Hotel management, tourism, culinary arts, and event management', 'utensils', '#EAB308', true),
('8bacfcaf-75ef-4486-b080-5e805b71f00a', 'Information Technology', 'Computer science, data science, cybersecurity, AI, and software development', 'laptop', '#14B8A6', true),
('e41010c9-36fa-4670-a7dd-eb30f2f9d500', 'Law & Legal Studies', 'Law, international law, criminology, and legal practice', 'scale', '#8B5CF6', true),
('b17ee134-a7db-4a23-a15e-b317ada7e9f3', 'Media & Communication', 'Journalism, broadcasting, public relations, and digital media', 'radio', '#D946EF', true),
('e3ad1136-0529-4a56-befe-f2cef3b54f54', 'Medicine & Health Sciences', 'Medicine, nursing, pharmacy, public health, and allied health professions', 'heart-pulse', '#EF4444', true),
('e8b9ab3c-0ff6-478d-abb7-6ebecf831079', 'Nursing & Caregiving', 'Nursing, caregiving, and patient care services', 'stethoscope', '#DC2626', true),
('4a585566-30f6-405d-9510-a1c3c199f20d', 'Public Policy & Governance', 'Public administration, policy, governance, and international relations', 'landmark', '#7C3AED', true),
('5280fc0a-aa9f-4e51-8861-d97caa067af4', 'Science & Mathematics', 'Biology, chemistry, physics, mathematics, and environmental science', 'flask', '#06B6D4', true),
('69b630e8-0f64-416f-bec3-61b7dafd17b9', 'Social Sciences', 'Psychology, sociology, economics, political science, and anthropology', 'users', '#EC4899', true),
('89bab3ee-1a56-415e-b970-d4b6a50b090d', 'Sports & Fitness', 'Sports science, coaching, physical education, and sports management', 'dumbbell', '#84CC16', true),
('90dbccb1-e1f7-4771-9549-32b4d8bc500b', 'Trades & Vocational', 'Plumbing, electrical, automotive, welding, and skilled trades', 'wrench', '#78716C', true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  icon = EXCLUDED.icon,
  color = EXCLUDED.color,
  is_active = EXCLUDED.is_active;
