# Phase 5 — Tests & Finalisation
**Durée estimée : 2-3 jours**
**Prérequis : Phases 1 à 4 validées**

---

## 🎯 Objectif de la phase
Valider que l'application fonctionne de bout en bout, corriger les bugs restants,
nettoyer le code et préparer tous les livrables du projet.

---

## Étape 5.1 — Tests Backend avec Postman
**Durée : 3-4 heures**

### Objectif
Tester systématiquement chaque endpoint de l'API avant de valider le backend.

### Ce que tu dois produire
Une **collection Postman complète** exportée en JSON, avec :

**Organisation de la collection :**
```
Smart CRM API
├── Auth
│   └── POST /api/auth/login
├── Customers
│   ├── GET    /api/customers
│   ├── GET    /api/customers/:id
│   ├── POST   /api/customers
│   ├── PUT    /api/customers/:id
│   └── DELETE /api/customers/:id
├── Interactions
│   ├── POST   /api/interactions
│   └── GET    /api/interactions/customer/:id
├── Segments
│   ├── GET    /api/segments
│   ├── POST   /api/segments
│   ├── POST   /api/segments/:id/customers/:customerId
│   └── DELETE /api/segments/:id/customers/:customerId
├── Campaigns
│   ├── GET    /api/campaigns
│   ├── POST   /api/campaigns
│   └── POST   /api/campaigns/:id/send
├── Scores
│   ├── GET    /api/scores
│   └── GET    /api/scores/compute-all
├── AI
│   ├── POST   /api/ai/generate-email
│   └── POST   /api/ai/suggest-segment
└── Dashboard
    └── GET    /api/dashboard/stats
```

**Pour chaque endpoint, tester :**
- ✅ Cas nominal (données valides → 200/201)
- ❌ Ressource inexistante → 404 avec message
- ❌ Données invalides → 400 avec détails de validation
- 🔒 Sans token → 401 Unauthorized
- 🔒 Token avec rôle insuffisant → 403 Forbidden

**Variables d'environnement Postman à créer :**
```json
{
  "baseUrl": "http://localhost:8080",
  "token": "{{copié après login}}",
  "customerId": "{{id d'un client de test}}"
}
```

**Script Postman pour auto-récupérer le token :**
```javascript
// Dans les Tests de POST /api/auth/login
pm.test("Login successful", function () {
    pm.response.to.have.status(200);
    const token = pm.response.json().token;
    pm.environment.set("token", token);
});
```

### Checklist de test backend
- [ ] Login retourne un JWT valide
- [ ] CRUD complet des clients fonctionne
- [ ] L'ajout d'une interaction est tracé correctement
- [ ] L'assignation client-segment fonctionne dans les deux sens
- [ ] Le calcul de score modifie bien la BDD
- [ ] L'envoi de campagne crée des EmailLogs pour chaque client du segment
- [ ] La génération IA retourne un texte cohérent
- [ ] Les 404 et 400 ont des messages en JSON (pas de stack traces)

---

## Étape 5.2 — Tests unitaires Java
**Durée : 3-4 heures**

### Objectif
Écrire des tests unitaires pour la logique métier critique.

### Ce que tu dois tester (dans `src/test/`)

**ScoringServiceTest :**
```java
@ExtendWith(MockitoExtension.class)
class ScoringServiceTest {

    @Mock private CustomerRepository customerRepository;
    @Mock private InteractionRepository interactionRepository;
    @Mock private CustomerScoreRepository scoreRepository;

    @InjectMocks private ScoringService scoringService;

    @Test
    void computeScore_clientAvecBeaucoupInteractions_doitEtreFidele() { ... }

    @Test
    void computeScore_clientSansInteraction_doitEtreARisque() { ... }

    @Test
    void computeScore_clientInactif_doitEtreARisque() { ... }
}
```

**CustomerServiceTest :**
```java
@Test
void createCustomer_emailDejaExistant_doitLancerException() { ... }

@Test
void deleteCustomer_idInexistant_doitLancerCustomerNotFoundException() { ... }
```

### Points d'attention
- Utiliser `@ExtendWith(MockitoExtension.class)` pour les tests unitaires
- `@Mock` pour les dépendances, `@InjectMocks` pour la classe testée
- Tester les cas nominaux ET les cas d'erreur
- Les tests doivent être rapides (pas de BDD réelle)

---

## Étape 5.3 — Tests d'intégration Angular (E2E manuel)
**Durée : 2-3 heures**

### Objectif
Vérifier tous les flux utilisateur de bout en bout dans le navigateur.

### Scénarios à tester

**Scénario 1 — Flux Commercial**
```
1. Se connecter avec un compte ROLE_COMMERCIAL
2. Vérifier que le dashboard s'affiche correctement
3. Créer un nouveau client
4. Ajouter une interaction à ce client
5. Vérifier que l'interaction apparaît dans la timeline
6. Se déconnecter → vérifier la redirection vers /login
7. Rafraîchir la page → vérifier que le token expiré redirige vers /login
```

**Scénario 2 — Flux Admin**
```
1. Se connecter avec un compte ROLE_ADMIN
2. Créer un nouveau segment
3. Assigner plusieurs clients à ce segment
4. Créer une campagne pour ce segment
5. Générer le contenu email avec l'IA (vérifier le spinner)
6. Modifier le contenu généré
7. Envoyer la campagne
8. Vérifier les EmailLogs côté backend (Postman ou BDD)
```

**Scénario 3 — Calcul de score**
```
1. Ajouter 5 interactions récentes à un client
2. Déclencher "Recalculer tous les scores" depuis le module Scores
3. Vérifier que le score du client a changé
4. Vérifier le badge sur la liste des clients
5. Vérifier l'historique des scores dans la fiche client
```

**Scénario 4 — Gestion des erreurs**
```
1. Essayer d'accéder à /customers sans être connecté → redirection /login
2. Soumettre un formulaire avec des champs vides → messages de validation
3. Créer un client avec un email déjà existant → message d'erreur
4. Éteindre Ollama et cliquer "Générer avec IA" → message d'erreur clair
```

---

## Étape 5.4 — Nettoyage et qualité du code
**Durée : 2-3 heures**

### Objectif
Rendre le code lisible, maintenable et prêt à être présenté.

### Checklist de nettoyage

**Backend Java :**
- [ ] Supprimer tous les `System.out.println()` → utiliser `@Slf4j` + `log.info()`
- [ ] Supprimer les imports inutilisés
- [ ] Vérifier que tous les TODO sont résolus ou commentés
- [ ] Chaque classe a un commentaire Javadoc sur son rôle
- [ ] Les constantes sont dans des fichiers constants (pas de magic numbers)
- [ ] Les mots de passe ne sont **jamais** en dur dans le code

**Frontend Angular :**
- [ ] Supprimer les `console.log()` de debug
- [ ] Vérifier que tous les Observables sont correctement détruits (`takeUntilDestroyed`)
- [ ] Les composants ont des commentaires sur leur rôle
- [ ] Pas de code mort (méthodes jamais appelées)
- [ ] Les erreurs HTTP sont toutes gérées avec `catchError`

**BDD :**
- [ ] Le `data.sql` contient uniquement des données de test cohérentes
- [ ] Les mots de passe dans `data.sql` sont hashés avec BCrypt

---

## Étape 5.5 — Documentation (README.md)
**Durée : 2-3 heures**

### Objectif
Rédiger un README complet pour que n'importe qui puisse installer et lancer le projet.

### Structure du README.md

```markdown
# Smart CRM

## Description
[Présentation du projet en 3-4 phrases]

## Stack technique
[Tableau avec toutes les technologies et versions]

## Prérequis
[Ce qui doit être installé avant de commencer]
- Java 21
- Node.js 20+
- MySQL 8.x
- Ollama + Mistral

## Installation

### 1. Cloner le projet
### 2. Configurer la base de données
### 3. Configurer application.properties
### 4. Démarrer Ollama
### 5. Lancer le backend
### 6. Lancer le frontend

## Comptes de test
| Email                    | Mot de passe | Rôle        |
|--------------------------|--------------|-------------|
| admin@smartcrm.com       | Admin123!    | ROLE_ADMIN  |
| commercial@smartcrm.com  | Comm123!     | ROLE_COMMERCIAL |

## Fonctionnalités principales
[Liste des features avec captures d'écran si possible]

## Architecture
[Schéma simplifié de l'architecture]

## Diagrammes UML
[Références aux fichiers de diagrammes]
```

---

## Étape 5.6 — Liste des outils avec versions
**Durée : 30 minutes**

### Ce que tu dois produire
Un fichier `TOOLS.md` avec la liste exacte des outils et versions utilisées :

```markdown
# Outils et versions

## Backend
- Java : 21.x.x
- Spring Boot : 3.x.x
- Spring AI : 1.0.x
- MapStruct : 1.6.x
- JJWT : 0.12.x
- Lombok : 1.18.x
- MySQL Connector : 8.x.x

## Frontend
- Node.js : 20.x.x
- npm : 10.x.x
- Angular : 20.x.x
- Angular Material : 20.x.x
- Chart.js : 4.x.x

## Base de données
- MySQL : 8.x.x

## IA
- Ollama : x.x.x
- Mistral : 7B

## Outils de développement
- IntelliJ IDEA : version
- VS Code : version
- Postman : version
- draw.io : version
```

---

## Étape 5.7 — Diagrammes UML finaux
**Durée : 1-2 heures**

### Objectif
S'assurer que les diagrammes correspondent exactement au code produit.

### Ce que tu dois vérifier
- Le diagramme de classes reflète les entités JPA réelles (avec leurs relations)
- Le diagramme de cas d'utilisation correspond aux endpoints implémentés
- Les enums dans les diagrammes correspondent aux enums Java

### Ce que tu dois exporter
- `diagrams/class-diagram.png` (ou .svg)
- `diagrams/use-case-diagram.png`
- `diagrams/schema-bdd.png` (schéma SQL visualisé)

---

## Étape 5.8 — Vidéo de démonstration
**Durée : 2-3 heures**

### Objectif
Enregistrer une démonstration complète de l'application.

### Plan de la vidéo (10-15 minutes recommandées)

```
Introduction (1 min)
  → Présentation du projet et de la stack

Démonstration Admin (5-6 min)
  → Login en tant qu'Admin
  → Dashboard : KPIs et graphiques
  → Gestion des segments (création, assignation)
  → Création d'une campagne email avec IA
  → Envoi de la campagne
  → Visualisation des logs email

Démonstration Commercial (3-4 min)
  → Login en tant que Commercial
  → Création d'un client
  → Ajout d'interactions
  → Consultation du score avec badge
  → Fiche client complète

Démonstration technique (2-3 min)
  → Console Spring Boot pendant un envoi
  → Réponse JSON de l'API (Postman)
  → BDD MySQL après les opérations
```

### Outils recommandés
- OBS Studio (gratuit, Windows/Mac/Linux)
- Résolution : 1920x1080
- Format : MP4

---

## ✅ Checklist finale de livraison

- [ ] `README.md` complet et testé (installation possible depuis zéro)
- [ ] `TOOLS.md` avec toutes les versions
- [ ] Collection Postman exportée (`smart-crm-api.postman_collection.json`)
- [ ] Diagrammes UML finaux dans le dossier `diagrams/`
- [ ] Code backend nettoyé (plus de console.log, imports inutilisés)
- [ ] Code frontend nettoyé
- [ ] Tests unitaires qui passent (`mvn test`)
- [ ] L'application fonctionne de bout en bout (login → campagne IA → envoi)
- [ ] Vidéo de démonstration enregistrée
- [ ] Le projet est commité et pushé sur Git avec un `.gitignore` correct

---

## 🎓 Bilan d'apprentissage

À la fin de ce projet, tu dois être capable d'expliquer :

**Architecture :**
- Pourquoi séparer Frontend/Backend ?
- Qu'est-ce qu'une API REST et comment fonctionne-t-elle ?
- Quel est le rôle des DTOs vs Entités ?

**Backend Java 21 / Spring Boot :**
- Comment fonctionne JPA / Hibernate ?
- Comment Spring Security protège-t-il les routes ?
- Qu'est-ce qu'un JWT et comment est-il validé ?
- Pourquoi utiliser MapStruct plutôt que mapper à la main ?

**Frontend Angular 20 :**
- Que sont les Signals et en quoi diffèrent-ils de RxJS ?
- Comment fonctionnent les Standalone Components ?
- Quel est le rôle d'un Interceptor HTTP ?
- Comment un AuthGuard protège-t-il une route ?

**IA :**
- Comment Ollama fait-il tourner un LLM localement ?
- Qu'est-ce que le Prompt Engineering ?
- Quelles sont les limites d'un LLM local vs une API cloud ?
