# Must@Dev - AI Integration Module pour RAD Studio

Bienvenue dans **Must@Dev AI**, une extension de niveau entreprise pour l'IDE Delphi / RAD Studio (via Open Tools API - OTA). Cette extension intègre de manière transparente la puissance des modèles d'intelligence artificielle (LLMs locaux et Cloud) directement dans votre environnement de développement.

## ✨ Fonctionnalités Principales

- 🧠 **Multi-Fournisseurs Avancé & Profils Rapides** :
  - **Profils préconfigurés** : Sélectionnez en 1 clic vos configurations pour *Ollama (Local)*, *LM Studio (Local)*, *OpenAI*, *Google Gemini*, *Anthropic Claude*, *Alibaba Qwen*, et *DeepSeek*. Les adresses et types d'API se configurent automatiquement !
  - **Changement instantané** : Plus besoin de retaper les configurations pour passer du local au cloud.
- 🔄 **Détection Automatique des Modèles Locaux** : Un simple clic sur "Actualiser" dans les paramètres interroge votre serveur Ollama ou LM Studio et remplit la liste déroulante avec les modèles réellement installés sur votre machine !
- 💾 **Mémoire de Contexte (Conversation History)** : 
  - L'assistant de chat garde en mémoire le fil de la discussion (jusqu'à 10 messages glissants) pour vous répondre de façon contextuelle.
  - Vous pouvez réinitialiser la conversation à tout moment grâce au bouton **Nouvelle conversation 🗑️**.
- 🛠️ **Optimisation Contextuelle à la Demande** :
  - Une case à cocher **"Optimiser le prompt avec le contexte"** vous permet de décider si vous souhaitez injecter vos règles de codage Delphi et vos fichiers `Agent.md` / `Gemini.md` / `Claude.md`.
  - Décochez-la pour poser des questions simples hors contexte afin d'**économiser drastiquement vos tokens**.
- ⚡ **Asynchrone & Non-Bloquant** : Toutes les requêtes sont exécutées dans des threads d'arrière-plan (`TThread`). Votre IDE reste 100% fluide et réactif pendant la génération du code.
- ⌨️ **Raccourcis Éditeur Natifs** : 
  - `Ctrl+Alt+Space` : **Autocomplétion**. Sélectionnez un extrait de code, l'IA l'analyse et insère la complétion directement.
  - `Ctrl+Alt+R` : **Refactoring**. Sélectionnez une méthode, l'IA l'optimise selon les meilleures pratiques Delphi et la remplace à la volée.
- 💬 **Assistant de Code Moderne (Dockable)** : Interface ancrable refaite à neuf (Flat UI, polices Segoe UI claires, sans bordures lourdes).
- 📝 **Journalisation Native (Logger)** : Les événements, appels API et erreurs remontent discrètement dans l'onglet *Messages* natif de RAD Studio.

## 🚀 Installation

1. Clonez ce dépôt ou téléchargez les sources.
2. Ouvrez le projet **`MustDevLLM.dpk`** dans Embarcadero RAD Studio.
3. Dans le Gestionnaire de Projets (Project Manager), faites un clic droit sur `MustDevLLM.bpl` et sélectionnez **Build** (Compiler).
4. Refaites un clic droit et sélectionnez **Install** (Installer).
5. Un nouveau menu **`Must@Dev`** apparaîtra en haut de l'IDE.

## ⚙️ Configuration

Une fois installé, allez dans le menu supérieur de RAD Studio :
**`Must@Dev` -> `Configuration...`** (ou via `Outils` -> `Options` -> `Tierce Partie`).

- **Profil Rapide** : Choisissez votre modèle cible.
- **Modèle** : Cliquez sur **Actualiser** si vous êtes en local pour lister vos modèles installés.
- **Clé API** : Saisissez votre clé de sécurité si vous êtes en mode Cloud.
- **Raccourcis Éditeur** : Personnalisez vos raccourcis clavier si vous le souhaitez.
- **System Prompts** : Modifiez les instructions système par défaut envoyées à l'IA pour correspondre exactement à votre style de programmation.

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.
