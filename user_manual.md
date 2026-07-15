# Manuel d'Utilisation - Must@Dev AI

Ce manuel détaille l'utilisation de l'extension **Must@Dev AI** intégrée à **Embarcadero RAD Studio** (Delphi). Il explique comment configurer l'extension, interagir avec l'assistant de chat hybride, utiliser les raccourcis d'édition automatique, exploiter le système multi-agents en arrière-plan, modéliser avec UML Mermaid, lancer une migration de projet, et lire les fichiers journaux.

---

## 1. Présentation Générale

**Must@Dev AI** est un module d'assistance au codage de niveau entreprise pour Delphi. Il s'intègre via l'Open Tools API (OTA) de RAD Studio pour fournir :
- Un assistant de discussion ancrable (API et Web).
- Une interface adaptative respectant automatiquement le thème clair/sombre de l'IDE.
- Une équipe d'agents d'IA autonomes s'exécutant en tâche de fond (asynchrone).
- Des outils d'interaction en temps réel pour insérer du code ou générer des unités à la volée.
- De l'autocomplétion contextuelle intelligente et du refactoring de code dans l'éditeur de texte.
- Le support des modèles d'IA locaux (Ollama, LM Studio) et distants (OpenAI, Gemini, Claude, Qwen, DeepSeek).

---

## 2. Configuration & Profils Rapides

Pour configurer l'extension, allez dans le menu supérieur de RAD Studio : **`Must@Dev` ➔ `Configuration...`**

### Le Panneau de Configuration

![Panneau de Configuration](file:///C:/Users/mustd/.gemini/antigravity/brain/e52cb2be-e84d-4df3-ae70-1a87ac5fe9b3/media__1783170807465.png)

#### A. Choix du Fournisseur d'IA
- **Serveur Local (Ollama, LM Studio)** : Cochez cette option si vous exécutez un modèle en local sur votre machine.
- **API Cloud (OpenAI, Gemini, Claude, Qwen, DeepSeek)** : Cochez cette option pour utiliser les serveurs officiels distants (nécessite une clé API).

#### B. Profils de Connexion Rapide
La liste déroulante **"Profil Rapide"** pré-configure instantanément les paramètres selon le service choisi :
1. **Ollama** : URL locale par défaut (`http://127.0.0.1:11434/api/generate`).
2. **LM Studio** : URL locale standardisée (`http://127.0.0.1:1234/v1/chat/completions`).
3. **OpenAI** : URL officielle de complétion de chat.
4. **Google Gemini** : URL officielle sécurisée par clé en paramètre de requête.
5. **Anthropic Claude** : URL de messages Anthropic sécurisée par en-têtes HTTP.
6. **Alibaba Qwen** : URL du mode compatible DashScope.
7. **DeepSeek** : URL officielle du service DeepSeek.

#### C. Récupération Dynamique des Modèles (`🔄 Actualiser`)
- Cliquez sur le bouton **`Actualiser`** à côté de la liste des modèles pour interroger dynamiquement le fournisseur et lister tous les modèles disponibles.
- Sélectionnez le modèle cible dans la liste, ou saisissez-en un manuellement.

---

## 3. L'Assistant Chat Hybride & Interaction Temps Réel

L'assistant est accessible via le menu **`Must@Dev` ➔ `AI Assistant...`**. Il s'ancre comme n'importe quel onglet de RAD Studio.

### Outils de Contrôle Synchrone de l'IDE :
Pour assurer un contrôle total au développeur, la barre d'outils du Chat comprend deux boutons d'interaction synchrone :
- **Insérer 📥** : Récupère le code sélectionné ou le dernier bloc de code pascal généré dans l'historique et l'insère immédiatement à l'emplacement du curseur actif dans l'éditeur RAD Studio.
- **Nouvelle unité 📄** : Instancie instantanément un nouvel onglet de code source vierge dans RAD Studio et y injecte le code issu du chat à l'aide d'un créateur de module natif (`IOTAModuleCreator`).
- **Joindre 📎** : Permet au développeur d'importer des fichiers et des images depuis sa machine locale pour enrichir la conversation :
  - **Fichiers textuels** (`.pas`, `.dpr`, `.txt`, `.json`, `.md`...) : Le contenu du fichier est automatiquement lu et injecté en tant que contexte délimité directement dans votre prompt utilisateur.
  - **Images** (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`) : Les images sont converties de manière sécurisée en Base64 et incluses dans la structure de données de requêtes pour les modèles d'IA dotés de facultés multimodales (Gemini, Claude, OpenAI, Ollama).

### Thématisation Adaptative Automatique :
L'interface détecte dynamiquement si l'IDE est configuré en mode clair ou sombre (calcul de luminance relative sur `clWindow` du style VCL actif).
- **Mode Sombre** : L'assistant prend un style moderne de type "VS Code" avec un fond anthracite (`$1E1E1E`), un texte blanc cassé (`$E0E0E0`), et des bulles utilisateur en bleu ciel pastel et IA en vert menthe pour garantir un confort visuel optimal.
- **Mode Clair** : L'interface se fond naturellement dans le style classique gris/blanc de RAD Studio.

---

## 4. Architecture Multi-Agents Autonomes

L'extension propose un sélecteur d'agents (**cbAgents**) vous permettant d'affecter vos requêtes à des entités spécialisées :

### A. Agents Standards Intégrés :
- **Développeur Delphi (Standard)** : Comement classique de programmation.
- **Architecte Logiciel (Conception)** : Privilégie la propreté de code, SOLID, le découplage et l'utilisation de patrons de conception.
- **Auditeur de Code (Sécurité & Perf)** : Traque activement les fuites mémoire, vérifie la sécurité des threads et l'optimisation algorithmique.
- **Testeur Senior (DUnitX)** : Génère des classes de tests unitaires robustes.

### B. Équipe d'Agents AI (Collaboration en Tâche de Fond) :
En sélectionnant **`Équipe d'Agents AI`**, vous lancez une orchestration d'agents qui collaborent de manière asynchrone :
1. Le **Coder Agent** écrit le code d'implémentation initial.
2. L'**Auditor Agent** récupère le code, l'analyse, et corrige à la volée les risques de fuites mémoire en structurant proprement les blocs `try..finally`.
3. Le **Tester Agent** crée automatiquement la suite de tests unitaires DUnitX.
4. Les logs des agents s'affichent en temps réel dans votre chat au fur et à mesure de leur progression, avant de vous livrer le rapport final de synthèse.

### C. Fichiers de Comportement Utilisateur (Custom Skills) :
L'assistant scanne dynamiquement les fichiers Markdown (`*.md`) présents dans le répertoire de votre projet actif. Tout fichier `.md` (par exemple `StandardEntreprise.md`) est automatiquement listé dans le sélecteur d'agents. Sélectionner cet agent injectera son contenu textuel comme règles système de l'IA.

---

## 5. Agent de Migration Globale de Projet

Pour moderniser de vieilles bases de code (ex: Delphi 7, 2007) vers les standards de Delphi 11/12 :
1. Sélectionnez **`Agent : Migrateur de Projet (Ancien ➔ Delphi 11/12)`** dans le sélecteur d'agents et cliquez sur "Envoyer".
2. L'assistant vous demande confirmation via un dialogue d'alerte.
3. Il liste et parcourt automatiquement tous les fichiers `.pas` et `.dpr` du projet actif de manière asynchrone en tâche de fond.
4. **Sécurité** : Pour chaque unité modifiée, une sauvegarde de sécurité `.bak` est générée sur le disque.
5. L'IA réécrit le code pour assurer la compatibilité Unicode (`AnsiString` ➔ `string`) et moderniser l'écriture (variables inline, for inline, generics).
6. **Mise à jour visuelle** : L'IDE recharge automatiquement en temps réel le code de chaque éditeur modifié à l'écran.

---

## 6. Outils de Modélisation Visuelle Mermaid UML

Intégrés dans la liste déroulante des actions rapides sur le code Delphi :
- **UML : Diagramme de Classes de l'Unité (Mermaid)** : Convertit la structure générale de l'unité active (classes, héritages, membres) en diagramme Mermaid (`classDiagram`).
- **UML : Diagramme de Séquence (Mermaid)** : Modélise les interactions et appels de méthodes (`sequenceDiagram`).
- **UML : Flowchart de l'Unité Globale (Mermaid)** : Représente la cinématique générale logique de l'unité (`graph TD`).
- **UML : Flowchart d'une Procédure/Fonction (Mermaid)** : Analyse la fonction active/sélectionnée pour générer son algorithme interne détaillé (tests `if`, `case`, boucles `for`/`while`, blocs d'exception `try`) au format Mermaid (`graph TD`).
- **UML : Diagramme d'État (Mermaid)** : Décrit les états logiques et leurs transitions (`stateDiagram-v2`).
- **UML : Diagramme d'Activité (Mermaid)** : Ordonne le flux d'activité séquentiel (`graph TB`).

Le code généré est copiable pour être inclus directement dans vos wikis de projet ou documentations Git.

---

## 7. Raccourcis d'Édition Directe (OTA)

Pour utiliser l'IA directement dans votre code source Delphi :
1. **Autocomplétion (`Ctrl+Alt+Space`)** : Sélectionnez une signature de méthode ou un début de fonction, appuyez sur le raccourci. L'IA génère et insère le code manquant directement à la position du curseur de l'éditeur sans aucun texte explicatif.
2. **Refactoring (`Ctrl+Alt+R`)** : Sélectionnez un bloc de code existant, appuyez sur le raccourci. L'IA réécrit, modernise et optimise le code sélectionné, puis remplace la sélection à la volée.

---

## 8. Journalisation & Dépannage

Tous les événements et erreurs sont journalisés en double :

### A. Dans l'IDE (Fenêtre Messages)
Les logs INFO, SUCCÈS et ERREUR s'affichent en temps réel dans l'onglet **`Must@Dev AI`** de la fenêtre de Messages au bas de RAD Studio.

### B. Dans un Fichier Journal Physique Horodaté
Chaque jour, un nouveau fichier log thread-safe est généré à l'adresse suivante :
📁 **`C:\Users\<Votre_Utilisateur>\Documents\MustDevLLM\MustDevLLM_AAAAMMJJ.log`**

*Exemple de lignes de journal :*
```log
[2026-07-12 12:41:55] [INFO] Fichier Agent.md injecté dans le contexte.
[2026-07-12 12:42:02] [SUCCES] Réponse du Chat reçue.
[2026-07-12 13:35:01] [INFO] [Tester Agent] Tests unitaires DUnitX rédigés.
```

---

## 9. Exportation au Format PDF

Pour enregistrer ce manuel au format PDF :
1. Ouvrez ce fichier (`user_manual.md`) dans un éditeur prenant en charge le Markdown (comme **VS Code**).
2. Installez l'extension **Markdown PDF** de VS Code.
3. Faites un clic droit dans le fichier et sélectionnez **`Markdown PDF: Export (pdf)`**.
4. Le manuel PDF sera généré instantanément dans le même dossier, prêt à être partagé ou imprimé.
