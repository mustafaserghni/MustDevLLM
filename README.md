# Must@Dev - AI Integration Module pour RAD Studio

Bienvenue dans **Must@Dev AI**, une extension de niveau entreprise pour l'IDE Delphi / RAD Studio (via Open Tools API - OTA). Cette extension intègre de manière transparente la puissance des modèles d'intelligence artificielle (LLMs locaux et Cloud) directement dans votre environnement de développement.

## ✨ Fonctionnalités Principales

- 🤖 **Système Multi-Agents & Collaboration Asynchrone** :
  - **Équipe d'Agents AI (Orchestrateur)** : Lancez une chaîne de collaboration en tâche de fond où un **Coder Agent** écrit le code, un **Auditor Agent** en fait la revue de sécurité (mémoire, try..finally), et un **Tester Agent** génère les tests DUnitX correspondants. Leurs interactions s'affichent en temps réel dans votre Chat.
  - **Agents Standards Spécialisés** : Sélectionnez des profils prédéfinis comme *Développeur*, *Architecte Logiciel (SOLID)*, *Auditeur de Code* ou *Testeur Senior (DUnitX)*.
  - **Agents Utilisateur (Skills personnalisés)** : L'extension scanne dynamiquement les fichiers Markdown (`*.md`) de votre dossier de projet pour vous proposer de nouveaux agents configurés selon vos propres règles.

- 📦 **Agent de Migration Globale de Projet** :
  - Sélectionnez l'agent de migration pour moderniser un **projet entier** d'une version ancienne (ex: Delphi 7/2007) vers Delphi 11/12 de façon entièrement asynchrone.
  - Gestion automatique des backups de sécurité (`.bak`).
  - Rechargement automatique et immédiat des fichiers édités dans l'éditeur de RAD Studio.

- 📥 **Interaction Synchrone en Temps Réel avec l'IDE** :
  - **Bouton Insérer (📥)** : Injectez le code sélectionné ou le dernier bloc généré par le chat directement dans votre éditeur de code.
  - **Bouton Nouvelle Unité (📄)** : Créez une nouvelle unité Delphi vierge dans l'IDE contenant le code généré en un seul clic via les services natifs de RAD Studio.

- 📊 **Outils de Diagrammes UML Mermaid** :
  - Traduisez instantanément votre code Delphi actif ou sélectionné en diagrammes UML au format Mermaid.
  - Génération de **Diagrammes de Classes** (`classDiagram`), **Diagrammes de Séquence** (`sequenceDiagram`) ou **Diagrammes de Flux** (`graph TD`) prêts à être intégrés dans vos fichiers de documentation.

- 🎨 **Interface Moderne & Adaptative (Thématisation IDE)** :
  - Détection automatique et mathématique du thème de RAD Studio (Luminance de `clWindow` via le style VCL actif).
  - Bascule automatique entre le mode clair standard et un mode sombre premium moderne (fond anthracite `$1E1E1E`, textes clairs `$E0E0E0`, nuances pastel bleu et vert pour les bulles de discussion).

- 🧠 **Multi-Fournisseurs Avancé & Profils Rapides** :
  - **Profils préconfigurés** : Sélectionnez en 1 clic vos configurations pour *Ollama (Local)*, *LM Studio (Local)*, *OpenAI*, *Google Gemini*, *Anthropic Claude*, *Alibaba Qwen*, et *DeepSeek*.
  - **Détection Automatique des Modèles Locaux** : Un simple clic sur "Actualiser" dans les paramètres interroge votre serveur Ollama ou LM Studio et remplit la liste déroulante avec les modèles réellement installés !
  - **Mémoire de Contexte (Conversation History)** : Garde en mémoire le fil de la discussion (jusqu'à 10 messages glissants) pour vous répondre de façon contextuelle.
  - **Asynchrone & Non-Bloquant** : Toutes les requêtes s'exécutent dans des threads d'arrière-plan (`TThread`).

- ⌨️ **Raccourcis Éditeur Natifs** : 
  - `Ctrl+Alt+Space` : **Autocomplétion**. Sélectionnez un extrait de code, l'IA l'analyse et insère la complétion directement.
  - `Ctrl+Alt+R` : **Refactoring**. Sélectionnez une méthode, l'IA l'optimise selon les meilleures pratiques Delphi et la remplace à la volée.

## 🚀 Installation

1. Clonez ce dépôt ou téléchargez les sources.
2. Ouvrez le projet **`MustDevLLM.dpk`** dans Embarcadero RAD Studio.
3. Dans le Gestionnaire de Projets (Project Manager), faites un clic droit sur `MustDevLLM.bpl` et sélectionnez **Build** (Compiler).
4. Refaites un clic droit et sélectionnez **Install** (Installer).
5. Un nouveau menu **`Must@Dev`** apparaîtra en haut de l'IDE.

## ⚙️ Configuration

Allez dans le menu supérieur de RAD Studio : **`Must@Dev` -> `Configuration...`** (or `Outils` -> `Options` -> `Tierce Partie`).

- **Profil Rapide** : Choisissez votre modèle cible.
- **Modèle** : Cliquez sur **Actualiser** si vous êtes en local pour lister vos modèles installés.
- **Clé API** : Saisissez votre clé de sécurité si vous êtes en mode Cloud.
- **Raccourcis Éditeur** : Personnalisez vos raccourcis clavier si vous le souhaitez.
- **System Prompts** : Modifiez les instructions système par défaut envoyées à l'IA pour correspondre exactement à votre style de programmation.

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.
