# Must@Dev - AI Integration Module pour RAD Studio

Bienvenue dans **Must@Dev AI**, une extension de niveau entreprise pour l'IDE Delphi / RAD Studio (via Open Tools API - OTA). Cette extension intègre de manière transparente la puissance des modèles d'intelligence artificielle (LLMs locaux et Cloud) directement dans votre environnement de développement.

## ✨ Fonctionnalités Principales

- 🧠 **Multi-Fournisseurs** : Prise en charge des modèles Cloud (OpenAI GPT-4, Google Gemini, Anthropic Claude) via API REST, et des modèles Locaux (Ollama, LM Studio) pour une confidentialité totale.
- ⚡ **Asynchrone & Non-Bloquant** : Toutes les requêtes sont exécutées dans des threads d'arrière-plan (`TThread`). Votre IDE reste 100% fluide et réactif pendant la génération du code.
- ⌨️ **Raccourcis Éditeur Natifs** : 
  - `Ctrl+Alt+Space` : **Autocomplétion**. Sélectionnez un extrait de code, l'IA l'analyse et insère la complétion directement.
  - `Ctrl+Alt+R` : **Refactoring**. Sélectionnez une méthode, l'IA l'optimise selon les meilleures pratiques Delphi et la remplace à la volée.
- 💬 **Assistant de Code (Dockable)** : Une fenêtre ancrable (Chat) dédiée avec formattage (RichEdit) pour poser vos questions d'architecture ou de débogage.
- 🛠️ **Optimiseur de Prompts Intégré** : L'extension injecte silencieusement des règles strictes de développement Delphi (sécurité mémoire, syntaxe moderne) pour forcer les LLMs à produire un code de haute qualité.
- 📝 **Journalisation Native (Logger)** : Les événements, appels API et erreurs remontent discrètement dans l'onglet *Messages* natif de RAD Studio.
- 📂 **Gestion de Contexte Projet** : Génération automatique de fichiers (`Agent.md`, `Gemini.md`, `Claude.md`) à la racine de votre projet pour contextualiser le comportement de l'IA spécifiquement pour chaque projet.

## 🚀 Installation

1. Clonez ce dépôt ou téléchargez les sources.
2. Ouvrez le projet **`MustDevLLM.dpk`** dans Embarcadero RAD Studio.
3. Dans le Gestionnaire de Projets (Project Manager), faites un clic droit sur `MustDevLLM.bpl` et sélectionnez **Build** (Compiler).
4. Refaites un clic droit et sélectionnez **Install** (Installer).
5. Un message confirmera que les composants de l'extension ont bien été enregistrés dans l'IDE.

## ⚙️ Configuration

Une fois installé, allez dans le menu supérieur de RAD Studio :
**`Must@Dev` -> `Configuration...`** (ou via `Outils` -> `Options` -> `Tierce Partie`).

- **Fournisseur d'IA** : Choisissez entre un fournisseur Cloud ou Local. Saisissez votre Clé API ou l'URL de votre Socket local.
- **Raccourcis Éditeur** : Personnalisez vos raccourcis clavier si vous le souhaitez.
- **System Prompts** : Modifiez les instructions système par défaut envoyées à l'IA pour correspondre exactement à votre style de programmation.

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.
