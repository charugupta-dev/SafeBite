# OCR Ingredient Scanning & Toddler Hazard RAG Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable parents to scan or load packaging images, extract ingredients on-device via ML Kit OCR into editable chips, and evaluate them against a comprehensive toddler hazard database using our 4-stage RAG backend.

**Architecture:** Flutter client runs Google ML Kit on-device text recognition on local packaging images $\to$ parses ingredient tokens into an interactive Chip Review screen $\to$ sends ingredients to FastAPI backend $\to$ Backend matches against `toddler_hazard_database.json` via BM25 + ChromaDB + FlashRank cross-encoder reranker $\to$ returns clinical safety verdict citing CDC/AAP/WHO.

**Tech Stack:** Flutter (Riverpod, MVVM, `google_mlkit_text_recognition`), Python FastAPI, ChromaDB, Rank-BM25, FlashRank ONNX cross-encoder.

---

### Task 1: Save & Ingest Toddler Hazard Database JSON in Backend

**Files:**
- Create: `/Users/charu/Desktop/safebite/safebite_backend/docs/toddler_hazard_database.json`
- Modify: `/Users/charu/Desktop/safebite/safebite_backend/rag_service.py`

- [ ] **Step 1: Write `toddler_hazard_database.json`**
  Save the exact 8-category JSON hazard database provided by the user.

- [ ] **Step 2: Update `load_and_chunk_docs` in `rag_service.py` to parse nested hazard schema**
  Extract each hazard item into a semantic document chunk with:
  `standard_name`, `aliases`, `hazard`, `unsafe_under_months`, and `authority`.

- [ ] **Step 3: Test and index into ChromaDB & BM25**
  Run test script to verify indexing and check that alias queries like `"Tartrazine"`, `"manuka honey"`, and `"HFCS"` match with high FlashRank scores.

---

### Task 2: Update Agent & Backend API for Ingredient Evaluation

**Files:**
- Modify: `/Users/charu/Desktop/safebite/safebite_backend/agent.py`
- Modify: `/Users/charu/Desktop/safebite/safebite_backend/api.py`

- [ ] **Step 1: Update API request model to support age in months**
  Update `FoodCheckRequest` in `api.py` with optional `age_months: int = 12`.

- [ ] **Step 2: Update Agent prompt in `agent.py`**
  Provide clear instructions to evaluate each ingredient from the list against age restrictions, returning:
  `status` (SAFE / CAUTION / UNSAFE), `flagged_ingredients`, and `summary`.

- [ ] **Step 3: Test API endpoint with curl**
  Test `POST /check-food` with `food_name="Raw Honey, Cane Sugar, Wheat Flour"` for a 8-month-old baby.
  Verify Honey is flagged UNSAFE (< 12 months) and Cane Sugar flagged (< 24 months).

---

### Task 3: Add ML Kit Dependency & Sample Images in Flutter

**Files:**
- Modify: `/Users/charu/Desktop/safebite/safebite_app/pubspec.yaml`
- Modify: `/Users/charu/Desktop/safebite/safebite_app/ios/Podfile` (if needed for ML Kit)
- Create: `/Users/charu/Desktop/safebite/safebite_app/assets/images/` sample label image

- [ ] **Step 1: Add `google_mlkit_text_recognition` to `pubspec.yaml`**
  Add dependency and register `assets/images/` folder.

- [ ] **Step 2: Install CocoaPods**
  Run `cd ios && pod install` to link Google ML Kit iOS framework.

---

### Task 4: Implement OCR Service & Ingredient Parser in Flutter

**Files:**
- Create: `/Users/charu/Desktop/safebite/safebite_app/lib/services/ocr_service.dart`

- [ ] **Step 1: Implement `OcrService`**
  - Method `recognizeTextFromPath(String imagePath)`
  - Helper `parseIngredients(String rawText)`: strips prefixes (e.g. "Ingredients:", "Contains:"), splits by `,` or `;`, trims, and filters blanks.

- [ ] **Step 2: Unit test ingredient parsing logic**
  Verify input `"INGREDIENTS: Apples, Raw Honey (2%), Yellow 5."` produces `["Apples", "Raw Honey", "Yellow 5"]`.

---

### Task 5: Build Editable Ingredient Review Screen & Wire MVVM

**Files:**
- Create: `/Users/charu/Desktop/safebite/safebite_app/lib/views/ingredient_review_screen.dart`
- Modify: `/Users/charu/Desktop/safebite/safebite_app/lib/viewmodels/home_viewmodel.dart`
- Modify: `/Users/charu/Desktop/safebite/safebite_app/lib/views/home_screen.dart`

- [ ] **Step 1: Create `IngredientReviewScreen`**
  - Shows list of extracted ingredients as `InputChip`s with delete `✕`.
  - Add text field to enter missing ingredients.
  - "Check Safety" button that triggers the API call.

- [ ] **Step 2: Add Scan/Load Sample Button on `HomeScreen`**
  - Add quick action to load the sample packaging image, run OCR, and navigate to the Review screen.

- [ ] **Step 3: Build & verify on iOS Simulator**
  - Build app using `/Users/charu/Desktop/safebite/safebite_app/run.sh`.
  - Test OCR extraction and safety results end-to-end.
