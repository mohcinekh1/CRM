-- ============================================================
--  Smart CRM — schema.sql
--  Phase 1.2 — Schéma MySQL (DDL)
--  Ordre de création respectant les dépendances FK
-- ============================================================

-- Désactiver temporairement les FK pour éviter les conflits au reset
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS customer_scores;
DROP TABLE IF EXISTS email_logs;
DROP TABLE IF EXISTS campaigns;
DROP TABLE IF EXISTS customer_segments;
DROP TABLE IF EXISTS interactions;
DROP TABLE IF EXISTS segments;
DROP TABLE IF EXISTS customers;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 1. TABLE : customers
-- ============================================================
CREATE TABLE customers (
    id            BIGINT          NOT NULL AUTO_INCREMENT,
    first_name    VARCHAR(100)    NOT NULL,
    last_name     VARCHAR(100)    NOT NULL,
    email         VARCHAR(255)    NOT NULL,
    phone         VARCHAR(20),
    address       VARCHAR(500),
    customer_state VARCHAR(20)   NOT NULL DEFAULT 'ACTIF',
    created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uk_customers_email (email),
    CONSTRAINT chk_customer_state CHECK (customer_state IN ('ACTIF', 'INACTIF'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 2. TABLE : segments
-- ============================================================
CREATE TABLE segments (
    id          BIGINT          NOT NULL AUTO_INCREMENT,
    name        VARCHAR(150)    NOT NULL,
    description VARCHAR(500),
    criteria    TEXT,

    PRIMARY KEY (id),
    UNIQUE KEY uk_segments_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 3. TABLE : interactions
-- ============================================================
CREATE TABLE interactions (
    id              BIGINT          NOT NULL AUTO_INCREMENT,
    type            VARCHAR(20)     NOT NULL,
    date            DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description     TEXT,
    customer_id     BIGINT          NOT NULL,

    PRIMARY KEY (id),
    CONSTRAINT fk_interactions_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE CASCADE,
    CONSTRAINT chk_interaction_type CHECK (type IN ('APPEL', 'EMAIL', 'REUNION', 'NOTE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 4. TABLE : customer_segments  (pivot Many-to-Many)
-- ============================================================
CREATE TABLE customer_segments (
    customer_id     BIGINT  NOT NULL,
    segment_id      BIGINT  NOT NULL,

    PRIMARY KEY (customer_id, segment_id),
    CONSTRAINT fk_cs_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_cs_segment
        FOREIGN KEY (segment_id) REFERENCES segments(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 5. TABLE : campaigns
-- ============================================================
CREATE TABLE campaigns (
    id              BIGINT          NOT NULL AUTO_INCREMENT,
    name            VARCHAR(200)    NOT NULL,
    subject         VARCHAR(300)    NOT NULL,
    body            TEXT            NOT NULL,
    scheduled_at    DATETIME,
    status          VARCHAR(20)     NOT NULL DEFAULT 'PLANIFIEE',
    segment_id      BIGINT          NOT NULL,

    PRIMARY KEY (id),
    CONSTRAINT fk_campaigns_segment
        FOREIGN KEY (segment_id) REFERENCES segments(id)
        ON DELETE CASCADE,
    CONSTRAINT chk_campaign_status CHECK (status IN ('PLANIFIEE', 'EN_COURS', 'ENVOYEE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 6. TABLE : email_logs
-- ============================================================
CREATE TABLE email_logs (
    id              BIGINT          NOT NULL AUTO_INCREMENT,
    to_email        VARCHAR(255)    NOT NULL,
    subject         VARCHAR(300)    NOT NULL,
    sent_at         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status          VARCHAR(50)     NOT NULL,
    customer_id     BIGINT          NOT NULL,
    campaign_id     BIGINT          NOT NULL,

    PRIMARY KEY (id),
    CONSTRAINT fk_emaillogs_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_emaillogs_campaign
        FOREIGN KEY (campaign_id) REFERENCES campaigns(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 7. TABLE : customer_scores
-- ============================================================
CREATE TABLE customer_scores (
    id              BIGINT          NOT NULL AUTO_INCREMENT,
    score           INT             NOT NULL,
    label           VARCHAR(20)     NOT NULL,
    computed_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    customer_id     BIGINT          NOT NULL,

    PRIMARY KEY (id),
    CONSTRAINT fk_scores_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE CASCADE,
    CONSTRAINT chk_score_label CHECK (label IN ('FIDELE', 'A_RISQUE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
