# Must@Dev - AI Integration Module pour RAD Studio

> 🚀 **Une alternative Open Source, souveraine et multi-agents à Embarcadero Kai™**

Bienvenue dans **Must@Dev AI**, une extension de niveau entreprise pour l'IDE Delphi / RAD Studio (via Open Tools API - OTA). Cette extension intègre de manière transparente la puissance des modèles d'intelligence artificielle (LLMs locaux et Cloud) directement dans votre environnement de développement.

---

## 💡 Pourquoi choisir Must@Dev AI face à Embarcadero Kai™ ?

**Embarcadero Kai** est l'assistant IA commercial intégré de RAD Studio. **Must@Dev AI** se positionne comme une alternative open source plus puissante, plus flexible et respectueuse de la confidentialité de votre code :

| Fonctionnalités | 🤖 Must@Dev AI (Open Source) | 💎 Embarcadero Kai (Commercial) |
| :--- | :--- | :--- |
| **Coût** | **100% Gratuit & Open Source** (MIT) | Payant (Inclus uniquement sous conditions ou abonnements) |
| **Souveraineté & Confidentialité** | **Total** (Supporte les serveurs locaux Ollama/LM Studio hors ligne) | **Limité** (Envoie obligatoirement le code sur des serveurs Cloud tiers) |
| **Choix des Modèles** | **Illimité** (Gemini, Claude, OpenAI, DeepSeek, Qwen, Ollama...) | **Unique** (Modèle imposé par Embarcadero) |
| **Multi-Agents Autonomes** | **Oui** (Chaîne asynchrone Coder + Auditeur de fuites + Testeur DUnitX) | **Non** (Chat conversationnel simple à un seul agent) |
| **Migration Globale de Projet** | **Oui** (Agent dédié pour migrer de vieux projets en Delphi 11/12 avec backups) | **Non** (Limité au code actif ou sélectionné) |
| **Diagrammes UML Mermaid** | **Oui** (Génération de diagrammes de Classes, Séquence et Flux Mermaid) | **Non** |
| **Boutons d'intégration IDE** | **Oui** (Boutons physiques *Insérer* et *Nouvelle Unité* natifs) | Basique |

---

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

- 📎 **Envoi de fichiers et d'images (Multimodalité)** :
  - **Bouton Joindre (📎)** : Permet de sélectionner un ou plusieurs fichiers ou images locaux à envoyer à la conversation.
  - Les fichiers de code source et textes (`.pas`, `.txt`, `.json`, `.md`...) sont **injectés intelligemment** dans le contexte du prompt.
  - Les images (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`) sont **encodées en Base64** et transmises directement aux modèles supportant le multimodal (Gemini, Claude, OpenAI, Ollama).

- 📊 **Outils de Diagrammes UML Mermaid** :
  - Traduisez instantanément votre code Delphi actif ou sélectionné en diagrammes UML ou de flux au format Mermaid.
  - Génération de **Diagrammes de Classes de l'Unité** (`classDiagram`), **Diagrammes de Séquence** (`sequenceDiagram`), **Flowchart Global de l'Unité** (`graph TD`), **Flowchart détaillé d'une Procédure/Fonction** avec ses boucles/conditions, **Diagrammes d'État** (`stateDiagram-v2`), et **Diagrammes d'Activité** (`graph TB`).
  - Prêt à être directement intégré dans vos fichiers de documentation de dépôt.

- 🎨 **Interface Moderne & Adaptative (Thématisation IDE)** :
  - Détection automatique et mathématique du thème de RAD Studio (Luminance de `clWindow` via le style VCL actif).
  - Bascule automatique entre le mode clair standard et un mode sombre premium moderne (fond anthracite `$1E1E1E`, textes clairs `$E0E0E0`, nuances pastel bleu et vert pour les bulles de discussion).

- 🧠 **Multi-Fournisseurs Avancé & Profils Rapides** :
  - **Profils préconfigurés** : Sélectionnez en 1 clic vos configurations pour *Ollama (Local)*, *LM Studio (Local)*, *OpenAI*, *Google Gemini*, *Anthropic Claude*, *Alibaba Qwen*, et *DeepSeek*.
  - **Détection Automatique des Modèles Locaux** : Un simple clic sur "Actualiser" dans les paramètres interroge votre serveur Ollama ou LM Studio et remplit la liste déroulante avec les modèles réellement installés !
  - **Mémoire de Contexte (Conversation History)** : Garde en mémoire le fil de la discussion (jusqu'à 10 messages glissants) pour vous répondre de façon contextuelle.
  - **Asynchrone & Non-Bloquant** : Toutes les requêtes s'exécutent dans des threads d'arrière-plan (`TThread`).
  - **Indicateur de travail & Bouton d'Arrêt** : Pendant l'attente d'une réponse de l'IA, le curseur passe en sablier et le bouton *Envoyer* se transforme en **`🛑 Arrêter`**. Cliquer dessus interrompt instantanément la connexion réseau active (Ollama, Gemini, Claude, OpenAI) de manière propre.

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
