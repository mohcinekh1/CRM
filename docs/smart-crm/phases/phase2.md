# Phase 2 — Backend Spring Boot
**Durée estimée : 6-8 jours**
**Prérequis : Phase 1 validée (diagrammes + schéma SQL)**

---

## 🎯 Objectif de la phase
Construire l'API REST complète avec Java 21 et Spring Boot 3.x.
Le backend expose des endpoints JSON consommés par le frontend Angular.
Il gère la logique métier, la persistance, la sécurité et les tâches automatiques.

---

## Étape 2.1 — Setup du projet
**Durée : 2-3 heures**

### Objectif
Créer un projet Spring Boot fonctionnel et correctement configuré avant d'écrire le moindre code métier.

### Ce que tu dois faire

**1. Créer le projet via [start.spring.io](https://start.spring.io)**
- Project : Maven
- Language : Java
- Spring Boot : 3.x (dernière stable)
- Java : 21
- Group : `com.smartcrm`
- Artifact : `smart-crm-backend`
- Packaging : Jar

**2. Dépendances à sélectionner :**
```
- Spring Web
- Spring Data JPA
- MySQL Driver
- Spring Security
- Spring Mail
- Lombok
- Validation
- Spring AI Ollama (ajout manuel dans pom.xml)
- MapStruct (ajout manuel dans pom.xml)
- JJWT (ajout manuel dans pom.xml — pour JWT)
```

**3. Configurer `application.properties` :**
```properties
# Base de données
spring.datasource.url=jdbc:mysql://localhost:3306/smart_crm
spring.datasource.username=root
spring.datasource.password=ton_mot_de_passe
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA / Hibernate
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect

# SQL Init
spring.sql.init.mode=always

# Mail (Gmail SMTP)
spring.mail.host=smtp.gmail.com
spring.mail.port=587
spring.mail.username=ton_email@gmail.com
spring.mail.password=ton_app_password
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true

# Ollama
spring.ai.ollama.base-url=http://localhost:11434
spring.ai.ollama.chat.model=mistral

# JWT
app.jwt.secret=ta_cle_secrete_longue_minimum_256_bits
app.jwt.expiration=86400000
```

**4. Configurer CORS** (pour autoriser Angular) :
- Créer une classe `CorsConfig` dans le package `config/`
- Autoriser l'origine `http://localhost:4200`

### Points d'attention
- Utiliser un fichier `.env` ou `application-local.properties` pour les mots de passe (ne jamais commit en clair)
- Java 21 : tu peux utiliser les Records pour certains DTOs simples
- Vérifier que MySQL est démarré avant de lancer le projet

---

## Étape 2.2 — Entités JPA
**Durée : 4-5 heures**

### Objectif
Créer les classes Java qui représentent les tables MySQL.
JPA (via Hibernate) fera le mapping automatiquement.

### Concepts clés
- `@Entity` → marque la classe comme une table BDD
- `@Table(name = "...")` → nom de la table
- `@Id` + `@GeneratedValue` → clé primaire auto-incrémentée
- `@Column` → personnalise une colonne
- `@ManyToOne`, `@OneToMany`, `@ManyToMany` → relations

### Ce que tu dois créer (dans `entities/`)

**Ordre de création recommandé** (des moins dépendantes aux plus dépendantes) :
1. `Customer.java`
2. `Segment.java`
3. `Interaction.java`
4. `Campaign.java`
5. `EmailLog.java`
6. `CustomerScore.java`

**Enums dans `enums/` :**
- `CustomerState.java` → ACTIF, INACTIF
- `InteractionType.java` → APPEL, EMAIL, REUNION, NOTE
- `ScoreLabel.java` → FIDELE, A_RISQUE
- `CampaignStatus.java` → PLANIFIEE, EN_COURS, ENVOYEE

**Pour la relation Many-to-Many Customer ↔ Segment :**
```java
// Dans Customer.java
@ManyToMany
@JoinTable(
    name = "customer_segments",
    joinColumns = @JoinColumn(name = "customer_id"),
    inverseJoinColumns = @JoinColumn(name = "segment_id")
)
private List<Segment> segments;
```

### Points d'attention
- Ajouter `@Enumerated(EnumType.STRING)` sur les champs enum (stocke la valeur lisible, pas l'index)
- Éviter les boucles infinies JSON avec `@JsonIgnore` sur le côté "mappedBy"
- Utiliser `LocalDateTime` pour les dates (pas `Date`)
- Lombok : ajouter `@Data`, `@NoArgsConstructor`, `@AllArgsConstructor`, `@Builder` sur chaque entité

---

## Étape 2.3 — Repositories
**Durée : 2-3 heures**

### Objectif
Créer les interfaces qui permettent d'accéder à la base de données.
Spring Data JPA génère automatiquement les requêtes SQL à partir des noms de méthodes.

### Concepts clés
- `JpaRepository<Entité, TypeId>` → fournit save(), findAll(), findById(), delete()...
- Les méthodes nommées → `findBy{Champ}(valeur)` génère automatiquement le SQL
- `@Query` → pour les requêtes complexes en JPQL ou SQL natif

### Ce que tu dois créer (dans `repositories/`)

```java
// Pour chaque entité, une interface :
CustomerRepository
SegmentRepository
InteractionRepository
CampaignRepository
EmailLogRepository
CustomerScoreRepository
```

**Méthodes custom importantes à implémenter :**
```java
// CustomerRepository
List<Customer> findByCustomerState(CustomerState state);
List<Customer> findBySegments_Id(Long segmentId);
Optional<Customer> findByEmail(String email);

// InteractionRepository
List<Interaction> findByCustomerIdOrderByDateDesc(Long customerId);
List<Interaction> findByCustomerIdAndDateAfter(Long customerId, LocalDateTime date);

// CustomerScoreRepository
Optional<CustomerScore> findTopByCustomerIdOrderByComputedAtDesc(Long customerId);
List<CustomerScore> findByCustomerIdOrderByComputedAtDesc(Long customerId);
```

### Points d'attention
- Les repositories sont des **interfaces**, pas des classes
- Spring crée automatiquement l'implémentation au démarrage
- `findBySegments_Id` → utilise le `_` pour traverser les relations (segments.id)

---

## Étape 2.4 — DTOs et Mappers
**Durée : 3-4 heures**

### Objectif
Créer des objets de transfert de données (DTO) pour isoler l'API de la structure interne.
MapStruct génère automatiquement le code de conversion entre entité et DTO.

### Pourquoi des DTOs ?
- L'API n'expose que ce dont le frontend a besoin
- Évite d'exposer des champs sensibles ou des relations cycliques
- Permet de valider les données entrantes indépendamment de l'entité

### Ce que tu dois créer (dans `dtos/`)

**Pattern : 3 DTOs par entité principale**
```
CustomerDTO         → lecture (GET) — données complètes
CustomerCreateDTO   → création (POST) — champs obligatoires uniquement
CustomerUpdateDTO   → modification (PUT) — champs modifiables
```

**Annotations de validation sur les DTOs Create/Update :**
```java
public class CustomerCreateDTO {
    @NotBlank(message = "Le prénom est obligatoire")
    private String firstName;

    @NotBlank
    private String lastName;

    @Email(message = "Email invalide")
    @NotBlank
    private String email;

    @Pattern(regexp = "^[0-9+]{8,15}$", message = "Téléphone invalide")
    private String phone;
}
```

**Mappers avec MapStruct (dans `mappers/`) :**
```java
@Mapper(componentModel = "spring")
public interface CustomerMapper {
    CustomerDTO toDTO(Customer customer);
    Customer toEntity(CustomerCreateDTO dto);
    void updateEntityFromDTO(CustomerUpdateDTO dto, @MappingTarget Customer customer);
}
```

### Points d'attention
- Ajouter le plugin MapStruct dans `pom.xml` pour la génération de code
- `@MappingTarget` → permet de modifier une entité existante sans la recréer
- Les DTOs de lecture peuvent contenir des données calculées (ex: score actuel)

---

## Étape 2.5 — Services (Logique Métier)
**Durée : 6-8 heures**

### Objectif
Implémenter la logique métier de l'application.
Les services orchestrent les repositories, appliquent les règles et coordonnent les opérations.

### Concepts clés
- `@Service` → marque la classe comme service Spring
- `@Transactional` → garantit l'atomicité des opérations BDD
- Les services ne doivent **jamais** retourner des entités directement → toujours des DTOs

### Ce que tu dois créer (dans `services/`)

**CustomerService**
```
Méthodes à implémenter :
- getAllCustomers() → List<CustomerDTO>
- getCustomerById(Long id) → CustomerDTO
- createCustomer(CustomerCreateDTO dto) → CustomerDTO
- updateCustomer(Long id, CustomerUpdateDTO dto) → CustomerDTO
- deleteCustomer(Long id) → void
- getCustomersBySegment(Long segmentId) → List<CustomerDTO>
- getCustomersByState(CustomerState state) → List<CustomerDTO>
```

**InteractionService**
```
- addInteraction(Long customerId, InteractionCreateDTO dto) → InteractionDTO
- getInteractionsByCustomer(Long customerId) → List<InteractionDTO>
- getRecentInteractions(Long customerId, int days) → List<InteractionDTO>
```

**SegmentService**
```
- createSegment(SegmentDTO dto) → SegmentDTO
- getAllSegments() → List<SegmentDTO>
- assignCustomerToSegment(Long customerId, Long segmentId) → void
- removeCustomerFromSegment(Long customerId, Long segmentId) → void
- getCustomersBySegment(Long segmentId) → List<CustomerDTO>
```

**ScoringService**
```
Logique de scoring à implémenter :
- score basé sur le nombre d'interactions (30 derniers jours)
- score basé sur l'état du client (ACTIF vs INACTIF)
- label automatique : score > 70 → FIDELE, sinon → A_RISQUE

Méthodes :
- computeScore(Long customerId) → CustomerScoreDTO
- computeAllScores() → void  [appelé par le scheduler]
```

**EmailService**
```
- sendEmail(String to, String subject, String body) → void
- sendCampaign(Long campaignId) → void
- logEmail(String to, String subject, Long customerId, Long campaignId) → void
```

**AIService**
```
- generateEmailContent(String customerContext) → String
```

### Points d'attention
- Gérer les cas `not found` avec des exceptions custom (voir Étape 2.8)
- `@Transactional` sur les méthodes qui modifient des données
- `ScoringService.computeScore()` doit sauvegarder le score en BDD
- `EmailService` doit créer un `EmailLog` à chaque envoi

---

## Étape 2.6 — RestControllers
**Durée : 4-5 heures**

### Objectif
Créer les endpoints REST qui exposent les fonctionnalités aux clients HTTP (Angular).

### Concepts clés
- `@RestController` → combine `@Controller` + `@ResponseBody`
- `@RequestMapping("/api/...")` → préfixe de l'URL
- `@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping` → méthodes HTTP
- `ResponseEntity<T>` → contrôle le statut HTTP de la réponse
- `@Valid` → déclenche la validation du DTO

### Ce que tu dois créer (dans `restcontrollers/`)

```
CustomerRestController    → /api/customers
InteractionRestController → /api/interactions
SegmentRestController     → /api/segments
CampaignRestController    → /api/campaigns
ScoreRestController       → /api/scores
EmailRestController       → /api/emails
DashboardRestController   → /api/dashboard
AuthRestController        → /api/auth
```

**Structure type d'un controller :**
```java
@RestController
@RequestMapping("/api/customers")
@RequiredArgsConstructor
public class CustomerRestController {

    private final CustomerService customerService;

    @GetMapping
    public ResponseEntity<List<CustomerDTO>> getAll() { ... }

    @GetMapping("/{id}")
    public ResponseEntity<CustomerDTO> getById(@PathVariable Long id) { ... }

    @PostMapping
    public ResponseEntity<CustomerDTO> create(@Valid @RequestBody CustomerCreateDTO dto) { ... }

    @PutMapping("/{id}")
    public ResponseEntity<CustomerDTO> update(@PathVariable Long id, @Valid @RequestBody CustomerUpdateDTO dto) { ... }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) { ... }
}
```

**Endpoints spécifiques à implémenter :**
```
GET  /api/customers?state=ACTIF        → filtrer par état
GET  /api/customers?segmentId=1        → filtrer par segment
POST /api/customers/{id}/segments/{sid} → assigner un segment
GET  /api/scores/compute-all           → déclencher le calcul des scores
POST /api/campaigns/{id}/send          → envoyer une campagne
POST /api/emails/generate-ai           → générer contenu IA
GET  /api/dashboard/stats              → statistiques globales
POST /api/auth/login                   → authentification
```

### Points d'attention
- Toujours retourner `ResponseEntity` pour contrôler le statut HTTP
- `201 Created` pour les POST, `200 OK` pour GET/PUT, `204 No Content` pour DELETE
- Injecter les services via le constructeur (pas `@Autowired` sur le champ)

---

## Étape 2.7 — Sécurité JWT
**Durée : 4-5 heures**

### Objectif
Sécuriser l'API avec Spring Security et des tokens JWT.
Seuls les utilisateurs authentifiés peuvent accéder aux endpoints protégés.

### Concepts clés
- **JWT (JSON Web Token)** → token signé contenant les informations de l'utilisateur
- **Spring Security Filter Chain** → chaîne de filtres qui interceptent chaque requête
- **UserDetails** → interface Spring pour représenter un utilisateur authentifié
- **JwtFilter** → filtre custom qui valide le token avant chaque requête

### Ce que tu dois créer (dans `security/`)

**Fichiers à créer :**
```
JwtUtil.java           → génère, valide, extrait les infos d'un token JWT
JwtFilter.java         → filtre Spring qui vérifie le token sur chaque requête
SecurityConfig.java    → configure Spring Security (routes publiques/protégées)
UserDetailsServiceImpl.java → charge l'utilisateur depuis la BDD
```

**Logique du flux d'authentification :**
```
1. POST /api/auth/login (email + password)
2. Spring Security vérifie les credentials
3. Si OK → génère un JWT signé avec le rôle de l'utilisateur
4. Le frontend stocke le JWT dans localStorage
5. À chaque requête → le frontend envoie : Authorization: Bearer {jwt}
6. JwtFilter valide le token et configure le contexte de sécurité
```

**Routes publiques (pas de token requis) :**
```
POST /api/auth/login
```

**Routes protégées par rôle :**
```
ROLE_COMMERCIAL → /api/customers/**, /api/interactions/**, /api/scores/**
ROLE_ADMIN      → tout + /api/segments/**, /api/campaigns/**, /api/dashboard/**
```

### Points d'attention
- Le secret JWT doit être long (minimum 256 bits) et stocké dans `application.properties`
- Ne jamais stocker le mot de passe en clair → utiliser `BCryptPasswordEncoder`
- Le token a une expiration → configurer `app.jwt.expiration=86400000` (24h en ms)
- Désactiver CSRF (inutile pour une API REST stateless)

---

## Étape 2.8 — Exceptions & Validation
**Durée : 2-3 heures**

### Objectif
Centraliser la gestion des erreurs pour retourner des réponses cohérentes et lisibles.

### Ce que tu dois créer (dans `exceptions/`)

**Exceptions custom :**
```java
CustomerNotFoundException.java    → extends RuntimeException
SegmentNotFoundException.java
CampaignNotFoundException.java
EmailSendException.java
```

**GlobalExceptionHandler :**
```java
@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(CustomerNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleCustomerNotFound(CustomerNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ErrorResponse(404, ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        // Extraire les messages de validation des champs
    }
}
```

**DTO de réponse d'erreur :**
```java
public record ErrorResponse(int status, String message, LocalDateTime timestamp) { }
```

### Points d'attention
- Le `@ControllerAdvice` intercepte les exceptions de **tous** les controllers
- `MethodArgumentNotValidException` → levée quand `@Valid` échoue
- Retourner des messages d'erreur clairs (pas de stack traces en production)

---

## Étape 2.9 — Scheduler (Tâches automatiques)
**Durée : 1-2 heures**

### Objectif
Déclencher automatiquement des traitements à des horaires fixes.

### Ce que tu dois créer (dans `scheduler/`)

**Activer le scheduling dans la classe principale :**
```java
@SpringBootApplication
@EnableScheduling
public class SmartCrmApplication { ... }
```

**CrmScheduler.java :**
```java
@Component
@RequiredArgsConstructor
public class CrmScheduler {

    private final ScoringService scoringService;
    private final EmailService emailService;

    @Scheduled(cron = "0 0 2 * * *")   // Chaque nuit à 2h
    public void computeAllScores() {
        scoringService.computeAllScores();
    }

    @Scheduled(cron = "0 0 8 * * *")   // Chaque matin à 8h
    public void triggerAutomaticEmails() {
        emailService.triggerAutomaticEmails();
    }
}
```

### Points d'attention
- Tester avec `fixedRate = 60000` (toutes les minutes) pendant le développement
- Revenir aux crons en production
- Logger chaque exécution pour traçabilité

---

## ✅ Critères de validation de la Phase 2

Avant de passer à la Phase 3, vérifie que :

- [ ] Le projet Spring Boot démarre sans erreur
- [ ] Toutes les tables sont créées en BDD (schema.sql chargé)
- [ ] Les entités JPA correspondent au schéma SQL
- [ ] L'endpoint `/api/auth/login` retourne un JWT valide
- [ ] Un endpoint protégé retourne 403 sans token et 200 avec token
- [ ] Les opérations CRUD fonctionnent pour `Customer` et `Segment`
- [ ] Le calcul de score fonctionne pour un client
- [ ] L'envoi d'email fonctionne (tester avec un vrai compte Gmail)
- [ ] Les erreurs retournent des réponses JSON structurées (pas de stack traces)
- [ ] Tous les endpoints sont testés avec Postman

---

## 📚 Ressources recommandées
- [Spring Initializr](https://start.spring.io)
- [Spring Security + JWT Tutorial](https://www.bezkoder.com/spring-boot-jwt-authentication/)
- [MapStruct Documentation](https://mapstruct.org/documentation/stable/reference/html/)
- [Java 21 Features](https://openjdk.org/projects/jdk/21/)
- [Spring AI Documentation](https://docs.spring.io/spring-ai/reference/)
