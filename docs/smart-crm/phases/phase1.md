# Phase 1 — Conception & Modélisation
**Durée estimée : 2-3 jours**
**Prérequis : aucun — c'est le point de départ**

---

## 🎯 Objectif de la phase
Avant d'écrire une seule ligne de code, concevoir l'architecture complète du système :
les entités, leurs relations, le schéma de base de données et les acteurs du système.
Un bon modèle évite 80% des problèmes de refactoring futurs.

---

## Étape 1.1 — Diagramme de classes UML
**Durée : 4-6 heures**

### Objectif
Représenter graphiquement toutes les entités du système et leurs relations.
C'est le "plan de l'architecte" avant de construire.

### Ce que tu dois produire
Un diagramme de classes UML (outil recommandé : draw.io, PlantUML ou Lucidchart) contenant :

**Entités à modéliser :**
```
Customer
├── id : Long
├── firstName : String
├── lastName : String
├── email : String
├── phone : String
├── address : String
├── customerState : CustomerState (enum)
└── createdAt : LocalDateTime

Interaction
├── id : Long
├── type : InteractionType (enum)
├── date : LocalDateTime
├── description : String
└── customer : Customer (FK)

Segment
├── id : Long
├── name : String
├── description : String
└── criteria : String

CustomerSegment  ← table pivot (Many-to-Many)
├── customer_id : Long (FK)
└── segment_id : Long (FK)

Campaign
├── id : Long
├── name : String
├── subject : String
├── body : Text
├── scheduledAt : LocalDateTime
├── status : CampaignStatus (enum)
└── segment : Segment (FK)

EmailLog
├── id : Long
├── toEmail : String
├── subject : String
├── sentAt : LocalDateTime
├── status : String
├── customer : Customer (FK)
└── campaign : Campaign (FK)

CustomerScore
├── id : Long
├── score : Integer
├── label : ScoreLabel (enum)
├── computedAt : LocalDateTime
└── customer : Customer (FK)
```

**Enums à inclure dans le diagramme :**
```
CustomerState  → ACTIF, INACTIF
InteractionType → APPEL, EMAIL, REUNION, NOTE
ScoreLabel     → FIDELE, A_RISQUE
CampaignStatus → PLANIFIEE, EN_COURS, ENVOYEE
```

**Relations à représenter :**
```
Customer    ──────< Interaction     (One-to-Many)
Customer    >────< Segment          (Many-to-Many via CustomerSegment)
Customer    ──────< CustomerScore   (One-to-Many)
Customer    ──────< EmailLog        (One-to-Many)
Segment     ──────< Campaign        (One-to-Many)
Campaign    ──────< EmailLog        (One-to-Many)
```

### Points d'attention
- Bien distinguer les cardinalités (1..*, 0..*, etc.)
- La relation Customer ↔ Segment est Many-to-Many → table pivot obligatoire
- `CustomerScore` est en One-to-Many car on garde l'historique des scores

---

## Étape 1.2 — Schéma MySQL (DDL)
**Durée : 3-4 heures**

### Objectif
Traduire le diagramme UML en scripts SQL concrets.
Spring Boot chargera ces scripts automatiquement au démarrage.

### Ce que tu dois produire

**Fichier `schema.sql`** — scripts `CREATE TABLE` dans l'ordre des dépendances :

Ordre de création (respecter les FK) :
1. `customers`
2. `segments`
3. `interactions`
4. `customer_segments` (pivot)
5. `campaigns`
6. `email_logs`
7. `customer_scores`

Chaque table doit avoir :
- Clé primaire `id BIGINT AUTO_INCREMENT PRIMARY KEY`
- Clés étrangères avec `FOREIGN KEY ... REFERENCES ...`
- Contraintes `NOT NULL` sur les champs obligatoires
- `UNIQUE` sur `customers.email`
- `ON DELETE CASCADE` sur les tables enfants

**Fichier `data.sql`** — données initiales :
- 1 utilisateur admin
- 1 utilisateur commercial
- 3 segments de base (ex: "Nouveaux clients", "Clients fidèles", "Clients à risque")
- 5 clients de test avec états variés

### Points d'attention
- L'ordre de création des tables est crucial (les FK doivent pointer vers des tables existantes)
- MySQL 8 : utiliser `ENGINE=InnoDB` pour le support des FK
- Les enums MySQL : utiliser `ENUM('VAL1', 'VAL2')` ou `VARCHAR` (préférer VARCHAR pour la flexibilité)
- Spring Boot config à ajouter dans `application.properties` :
  ```properties
  spring.sql.init.mode=always
  spring.jpa.hibernate.ddl-auto=validate
  ```

---

## Étape 1.3 — Diagramme de cas d'utilisation
**Durée : 2-3 heures**

### Objectif
Définir **qui fait quoi** dans le système.
Les cas d'utilisation servent de référence pour créer les endpoints REST et les permissions de sécurité.

### Ce que tu dois produire
Un diagramme UML de cas d'utilisation avec :

**Acteurs :**
```
Commercial → utilisateur terrain, gère ses clients
Admin      → gère la configuration globale du CRM
Système    → actions automatiques (scheduler)
```

**Cas d'utilisation par acteur :**

```
Commercial :
├── Se connecter
├── Créer un client
├── Modifier un client
├── Voir la fiche client
├── Ajouter une interaction
├── Voir les interactions d'un client
├── Voir le score d'un client
└── Voir son tableau de bord

Admin :
├── Tout ce que fait le Commercial
├── Gérer les segments (CRUD)
├── Assigner un client à un segment
├── Créer une campagne email
├── Envoyer une campagne
├── Générer un email avec l'IA
├── Voir les logs d'emails
└── Voir le tableau de bord global

Système (automatique) :
├── Calculer les scores (chaque nuit à 2h)
└── Envoyer les emails automatiques (chaque matin à 8h)
```

### Points d'attention
- Les cas d'utilisation du Commercial sont un sous-ensemble de ceux de l'Admin
- Les actions du Système ne nécessitent pas d'authentification (scheduler interne)
- Ce diagramme sera directement utilisé pour configurer Spring Security (Phase 2)

---

## ✅ Critères de validation de la Phase 1

Avant de passer à la Phase 2, vérifie que :

- [ ] Le diagramme UML contient toutes les entités avec leurs attributs et types
- [ ] Toutes les relations sont représentées avec les bonnes cardinalités
- [ ] Les enums sont définis dans le diagramme
- [ ] Le fichier `schema.sql` crée toutes les tables dans le bon ordre
- [ ] Les clés étrangères et contraintes sont correctement définies
- [ ] Le fichier `data.sql` contient des données de test cohérentes
- [ ] Le diagramme de cas d'utilisation couvre tous les acteurs et leurs actions
- [ ] Tu peux expliquer chaque entité et relation sans regarder tes notes

---

## 📚 Ressources recommandées
- [draw.io](https://draw.io) → diagrammes UML gratuits en ligne
- [PlantUML](https://plantuml.com) → diagrammes en code (alternatif)
- MySQL 8 Documentation → [dev.mysql.com](https://dev.mysql.com/doc/)
- Spring Boot SQL Init → [docs.spring.io](https://docs.spring.io/spring-boot/docs/current/reference/html/howto.html#howto.data-initialization)
