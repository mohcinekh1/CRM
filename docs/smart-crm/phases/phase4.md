# Phase 4 — Intégration IA (Ollama + Spring AI)
**Durée estimée : 2-3 jours**
**Prérequis : Phase 2 et Phase 3 validées et fonctionnelles**

---

## 🎯 Objectif de la phase
Enrichir le CRM avec des fonctionnalités d'intelligence artificielle locale.
Ollama fait tourner un modèle Mistral directement sur ta machine, sans API externe ni coût.
Spring AI simplifie l'intégration avec une abstraction haut niveau.

---

## Étape 4.1 — Installation et configuration d'Ollama
**Durée : 1-2 heures**

### Objectif
Installer Ollama et vérifier que le modèle Mistral est opérationnel avant d'écrire du code.

### Concepts clés
- **Ollama** → outil open-source pour faire tourner des LLMs localement
- **Mistral** → modèle de langage performant et léger, idéal pour usage local
- **API Ollama** → expose une API REST sur `http://localhost:11434`

### Ce que tu dois faire

**1. Installer Ollama :**
```bash
# Linux / macOS
curl -fsSL https://ollama.com/install.sh | sh

# Windows → télécharger l'installeur depuis https://ollama.com
```

**2. Télécharger le modèle Mistral :**
```bash
ollama pull mistral
# Attendre le téléchargement (~4GB)
```

**3. Vérifier que l'API fonctionne :**
```bash
# Tester l'API directement
curl http://localhost:11434/api/chat \
  -d '{"model": "mistral", "messages": [{"role": "user", "content": "Dis bonjour"}], "stream": false}'
```

**4. Lister les modèles disponibles :**
```bash
ollama list
```

### Points d'attention
- Ollama doit être démarré avant Spring Boot : `ollama serve`
- Il tourne sur le port 11434 par défaut
- Assure-toi d'avoir au moins 8GB de RAM disponible pour Mistral
- La première réponse peut être lente (chargement du modèle en mémoire)

---

## Étape 4.2 — Configuration Spring AI
**Durée : 1 heure**

### Objectif
Configurer la dépendance Spring AI pour communiquer avec Ollama depuis le backend.

### Ce que tu dois faire

**1. Ajouter la dépendance dans `pom.xml` :**
```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>org.springframework.ai</groupId>
      <artifactId>spring-ai-bom</artifactId>
      <version>1.0.0</version>
      <type>pom</type>
      <scope>import</scope>
    </dependency>
  </dependencies>
</dependencyManagement>

<dependencies>
  <dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-ollama-spring-boot-starter</artifactId>
  </dependency>
</dependencies>
```

**2. Vérifier `application.properties` :**
```properties
spring.ai.ollama.base-url=http://localhost:11434
spring.ai.ollama.chat.model=mistral
spring.ai.ollama.chat.options.temperature=0.7
spring.ai.ollama.chat.options.num-predict=500
```

**3. Tester l'autoconfiguration :**
Spring AI injecte automatiquement un `ChatClient` ou `OllamaChatModel`.
Créer un test rapide dans une classe de test pour vérifier que l'injection fonctionne.

### Points d'attention
- `temperature` → contrôle la créativité (0 = déterministe, 1 = très créatif). 0.7 est un bon équilibre pour les emails.
- `num-predict` → nombre max de tokens générés (500 ≈ 350 mots)
- Spring AI gère automatiquement le format de la requête Ollama

---

## Étape 4.3 — Service IA : Génération d'emails
**Durée : 3-4 heures**

### Objectif
Implémenter la génération automatique du contenu d'un email personnalisé
en fonction du profil et de l'historique d'un client.

### Concepts clés
- **Prompt Engineering** → l'art de formuler les instructions à l'IA
- **Context Window** → quantité d'informations qu'on peut donner au modèle
- **System Prompt** → instructions de comportement données à l'IA en amont

### Ce que tu dois créer (dans `services/AIService.java`)

**Structure du service :**
```java
@Service
@RequiredArgsConstructor
public class AIService {

    private final ChatClient chatClient; // injecté par Spring AI

    public String generateEmailContent(EmailGenerationRequestDTO request) {
        // 1. Construire le contexte client
        String customerContext = buildCustomerContext(request);

        // 2. Construire le prompt
        String prompt = buildEmailPrompt(customerContext, request.getObjective());

        // 3. Appeler Ollama
        // 4. Retourner le résultat
    }

    private String buildCustomerContext(EmailGenerationRequestDTO request) {
        // Assembler les infos : nom, score, dernière interaction, segment...
    }

    private String buildEmailPrompt(String context, String objective) {
        // Construire un prompt structuré et clair
    }
}
```

**DTO pour la requête de génération :**
```java
public class EmailGenerationRequestDTO {
    private Long customerId;       // null si email de campagne générique
    private String objective;      // ex: "fidélisation", "relance", "promotion"
    private String tone;           // ex: "professionnel", "chaleureux", "urgent"
    private String additionalInfo; // infos supplémentaires optionnelles
}
```

**Exemple de prompt à construire :**
```
Tu es un expert en marketing relationnel pour un CRM.
Rédige un email professionnel en français avec les caractéristiques suivantes :

Contexte client :
- Nom : [prénom nom]
- Statut : [ACTIF/INACTIF]
- Score de fidélité : [score]/100 ([label])
- Dernière interaction : [date] - [type]
- Segment : [nom du segment]

Objectif de l'email : [objectif]
Ton souhaité : [ton]
Informations supplémentaires : [infos]

L'email doit :
- Commencer par une formule de politesse personnalisée
- Faire référence au contexte du client de manière naturelle
- Contenir un appel à l'action clair
- Être concis (150-200 mots maximum)
- Finir par une formule de clôture professionnelle

Retourne uniquement le corps de l'email, sans sujet ni métadonnées.
```

### Points d'attention
- Plus le prompt est précis → meilleure est la réponse
- Tester avec plusieurs clients ayant des profils différents
- L'appel à Ollama est synchrone → peut prendre 5-15 secondes → ajouter un timeout
- Gérer le cas où Ollama ne répond pas (exception + message d'erreur clair)

---

## Étape 4.4 — Service IA : Suggestion de segment
**Durée : 2-3 heures**

### Objectif
Suggérer automatiquement le segment le plus adapté à un client
en fonction de son profil et de l'historique des interactions.

### Ce que tu dois créer (méthode dans `AIService`)

```java
public String suggestSegment(Long customerId, List<String> availableSegments) {
    // 1. Récupérer le profil complet du client
    // 2. Construire un prompt avec les segments disponibles
    // 3. Demander à l'IA de choisir + justifier
    // 4. Retourner la suggestion
}
```

**Exemple de prompt :**
```
Tu es un analyste CRM. Voici le profil d'un client :
[profil du client]

Voici les segments disponibles dans notre CRM :
[liste des segments avec leur description]

Quel segment recommandes-tu pour ce client ?
Réponds avec le format JSON suivant :
{
  "segmentRecommande": "Nom du segment",
  "raison": "Explication courte en 1-2 phrases"
}
```

### Points d'attention
- Demander à l'IA de répondre en JSON → plus facile à parser côté Java
- Utiliser `ObjectMapper` pour parser la réponse JSON
- Gérer le cas où la réponse n'est pas du JSON valide (fallback sur réponse textuelle)

---

## Étape 4.5 — Endpoints IA dans le backend
**Durée : 1-2 heures**

### Objectif
Exposer les fonctionnalités IA via des endpoints REST consommés par Angular.

### Ce que tu dois créer (dans `EmailRestController` ou nouveau `AIRestController`)

```
POST /api/ai/generate-email
     Body: EmailGenerationRequestDTO
     Response: { "content": "Corps de l'email généré..." }

POST /api/ai/suggest-segment
     Body: { "customerId": 1 }
     Response: { "segmentRecommande": "...", "raison": "..." }
```

### Points d'attention
- Ces endpoints peuvent être lents → ne pas oublier le timeout
- Réservés aux ROLE_ADMIN (Spring Security)
- Logger chaque appel IA pour audit

---

## Étape 4.6 — Intégration côté Angular
**Durée : 2-3 heures**

### Objectif
Connecter les boutons IA du frontend avec les nouveaux endpoints backend.

### Ce que tu dois faire

**1. Créer `AIService` dans Angular (dans `services/`) :**
```typescript
@Injectable({ providedIn: 'root' })
export class AIService {
  private http = inject(HttpClient);

  generateEmail(request: EmailGenerationRequest): Observable<{ content: string }> {
    return this.http.post<{ content: string }>('/api/ai/generate-email', request);
  }

  suggestSegment(customerId: number): Observable<SegmentSuggestion> {
    return this.http.post<SegmentSuggestion>('/api/ai/suggest-segment', { customerId });
  }
}
```

**2. Dans `campaign-form.component` :**
- Bouton "✨ Générer avec l'IA" → ouvre un `MatDialog`
- Dans le dialog : champs "Objectif" et "Ton"
- Bouton "Générer" → appelle `AIService.generateEmail()`
- Pendant l'appel : spinner + message "L'IA rédige votre email..."
- Résultat → pré-remplit le textarea du formulaire
- L'utilisateur peut modifier le texte avant de sauvegarder

**3. Dans `customer-detail.component` :**
- Bouton "💡 Suggérer un segment" → appelle `AIService.suggestSegment()`
- Affiche la suggestion dans un `MatSnackBar` ou une card d'information
- Bouton pour appliquer directement la suggestion

### Points d'attention
- L'appel IA peut prendre 5-15 secondes → le spinner doit être visible
- Désactiver le bouton pendant l'appel pour éviter les doubles soumissions
- Afficher un message d'erreur si l'IA ne répond pas

---

## ✅ Critères de validation de la Phase 4

Avant de passer à la Phase 5, vérifie que :

- [ ] `ollama serve` fonctionne et le modèle Mistral est téléchargé
- [ ] L'appel direct à l'API Ollama via `curl` retourne une réponse
- [ ] Spring Boot démarre sans erreur avec la dépendance Spring AI
- [ ] `POST /api/ai/generate-email` retourne un email cohérent en JSON
- [ ] `POST /api/ai/suggest-segment` retourne une suggestion avec justification
- [ ] Le bouton "Générer avec l'IA" dans Angular affiche un spinner puis le résultat
- [ ] Le contenu généré est pré-rempli dans le formulaire (modifiable)
- [ ] Les erreurs IA sont gérées (message d'erreur si Ollama est hors ligne)

---

## 📚 Ressources recommandées
- [Ollama Documentation](https://ollama.com/docs)
- [Spring AI + Ollama](https://docs.spring.io/spring-ai/reference/api/chat/ollama-chat.html)
- [Mistral Model Card](https://ollama.com/library/mistral)
- [Prompt Engineering Guide](https://www.promptingguide.ai/fr)
