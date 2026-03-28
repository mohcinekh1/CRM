# Phase 3 — Frontend Angular 20
**Durée estimée : 6-8 jours**
**Prérequis : Phase 2 validée (API backend fonctionnelle + Postman OK)**

---

## 🎯 Objectif de la phase
Construire l'interface utilisateur de Smart CRM avec Angular 20.
Le frontend communique avec le backend via des appels HTTP REST,
affiche les données de manière claire et gère l'authentification côté client.

---

## Étape 3.1 — Setup du projet Angular
**Durée : 2-3 heures**

### Objectif
Créer un projet Angular 20 structuré et prêt au développement.

### Nouveautés Angular 20 à connaître
- **Signals** → nouveau système réactif (remplace en partie RxJS)
- **Standalone Components** → plus besoin de NgModule dans la plupart des cas
- **Control Flow** → nouvelle syntaxe `@if`, `@for`, `@switch` dans les templates
- **inject()** → alternative aux constructeurs pour l'injection de dépendances

### Ce que tu dois faire

**1. Créer le projet :**
```bash
ng new smart-crm-frontend --routing --style=scss --standalone
cd smart-crm-frontend
```

**2. Installer les dépendances :**
```bash
npm install @angular/material @angular/cdk
npm install jwt-decode
npm install chart.js ng2-charts
```

**3. Configurer Angular Material :**
```bash
ng add @angular/material
# Choisir un thème (ex: Indigo/Pink ou personnalisé)
```

**4. Structure des dossiers à créer :**
```
src/app/
├── core/
│   ├── interceptors/
│   │   └── jwt.interceptor.ts
│   ├── guards/
│   │   └── auth.guard.ts
│   └── services/
│       └── auth.service.ts
├── shared/
│   ├── components/
│   │   ├── navbar/
│   │   ├── sidebar/
│   │   └── confirm-dialog/
│   └── models/
│       ├── customer.model.ts
│       ├── segment.model.ts
│       ├── campaign.model.ts
│       ├── score.model.ts
│       └── interaction.model.ts
├── modules/
│   ├── auth/
│   │   └── login/
│   ├── dashboard/
│   ├── customers/
│   │   ├── customer-list/
│   │   ├── customer-detail/
│   │   └── customer-form/
│   ├── segments/
│   ├── campaigns/
│   └── scores/
└── services/
    ├── customer.service.ts
    ├── segment.service.ts
    ├── campaign.service.ts
    ├── score.service.ts
    └── interaction.service.ts
```

**5. Configurer le proxy Angular (pour éviter les CORS en dev) :**
Créer `proxy.conf.json` :
```json
{
  "/api": {
    "target": "http://localhost:8080",
    "secure": false
  }
}
```
Dans `angular.json` → ajouter `"proxyConfig": "proxy.conf.json"` sous `serve.options`

### Points d'attention
- Angular 20 utilise par défaut les Standalone Components → pas de `app.module.ts`
- Utiliser `provideHttpClient(withInterceptors([jwtInterceptor]))` dans `app.config.ts`
- Les signals sont préférables à `BehaviorSubject` pour l'état simple

---

## Étape 3.2 — Modèles TypeScript
**Durée : 1-2 heures**

### Objectif
Définir les interfaces TypeScript qui correspondent aux DTOs du backend.
C'est le "contrat" entre frontend et backend.

### Ce que tu dois créer (dans `shared/models/`)

```typescript
// customer.model.ts
export interface Customer {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address: string;
  customerState: 'ACTIF' | 'INACTIF';
  createdAt: string;
  currentScore?: CustomerScore;
  segments?: Segment[];
}

export interface CustomerCreateDTO {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address: string;
}
```

Créer des modèles similaires pour :
- `Segment`, `SegmentCreateDTO`
- `Interaction`, `InteractionCreateDTO`
- `Campaign`, `CampaignCreateDTO`
- `CustomerScore`
- `EmailLog`
- `AuthRequest`, `AuthResponse`

---

## Étape 3.3 — Services Angular
**Durée : 3-4 heures**

### Objectif
Créer les services qui communiquent avec le backend via HTTP.

### Concepts clés Angular 20
- `HttpClient` → service Angular pour les appels HTTP
- `Observable<T>` → flux de données asynchrone (RxJS)
- `inject()` → injection de dépendances sans constructeur
- `signal()` → état réactif local

### Ce que tu dois créer (dans `services/`)

**Structure type d'un service :**
```typescript
@Injectable({ providedIn: 'root' })
export class CustomerService {
  private http = inject(HttpClient);
  private apiUrl = '/api/customers';

  getAll(): Observable<Customer[]> {
    return this.http.get<Customer[]>(this.apiUrl);
  }

  getById(id: number): Observable<Customer> {
    return this.http.get<Customer>(`${this.apiUrl}/${id}`);
  }

  create(dto: CustomerCreateDTO): Observable<Customer> {
    return this.http.post<Customer>(this.apiUrl, dto);
  }

  update(id: number, dto: Partial<Customer>): Observable<Customer> {
    return this.http.put<Customer>(`${this.apiUrl}/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
```

**AuthService (dans `core/services/`) :**
```typescript
@Injectable({ providedIn: 'root' })
export class AuthService {
  private isLoggedIn = signal(false);
  private userRole = signal<string | null>(null);

  login(credentials: AuthRequest): Observable<AuthResponse> { ... }
  logout(): void { localStorage.removeItem('token'); }
  getToken(): string | null { return localStorage.getItem('token'); }
  isAuthenticated(): boolean { return !!this.getToken(); }
  getUserRole(): string | null { ... }
}
```

---

## Étape 3.4 — Intercepteur JWT et Guards
**Durée : 2-3 heures**

### Objectif
Automatiser l'ajout du token JWT à chaque requête et protéger les routes privées.

### JWT Interceptor (dans `core/interceptors/`)
```typescript
// Ajoute automatiquement le header Authorization à chaque requête
export const jwtInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.getToken();

  if (token) {
    const authReq = req.clone({
      headers: req.headers.set('Authorization', `Bearer ${token}`)
    });
    return next(authReq);
  }
  return next(req);
};
```

### Auth Guard (dans `core/guards/`)
```typescript
// Protège les routes qui nécessitent une authentification
export const authGuard: CanActivateFn = () => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) return true;

  router.navigate(['/login']);
  return false;
};
```

### Configuration du Router (`app.routes.ts`)
```typescript
export const routes: Routes = [
  { path: 'login', loadComponent: () => import('./modules/auth/login/login.component') },
  {
    path: '',
    canActivate: [authGuard],
    children: [
      { path: 'dashboard', loadComponent: ... },
      { path: 'customers', loadComponent: ... },
      { path: 'customers/:id', loadComponent: ... },
      { path: 'segments', loadComponent: ... },
      { path: 'campaigns', loadComponent: ... },
      { path: 'scores', loadComponent: ... },
    ]
  },
  { path: '**', redirectTo: 'dashboard' }
];
```

---

## Étape 3.5 — Page de Login
**Durée : 2-3 heures**

### Objectif
Créer la page d'authentification, point d'entrée de l'application.

### Ce que tu dois créer (`modules/auth/login/`)

**login.component.ts** :
- Formulaire réactif avec `FormBuilder` (email + password)
- Validation : email valide, password non vide
- Appel `AuthService.login()` au submit
- Redirection vers `/dashboard` si succès
- Affichage d'un message d'erreur si échec

**login.component.html** :
- Design sobre avec Angular Material (MatCard, MatFormField, MatButton)
- Logo ou titre "Smart CRM" en haut
- Affichage des erreurs de validation inline
- Spinner de chargement pendant l'appel API

### Points d'attention
- Utiliser `ReactiveFormsModule` (pas `FormsModule`)
- Désactiver le bouton Submit pendant le chargement
- Stocker uniquement le token JWT, pas le mot de passe

---

## Étape 3.6 — Layout principal (Navbar + Sidebar)
**Durée : 2-3 heures**

### Objectif
Créer la structure visuelle commune à toutes les pages protégées.

### Ce que tu dois créer (`shared/components/`)

**navbar.component** :
- Titre "Smart CRM" + logo
- Nom de l'utilisateur connecté (extrait du JWT)
- Bouton "Déconnexion"
- Responsive (burger menu sur mobile)

**sidebar.component** :
- Liens de navigation vers : Dashboard, Clients, Segments, Campagnes, Scores
- Icônes Material Icons
- Lien actif mis en évidence
- Affichage conditionnel selon le rôle (Admin vs Commercial)

---

## Étape 3.7 — Dashboard
**Durée : 3-4 heures**

### Objectif
Page d'accueil avec les indicateurs clés du CRM en un coup d'œil.

### Ce que tu dois créer (`modules/dashboard/`)

**Indicateurs à afficher (cards) :**
- Total clients
- Clients actifs
- Clients à risque (score A_RISQUE)
- Interactions cette semaine
- Campagnes envoyées ce mois

**Graphique (Chart.js) :**
- Évolution du nombre de clients par mois (line chart)
- Répartition FIDELE / A_RISQUE (pie chart)

**Tableau des dernières interactions :**
- 5 dernières interactions avec : client, type, date

### Points d'attention
- Créer un endpoint `GET /api/dashboard/stats` côté backend pour tout récupérer en un appel
- Utiliser `ng2-charts` pour les graphiques
- Les cards utilisent Angular Material `MatCard`

---

## Étape 3.8 — Module Clients
**Durée : 5-6 heures**

### Objectif
Gérer l'ensemble du cycle de vie des clients : liste, fiche, création, édition.

### Ce que tu dois créer (`modules/customers/`)

**customer-list.component** :
- Tableau paginé (`MatTable` + `MatPaginator`)
- Colonne : Nom, Email, Téléphone, État, Score, Actions
- Barre de recherche (filtre par nom/email)
- Filtres dropdown : État, Segment
- Badge coloré sur le score (vert = FIDELE, rouge = A_RISQUE, gris = non calculé)
- Boutons : "Voir", "Modifier", "Supprimer" (avec confirm dialog)
- Bouton "Nouveau client" → redirige vers le formulaire

**customer-detail.component** :
- Informations personnelles (lecture) + bouton "Modifier"
- Timeline des interactions avec icône selon le type
- Bouton "Ajouter une interaction" → ouvre un dialog Angular Material
- Affichage du score actuel avec badge
- Graphique historique des scores
- Segments assignés + bouton "Gérer les segments"

**customer-form.component** (création + édition) :
- Formulaire réactif avec tous les champs
- Validation temps réel
- Pré-remplissage en mode édition
- Boutons "Annuler" et "Enregistrer"

### Points d'attention
- Utiliser `ActivatedRoute` pour récupérer l'id en mode édition
- Le formulaire création et édition peut être le **même composant** (mode dual)
- `MatDialog` pour les dialogs (ajout interaction, confirmation suppression)
- Les badges de score : utiliser `[ngClass]` ou la directive `class` avec des conditions

---

## Étape 3.9 — Module Segments
**Durée : 3-4 heures**

### Objectif
Permettre la gestion des segments de clients.

### Ce que tu dois créer (`modules/segments/`)

**segment-list.component** :
- Tableau : Nom, Description, Nombre de clients, Actions
- Bouton "Nouveau segment"
- Bouton "Voir les clients" → navigue vers une vue filtrée

**segment-detail.component** :
- Infos du segment
- Liste des clients assignés (tableau avec recherche)
- Bouton "Retirer du segment" sur chaque client
- Bouton "Ajouter des clients" → dialog de sélection multi-clients

**segment-form.component** :
- Formulaire création/édition (Nom, Description, Critères)

---

## Étape 3.10 — Module Campagnes Email
**Durée : 4-5 heures**

### Objectif
Permettre la création, la gestion et l'envoi de campagnes email ciblées.

### Ce que tu dois créer (`modules/campaigns/`)

**campaign-list.component** :
- Tableau : Nom, Sujet, Segment cible, Statut, Date planifiée, Actions
- Badge de statut (PLANIFIEE = bleu, EN_COURS = orange, ENVOYEE = vert)
- Boutons : "Voir", "Envoyer", "Supprimer"

**campaign-form.component** :
- Champs : Nom, Sujet, Corps (textarea riche ou simple), Segment cible, Date planifiée
- Bouton **"✨ Générer avec l'IA"** :
  - Ouvre un dialog
  - L'utilisateur saisit le contexte (ex: "Email de fidélisation pour clients inactifs")
  - Appelle `/api/emails/generate-ai` → affiche le résultat dans le textarea
  - L'utilisateur peut modifier avant de sauvegarder
- Bouton "Envoyer maintenant" ou "Planifier"

### Points d'attention
- L'appel IA peut prendre du temps → afficher un spinner avec message "L'IA rédige votre email..."
- Demander confirmation avant l'envoi ("Cette campagne sera envoyée à X clients. Confirmer ?")

---

## Étape 3.11 — Module Scores
**Durée : 2-3 heures**

### Objectif
Visualiser et gérer les scores de fidélité des clients.

### Ce que tu dois créer (`modules/scores/`)

**score-list.component** :
- Tableau : Client, Score (barre de progression), Label, Date de calcul
- Filtre par label (FIDELE / A_RISQUE)
- Bouton "Recalculer tous les scores" (avec confirmation + spinner)
- Trier par score (décroissant par défaut)

**score-history.component** (embarqué dans customer-detail) :
- Graphique ligne : évolution du score dans le temps
- Tableau des calculs précédents

---

## ✅ Critères de validation de la Phase 3

Avant de passer à la Phase 4, vérifie que :

- [ ] `ng serve` fonctionne sans erreur de compilation
- [ ] Le login fonctionne et stocke le JWT
- [ ] Les routes protégées redirigent vers `/login` sans token
- [ ] La liste des clients s'affiche avec pagination et filtres
- [ ] La fiche client affiche interactions, score et segments
- [ ] La création et modification d'un client fonctionnent
- [ ] La liste des segments et l'assignation client-segment fonctionnent
- [ ] La création d'une campagne fonctionne
- [ ] Le tableau des scores s'affiche correctement
- [ ] La déconnexion supprime le token et redirige vers `/login`

---

## 📚 Ressources recommandées
- [Angular 20 Documentation](https://angular.dev)
- [Angular Material Components](https://material.angular.io/components)
- [Angular Signals Guide](https://angular.dev/guide/signals)
- [Chart.js Documentation](https://www.chartjs.org/docs/)
- [jwt-decode npm](https://www.npmjs.com/package/jwt-decode)
