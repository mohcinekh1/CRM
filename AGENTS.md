# Smart CRM — repères pour les assistants (Cursor / agents)

| Rôle | Emplacement |
|------|-------------|
| Contexte stack, domaine, conventions | `.context.md` (racine) |
| Jalons et tâches par phase | `docs/smart-crm/phases/phase1.md` → `phase5.md` |
| Schéma & données MySQL | `database/schema.sql`, `database/data.sql` |
| Diagrammes phase 1 (classes, cas d’utilisation) | `docs/smart-crm/phase1/diagrams/` |
| Mode mentor et règles d’interaction | `.cursorrules` (racine) |
| Rappel automatique des chemins ci-dessus | `.cursor/rules/smart-crm.mdc` (`alwaysApply: true`) |

Ordre strict des phases : **1** conception → **2** backend → **3** frontend → **4** IA → **5** tests & finalisation.
