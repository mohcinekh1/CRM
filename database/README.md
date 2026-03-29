# Scripts SQL — Smart CRM

| Fichier | Rôle |
|---------|------|
| `schema.sql` | DDL MySQL 8 (tables + FK + contraintes), ordre phase 1. |
| `data.sql` | Données de test (segments, clients, pivot, interactions, scores, campagne). |

**Spring Boot (phase 2)** : copier ou référencer ces fichiers dans `src/main/resources/` et activer `spring.sql.init.mode=always` (voir `phase2.md`).

**Diagrammes UML (phase 1)** : `docs/smart-crm/phase1/diagrams/`.

**Note** : la phase 1.2 mentionne aussi un utilisateur admin et un commercial dans `data.sql` ; il n’y a pas encore de table `users` dans le modèle métier de la phase 1. À prévoir avec l’authentification JWT (phase 2).
