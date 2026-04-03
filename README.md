# Smart CRM

Application de gestion de la relation client : scoring, segmentation, campagnes e-mail et (plus tard) génération de contenu via **Ollama** en local.

## Stack

| Couche | Technologie |
|--------|-------------|
| Backend | Spring Boot 4.x, Java 21, Spring Data JPA |
| Base de données | MySQL (recommandé 8.x) |
| Frontend (prévu) | Angular 20 |
| Sécurité (prévu) | Spring Security + JWT |
| E-mail | Spring Mail (ex. Gmail SMTP) |
| IA (prévu) | Spring AI + Ollama |

Le détail métier et les conventions sont dans [`.context.md`](.context.md).

## Structure du dépôt

```
CRM/
├── backend/smart-crm-backend/   # API Spring Boot (Maven)
├── docs/smart-crm/              # Phases du projet, diagrammes phase 1
├── .context.md                  # Contexte produit et technique
├── AGENTS.md                    # Repères pour assistants / outils
└── .cursor/rules/               # Règles Cursor du projet
```

Plan d’implémentation : `docs/smart-crm/phases/phase1.md` → `phase5.md` (ordre strict 1 à 5).

## Prérequis

- **JDK 21** (ou version compatible avec le `pom.xml`)
- **Maven** (ou utilisation du wrapper `mvnw` dans le module backend)
- **MySQL** démarré (base `smart_crm`, créée au besoin via l’URL JDBC du projet)

## Backend : configuration locale

Les secrets (mot de passe MySQL, Gmail, clé JWT) ne doivent pas être versionnés. Utiliser le fichier **`backend/smart-crm-backend/src/main/resources/application-local.properties`** (ignoré par Git à la racine du repo via `.gitignore`).

1. Copier le modèle s’il existe (`application-local.properties.example`) ou créer `application-local.properties` à côté de `application.properties`.
2. Renseigner au minimum : `spring.datasource.username`, `spring.datasource.password`, `spring.mail.*`, `app.jwt.secret`.

Le profil actif par défaut est **`local`** (voir `application.properties`).

## Backend : lancer l’application

```bash
cd backend/smart-crm-backend
./mvnw spring-boot:run
```

Sous Windows PowerShell :

```powershell
cd backend\smart-crm-backend
.\mvnw.cmd spring-boot:run
```

L’API écoute par défaut sur **http://localhost:8080**. Les scripts **`schema.sql`** et **`data.sql`** dans `src/main/resources/` initialisent le schéma et des données de test au démarrage (selon la configuration Spring).

## Documentation

- Phases et tâches : [docs/smart-crm/phases/](docs/smart-crm/phases/)
- Index doc planification : [docs/smart-crm/README.md](docs/smart-crm/README.md)

## Licence

Projet personnel / pédagogique — préciser la licence si vous publiez le dépôt.
