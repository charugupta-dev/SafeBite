import os
import re
import json
import glob
from pathlib import Path
from pypdf import PdfReader
import chromadb
from chromadb.utils import embedding_functions
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from rank_bm25 import BM25Okapi
from flashrank import Ranker, RerankRequest

BASE_DIR = Path(__file__).resolve().parent
DOCS_DIR = BASE_DIR / "docs"
CHROMA_DIR = BASE_DIR / "chroma_db"
COLLECTION_NAME = "safebite_guidelines"

# ① Embedding Function: all-MiniLM-L6-v2 (free, runs locally via ONNX)
embedding_func = embedding_functions.DefaultEmbeddingFunction()

# ② Cross-Encoder Reranker (Stage 2 in the retrieval funnel)
_reranker_instance = None

def get_reranker():
    global _reranker_instance
    if _reranker_instance is None:
        _reranker_instance = Ranker()
    return _reranker_instance

# Cache for BM25 index and corpus
_bm25_instance = None
_bm25_corpus_docs = None


def tokenize(text: str) -> list[str]:
    """Alphanumeric tokenizer for BM25 keyword matching."""
    return re.findall(r'\w+', text.lower())


def load_and_chunk_docs(docs_directory=DOCS_DIR, chunk_size=450, chunk_overlap=50):
    """
    Loads both PDFs and structured JSON files from docs directory:
    - PDFs: extracted page-by-page and chunked with RecursiveCharacterTextSplitter.
    - JSONs: each record/item is indexed as a clean, complete semantic unit.
    """
    raw_docs = []

    # 1. Process PDFs
    pdf_files = glob.glob(os.path.join(docs_directory, "*.pdf"))
    for pdf_path in pdf_files:
        filename = os.path.basename(pdf_path)
        reader = PdfReader(pdf_path)
        for page_num, page in enumerate(reader.pages):
            text = page.extract_text() or ""
            if text.strip():
                raw_docs.append(
                    Document(
                        page_content=text,
                        metadata={"source": filename, "page": page_num + 1, "type": "pdf"}
                    )
                )

    # 2. Process JSON files (Structured data)
    json_files = glob.glob(os.path.join(docs_directory, "*.json"))
    json_chunk_count = 0
    for json_path in json_files:
        filename = os.path.basename(json_path)
        try:
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                
            entries = []
            if isinstance(data, dict) and "toddler_hazard_database" in data:
                db = data["toddler_hazard_database"]
                for cat_name, items in db.items():
                    if isinstance(items, list):
                        for item in items:
                            if isinstance(item, dict):
                                item_copy = item.copy()
                                item_copy["category"] = cat_name
                                entries.append(item_copy)
            elif isinstance(data, list):
                entries = data
            elif isinstance(data, dict):
                entries = [data]

            for idx, item in enumerate(entries):
                if isinstance(item, dict):
                    std_name = item.get("standard_name") or item.get("food") or item.get("name") or f"Item {idx+1}"
                    category = item.get("category", "").replace("_", " ").title()
                    aliases = ", ".join(item.get("aliases", [])) if isinstance(item.get("aliases"), list) else item.get("aliases", "")
                    unsafe_months = item.get("unsafe_under_months", "")
                    hazard = item.get("hazard", "")
                    authority = item.get("authority", "")

                    lines = [f"Item: {std_name}"]
                    if category:
                        lines.append(f"Category: {category}")
                    if aliases:
                        lines.append(f"Aliases & Common Names: {aliases}")
                    if unsafe_months != "":
                        lines.append(f"Safety Restriction: Strictly unsafe for children under {unsafe_months} months of age.")
                    if hazard:
                        lines.append(f"Hazard & Health Risk: {hazard}")
                    if authority:
                        lines.append(f"Health Authority & Guidelines: {authority}")
                    
                    content = "\n".join(lines)
                else:
                    content = str(item)

                raw_docs.append(
                    Document(
                        page_content=content,
                        metadata={
                            "source": filename,
                            "page": idx + 1,
                            "type": "json",
                            "standard_name": item.get("standard_name", ""),
                            "unsafe_under_months": item.get("unsafe_under_months", 0)
                        }
                    )
                )
                json_chunk_count += 1
        except Exception as e:
            print(f"⚠️ Error reading {filename}: {e}")

    # Split PDF documents using RecursiveCharacterTextSplitter
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        separators=["\n\n", "\n", "•", " ", ""]
    )
    
    # We only need to chunk long PDF pages; JSON records are already atomized
    pdf_docs = [d for d in raw_docs if d.metadata.get("type") == "pdf"]
    json_docs = [d for d in raw_docs if d.metadata.get("type") == "json"]
    
    pdf_chunks = text_splitter.split_documents(pdf_docs) if pdf_docs else []
    all_chunks = pdf_chunks + json_docs

    print(f"📄 Loaded {len(pdf_files)} PDFs and {len(json_files)} JSONs ➡️ Total {len(all_chunks)} indexable chunks.")
    return all_chunks


def index_documents(force_reindex=False):
    """
    Indexes document chunks into local persistent ChromaDB.
    """
    global _bm25_instance, _bm25_corpus_docs
    client = chromadb.PersistentClient(path=str(CHROMA_DIR))
    
    existing_collections = [c.name for c in client.list_collections()]
    if COLLECTION_NAME in existing_collections and not force_reindex:
        collection = client.get_collection(name=COLLECTION_NAME, embedding_function=embedding_func)
        if collection.count() > 0:
            return collection

    if COLLECTION_NAME in existing_collections:
        client.delete_collection(COLLECTION_NAME)

    collection = client.create_collection(
        name=COLLECTION_NAME,
        embedding_function=embedding_func,
        metadata={"description": "Pediatric & Toddler Food Safety Knowledge Base"}
    )

    chunks = load_and_chunk_docs()

    documents = [c.page_content for c in chunks]
    metadatas = [c.metadata for c in chunks]
    ids = [f"chunk_{i+1}" for i in range(len(chunks))]

    collection.add(documents=documents, metadatas=metadatas, ids=ids)
    print(f"🎉 Successfully indexed {collection.count()} chunks into ChromaDB at {CHROMA_DIR}!")
    
    _bm25_instance = None
    _bm25_corpus_docs = None
    return collection


def _get_bm25_index():
    global _bm25_instance, _bm25_corpus_docs
    if _bm25_instance is not None:
        return _bm25_instance, _bm25_corpus_docs

    client = chromadb.PersistentClient(path=str(CHROMA_DIR))
    collection = client.get_collection(name=COLLECTION_NAME, embedding_function=embedding_func)
    
    all_data = collection.get()
    ids = all_data["ids"]
    docs = all_data["documents"]
    metas = all_data["metadatas"]
    
    corpus_docs = []
    tokenized_corpus = []
    
    for doc_id, doc, meta in zip(ids, docs, metas):
        item = {
            "id": doc_id,
            "content": doc,
            "source": meta.get("source", "unknown"),
            "page": meta.get("page", 1)
        }
        corpus_docs.append(item)
        tokenized_corpus.append(tokenize(doc))
        
    _bm25_instance = BM25Okapi(tokenized_corpus)
    _bm25_corpus_docs = corpus_docs
    return _bm25_instance, _bm25_corpus_docs


def bm25_search(query: str, top_k: int = 10):
    """Librarian A: Exact keyword search."""
    bm25, corpus = _get_bm25_index()
    tokens = tokenize(query)
    if not tokens:
        return []
    
    scores = bm25.get_scores(tokens)
    scored_items = sorted(zip(corpus, scores), key=lambda x: x[1], reverse=True)
    
    results = []
    for item, score in scored_items[:top_k]:
        if score > 0:
            results.append({
                **item,
                "bm25_score": round(float(score), 4)
            })
    return results


def vector_search(query: str, top_k: int = 10):
    """Librarian B: Vector embedding search via ChromaDB."""
    client = chromadb.PersistentClient(path=str(CHROMA_DIR))
    collection = client.get_collection(name=COLLECTION_NAME, embedding_function=embedding_func)
    
    raw = collection.query(query_texts=[query], n_results=top_k)
    results = []
    
    if raw and raw["documents"] and raw["documents"][0]:
        for doc_id, doc, meta, dist in zip(raw["ids"][0], raw["documents"][0], raw["metadatas"][0], raw["distances"][0]):
            results.append({
                "id": doc_id,
                "content": doc,
                "source": meta.get("source", "unknown"),
                "page": meta.get("page", 1),
                "distance": round(float(dist), 4)
            })
    return results


def hybrid_search(query: str, top_k: int = 10, rrf_k: int = 60):
    """
    Stage 1: Fast Candidate Generation with Reciprocal Rank Fusion (RRF).
    Merges BM25 + Vector Search to produce top candidate chunks.
    """
    bm25_candidates = bm25_search(query, top_k=top_k)
    vector_candidates = vector_search(query, top_k=top_k)
    
    doc_map = {}
    rrf_scores = {}
    
    for rank, item in enumerate(bm25_candidates, 1):
        doc_id = item["id"]
        doc_map[doc_id] = item
        rrf_scores[doc_id] = rrf_scores.get(doc_id, 0.0) + (1.0 / (rrf_k + rank))
        
    for rank, item in enumerate(vector_candidates, 1):
        doc_id = item["id"]
        doc_map[doc_id] = item
        rrf_scores[doc_id] = rrf_scores.get(doc_id, 0.0) + (1.0 / (rrf_k + rank))
        
    sorted_ids = sorted(rrf_scores.keys(), key=lambda did: rrf_scores[did], reverse=True)
    
    results = []
    for doc_id in sorted_ids[:top_k]:
        item = doc_map[doc_id].copy()
        item["rrf_score"] = round(rrf_scores[doc_id], 5)
        results.append(item)
    return results


def rerank_passages(query: str, candidate_chunks: list[dict], top_k: int = 3):
    """
    Stage 2: Cross-Encoder Reranking (The Interview Stage).
    Scores (query, passage) pairs jointly through the transformer attention mechanism.
    """
    if not candidate_chunks:
        return []

    ranker = get_reranker()
    passages = [
        {"id": c["id"], "text": c["content"], "meta": {"source": c["source"], "page": c["page"], "rrf_score": c.get("rrf_score", 0)}}
        for c in candidate_chunks
    ]
    
    rerank_request = RerankRequest(query=query, passages=passages)
    reranked = ranker.rerank(rerank_request)
    
    results = []
    for r in reranked[:top_k]:
        meta = r.get("meta", {})
        results.append({
            "id": r["id"],
            "content": r["text"],
            "source": meta.get("source", "unknown"),
            "page": meta.get("page", 1),
            "rerank_score": round(float(r["score"]), 4),
            "stage1_rrf_score": meta.get("rrf_score", 0)
        })
    return results


def retrieve_relevant_guidelines(query: str, k: int = 2):
    """
    Full 2-Stage RAG Pipeline:
    1. Fast Hybrid Sweep (BM25 + Vector + RRF) -> gets top 8 candidates.
    2. Cross-Encoder Reranker -> evaluates candidates and picks top k winners.
    """
    # Stage 1: Broad hybrid candidate generation
    candidates = hybrid_search(query, top_k=8)
    
    # Stage 2: Deep cross-encoder reranking
    winners = rerank_passages(query, candidates, top_k=k)
    return winners


if __name__ == "__main__":
    index_documents(force_reindex=False)
    
    test_queries = [
        "Can a baby eat honey?",
        "Choking hazard for whole grapes",
        "E102 food dye"
    ]
    
    for q in test_queries:
        print("\n" + "="*65)
        print(f"🔎 QUERY: '{q}'")
        print("="*65)
        
        # Show Stage 1 vs Stage 2
        stage1 = hybrid_search(q, top_k=5)
        print("\n📋 STAGE 1 (Hybrid Candidates - BM25 + Vector RRF):")
        for idx, c in enumerate(stage1[:3], 1):
            print(f"  [{idx}] (RRF: {c['rrf_score']}) {c['content'][:90].strip()}...")

        stage2 = retrieve_relevant_guidelines(q, k=2)
        print("\n🎙️ STAGE 2 (Cross-Encoder Rerank Winners):")
        for idx, w in enumerate(stage2, 1):
            print(f"  ★ Winner #{idx} (Rerank Score: {w['rerank_score']}) from {w['source']}")
            print(f"    \"{w['content'][:120].strip()}...\"")
