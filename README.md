# Must@Dev - AI Integration Module pour RAD Studio

Bienvenue dans **Must@Dev AI**, une extension de niveau entreprise pour l'IDE Delphi / RAD Studio (via Open Tools API - OTA). Cette extension intègre de manière transparente la puissance des modèles d'intelligence artificielle (LLMs locaux et Cloud) directement dans votre environnement de développement.

## ✨ Fonctionnalités Principales

- 🧠 **Multi-Fournisseurs Avancé** : 
  - **Cloud** : Intégration optimisée pour OpenAI (GPT-4), Google Gemini, Anthropic Claude, QWen, et DeepSeek. Chaque fournisseur utilise son propre formateur JSON natif.
  - **Local** : Support total de Ollama et LM Studio.
- 🔄 **Détection Automatique des Modèles Locaux** : Un simple clic sur "Actualiser" dans les paramètres interroge votre serveur Ollama ou LM Studio et remplit la liste déroulante avec les modèles réellement installés sur votre machine !
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
5. Un nouveau menu **`Must@Dev`** apparaîtra en haut de l'IDE.

## ⚙️ Configuration

Une fois installé, allez dans le menu supérieur de RAD Studio :
**`Must@Dev` -> `Configuration...`** (ou via `Outils` -> `Options` -> `Tierce Partie`).

- **Fournisseur Local** : Entrez votre endpoint (ex: `http://127.0.0.1:11434/api/generate` pour Ollama) et cliquez sur **Actualiser** pour lister vos modèles locaux.
- **Fournisseur Cloud** : Choisissez votre moteur préféré (OpenAI/Standard, Gemini, ou Claude), saisissez votre URL et Clé API.
- **Raccourcis Éditeur** : Personnalisez vos raccourcis clavier si vous le souhaitez.
- **System Prompts** : Modifiez les instructions système par défaut envoyées à l'IA pour correspondre exactement à votre style de programmation.

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.
