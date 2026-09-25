# SafeBite: OCR Ingredient Scanning & Toddler Hazard RAG Design

## 1. Goal
Enable parents to scan or load food ingredient packaging images in Flutter, run on-device OCR using Google ML Kit to extract ingredients into editable review chips, and verify safety against a pediatric hazard database (JSON rules + 4-stage RAG) via FastAPI.

## 2. Architecture & Components

### 2.1 Backend (`safebite_backend`)
- **Hazard Database**: `docs/toddler_hazard_database.json`
  - 8 core categories: microbiological/pathogens, stimulants, added sugars, artificial sweeteners, dangerous fats, synthetic preservatives/nitrates, artificial colors, physical choking hazards.
  - Fields per hazard: `standard_name`, `aliases`, `hazard`, `unsafe_under_months`, `authority`.
- **RAG Ingestion (`rag_service.py`)**:
  - Parses `toddler_hazard_database.json`.
  - Creates structured semantic chunks including standard names, aliases, age cutoffs, and hazards.
  - Indexes into ChromaDB vector store + BM25 keyword index.
- **Reranker**:
  - `flashrank` (`ms-marco-TinyBERT-L-2-v2`) cross-encoder reranks top candidate chunks before feeding context to LLM.
- **Evaluation API (`api.py`)**:
  - Endpoint `POST /check-food` accepts `{ "food_name": "...", "profile": "baby", "age_months": 8 }`.

### 2.2 Frontend (`safebite_app`)
- **Package**: `google_mlkit_text_recognition` + `image_picker` or local file loader.
- **State Management**: Flutter Riverpod with MVVM.
- **Screen Flow**:
  1. **Home / Scanner Screen**:
     - Profile badge: "Baby (8 months)".
     - Image loading / scanning trigger (supports loading sample label image from assets/documents for easy simulator testing).
  2. **Review Ingredients Screen**:
     - Displays extracted ingredients as editable chip tags.
     - Parents can tap to remove or add missing items.
     - "Check Safety" button.
  3. **Safety Results Screen**:
     - Status badge (🔴 UNSAFE / 🟡 CAUTION / 🟢 SAFE).
     - Breakdown per ingredient citing health authorities (CDC, AAP, WHO).

## 3. Scope & Constraints
- Focus strictly on the happy flow: simple, readable, and maintainable.
- Simulator friendly: local sample packaging images in `docs/` or `assets/` so testing does not require physical camera hardware.
- **STRICT RULE**: Do NOT push anything to Git until the user explicitly requests it.
