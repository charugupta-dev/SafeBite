import os
import glob
from pathlib import Path
from pypdf import PdfReader
import chromadb
from chromadb.utils import embedding_functions
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter

BASE_DIR = Path(__file__).resolve().parent
DOCS_DIR = BASE_DIR / "docs"
CHROMA_DIR = BASE_DIR / "chroma_db"
COLLECTION_NAME = "safebite_guidelines"

# ① Embedding Function: all-MiniLM-L6-v2 (free, runs locally via ONNX)
embedding_func = embedding_functions.DefaultEmbeddingFunction()

def load_and_chunk_pdfs(docs_directory=DOCS_DIR, chunk_size=450, chunk_overlap=50):
    """
    1. Reads all PDF documents from the docs folder.
    2. Extracts text page-by-page.
    3. Splits text into semantic chunks with overlap using RecursiveCharacterTextSplitter.
    """
    pdf_files = glob.glob(os.path.join(docs_directory, "*.pdf"))
    if not pdf_files:
        raise FileNotFoundError(f"No PDF files found in {docs_directory}")

    raw_docs = []
    for pdf_path in pdf_files:
        filename = os.path.basename(pdf_path)
        reader = PdfReader(pdf_path)
        for page_num, page in enumerate(reader.pages):
            text = page.extract_text() or ""
            if text.strip():
                raw_docs.append(
                    Document(
                        page_content=text,
                        metadata={"source": filename, "page": page_num + 1}
                    )
                )

    # Split using RecursiveCharacterTextSplitter
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        separators=["\n\n", "\n", "•", " ", ""]
    )
    chunks = text_splitter.split_documents(raw_docs)
    print(f"📄 Loaded {len(pdf_files)} PDFs ({len(raw_docs)} pages) ➡️ Created {len(chunks)} chunks.")
    return chunks


def index_documents(force_reindex=False):
    """
    Indexes document chunks into local persistent ChromaDB.
    """
    client = chromadb.PersistentClient(path=str(CHROMA_DIR))
    
    # Check if collection already exists
    existing_collections = [c.name for c in client.list_collections()]
    if COLLECTION_NAME in existing_collections and not force_reindex:
        collection = client.get_collection(name=COLLECTION_NAME, embedding_function=embedding_func)
        if collection.count() > 0:
            print(f"📚 Found existing ChromaDB with {collection.count()} chunks. Skipping re-indexing.")
            return collection

    if COLLECTION_NAME in existing_collections:
        client.delete_collection(COLLECTION_NAME)

    collection = client.create_collection(
        name=COLLECTION_NAME,
        embedding_function=embedding_func,
        metadata={"description": "Pediatric & Toddler Food Safety Knowledge Base"}
    )

    chunks = load_and_chunk_pdfs()

    # Prepare data for ChromaDB
    documents = [c.page_content for c in chunks]
    metadatas = [c.metadata for c in chunks]
    ids = [f"chunk_{i+1}" for i in range(len(chunks))]

    collection.add(documents=documents, metadatas=metadatas, ids=ids)
    print(f"🎉 Successfully indexed {collection.count()} chunks into ChromaDB at {CHROMA_DIR}!")
    return collection


def retrieve_relevant_guidelines(query: str, k: int = 3):
    """
    Retrieves top-k most relevant chunks from ChromaDB using vector similarity.
    """
    client = chromadb.PersistentClient(path=str(CHROMA_DIR))
    collection = client.get_collection(name=COLLECTION_NAME, embedding_function=embedding_func)
    
    results = collection.query(
        query_texts=[query],
        n_results=k
    )
    
    formatted_results = []
    if results and results["documents"]:
        docs = results["documents"][0]
        metas = results["metadatas"][0]
        distances = results["distances"][0] if "distances" in results else [0] * len(docs)
        
        for doc, meta, dist in zip(docs, metas, distances):
            formatted_results.append({
                "content": doc,
                "source": meta.get("source", "unknown"),
                "page": meta.get("page", 1),
                "distance": round(dist, 4)
            })
            
    return formatted_results


if __name__ == "__main__":
    print("--- 1. Indexing Documents ---")
    index_documents(force_reindex=True)

    print("\n--- 2. Testing Query: 'Can a baby eat chocolate?' ---")
    results = retrieve_relevant_guidelines("Can a baby eat chocolate?")
    for idx, r in enumerate(results, 1):
        print(f"\n[Result {idx}] (Source: {r['source']}, Page {r['page']}, Dist: {r['distance']})")
        print(f"  {r['content']}")

    print("\n--- 3. Testing Query: 'Choking hazard whole grapes' ---")
    results = retrieve_relevant_guidelines("Choking hazard whole grapes")
    for idx, r in enumerate(results, 1):
        print(f"\n[Result {idx}] (Source: {r['source']}, Page {r['page']}, Dist: {r['distance']})")
        print(f"  {r['content']}")
