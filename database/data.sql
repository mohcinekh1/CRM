-- ============================================================
--  Smart CRM — data.sql
--  Phase 1.2 — Données initiales & de test
-- ============================================================

-- ============================================================
-- SEGMENTS DE BASE (3)
-- ============================================================
INSERT INTO segments (name, description, criteria) VALUES
('Nouveaux clients',  'Clients créés depuis moins de 30 jours',       'created_at >= NOW() - INTERVAL 30 DAY'),
('Clients fidèles',   'Clients actifs avec score élevé (FIDELE)',      'customer_state = ''ACTIF'' AND label = ''FIDELE'''),
('Clients à risque',  'Clients inactifs ou avec score faible (A_RISQUE)', 'customer_state = ''INACTIF'' OR label = ''A_RISQUE''');

-- ============================================================
-- CLIENTS DE TEST (5)
-- ============================================================
INSERT INTO customers (first_name, last_name, email, phone, address, customer_state, created_at) VALUES
('Alice',   'Martin',   'alice.martin@email.com',   '0601020304', '12 rue de Paris, 75001 Paris',        'ACTIF',   NOW() - INTERVAL 5 DAY),
('Bob',     'Dupont',   'bob.dupont@email.com',     '0605060708', '34 avenue Victor Hugo, 69001 Lyon',   'ACTIF',   NOW() - INTERVAL 60 DAY),
('Clara',   'Bernard',  'clara.bernard@email.com',  '0609101112', '56 boulevard Gambetta, 13001 Marseille', 'INACTIF', NOW() - INTERVAL 120 DAY),
('David',   'Leclerc',  'david.leclerc@email.com',  '0613141516', '78 rue Nationale, 31000 Toulouse',    'ACTIF',   NOW() - INTERVAL 200 DAY),
('Emma',    'Rousseau', 'emma.rousseau@email.com',  '0617181920', '90 rue de la Liberté, 59000 Lille',   'INACTIF', NOW() - INTERVAL 15 DAY);

-- ============================================================
-- ASSIGNATION CLIENTS → SEGMENTS
-- ============================================================
-- Alice (id=1) → Nouveaux clients
INSERT INTO customer_segments (customer_id, segment_id) VALUES (1, 1);

-- Bob (id=2) → Clients fidèles
INSERT INTO customer_segments (customer_id, segment_id) VALUES (2, 2);

-- Clara (id=3) → Clients à risque
INSERT INTO customer_segments (customer_id, segment_id) VALUES (3, 3);

-- David (id=4) → Clients fidèles
INSERT INTO customer_segments (customer_id, segment_id) VALUES (4, 2);

-- Emma (id=5) → Clients à risque
INSERT INTO customer_segments (customer_id, segment_id) VALUES (5, 3);

-- ============================================================
-- INTERACTIONS DE TEST
-- ============================================================
INSERT INTO interactions (type, date, description, customer_id) VALUES
('APPEL',   NOW() - INTERVAL 3 DAY,  'Appel de bienvenue, client très intéressé.',         1),
('EMAIL',   NOW() - INTERVAL 55 DAY, 'Envoi offre promotionnelle été.',                    2),
('REUNION', NOW() - INTERVAL 10 DAY, 'Réunion de suivi, renouvellement contrat discuté.',  2),
('NOTE',    NOW() - INTERVAL 100 DAY,'Client n\'a pas répondu aux derniers emails.',        3),
('APPEL',   NOW() - INTERVAL 180 DAY,'Rappel suite à inactivité, pas de suite.',           4);

-- ============================================================
-- SCORES DE TEST
-- ============================================================
INSERT INTO customer_scores (score, label, computed_at, customer_id) VALUES
(85, 'FIDELE',   NOW() - INTERVAL 1 DAY, 1),
(92, 'FIDELE',   NOW() - INTERVAL 1 DAY, 2),
(30, 'A_RISQUE', NOW() - INTERVAL 1 DAY, 3),
(78, 'FIDELE',   NOW() - INTERVAL 1 DAY, 4),
(25, 'A_RISQUE', NOW() - INTERVAL 1 DAY, 5);

-- ============================================================
-- CAMPAGNE DE TEST
-- ============================================================
INSERT INTO campaigns (name, subject, body, scheduled_at, status, segment_id) VALUES
(
  'Campagne Fidélisation Été',
  'Merci pour votre fidélité — Offre exclusive',
  'Bonjour, en tant que client fidèle, nous vous offrons une remise exclusive de 20% sur votre prochain achat. Profitez-en avant le 31 août !',
  NOW() + INTERVAL 2 DAY,
  'PLANIFIEE',
  2
);
