import os
import json
from pathlib import Path
from openai import OpenAI
from dotenv import load_dotenv
from rag_service import retrieve_relevant_guidelines, index_documents

# Ensure ChromaDB index exists on startup
index_documents(force_reindex=False)

env_path = Path(__file__).resolve().parent / ".env"
if not env_path.exists():
    env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

if os.getenv("GROQ_API_KEY"):
    client = OpenAI(
        api_key=os.getenv("GROQ_API_KEY"),
        base_url="https://api.groq.com/openai/v1",
    )
    model_name = "openai/gpt-oss-20b"
elif os.getenv("OPENAI_API_KEY"):
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    model_name = "gpt-4o-mini"
else:
    raise ValueError("No API key found. Add OPENAI_API_KEY or GROQ_API_KEY to your .env file.")

# --- HEALTH PROFILES ---
PROFILES_DB = {
    "baby": "Age: 8 months. Rules: STRICTLY NO added sugar, NO caffeine, NO honey, NO artificial flavors/sweeteners. High choking risk: foods must be soft/pureed.",
    "parent": "Age: 65 years. Rules: Diabetic and high blood pressure. Must have low sugar and low sodium.",
    "me": "Age: 30 years. Rules: Lactose intolerant. No dairy."
}

# --- TOOL FUNCTIONS ---
def query_food_guidelines_rag(query: str):
    """Searches official PDF guidelines (WHO, CDC, AAP) in ChromaDB."""
    print(f"🔧 Tool called: query_food_guidelines_rag('{query}')")
    results = retrieve_relevant_guidelines(query, k=2)
    if not results:
        return "No specific document guidelines found."
    
    formatted = []
    for r in results:
        formatted.append(f"[{r['source']} - Page {r['page']}]:\n{r['content']}")
    return "\n\n".join(formatted)

def get_health_profile(target: str):
    print(f"🔧 Tool called: get_health_profile('{target}')")
    return PROFILES_DB.get(target.lower(), "Healthy adult with no specific restrictions.")

tools = [
    {
        "type": "function",
        "function": {
            "name": "query_food_guidelines_rag",
            "description": "Searches the official pediatric and nutritional safety library (WHO, CDC, AAP) for food safety rules, hazards, and recommendations.",
            "parameters": {
                "type": "object",
                "properties": {"query": {"type": "string", "description": "The food item, ingredient, or safety question to search in the guidelines"}},
                "required": ["query"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_health_profile",
            "description": "Get the dietary restrictions and health rules for a specific person (baby, parent, or me).",
            "parameters": {
                "type": "object",
                "properties": {"target": {"type": "string", "description": "the target person, e.g., baby, parent, or me"}},
                "required": ["target"],
            },
        },
    }
]

def analyze_food_safety(food: str, target: str, return_metadata=False):
    system_prompt = (
        "You are Safebite, an AI Food Safety Assistant backed by medical and clinical guidelines.\n"
        "1. Always use 'query_food_guidelines_rag' to search your library for the food item and 'get_health_profile' for the person's rules.\n"
        "2. Answer with a clear '🟢 SAFE', '🟡 CAUTION', or '🔴 UNSAFE' on the very first line.\n"
        "3. Provide 2-3 short bullet points citing facts directly from the retrieved guidelines (mentioning WHO or CDC/AAP if applicable).\n"
        "4. If there is a choking hazard or preparation instruction (like cutting grapes), explicitly mention it."
    )
    
    user_prompt = f"Is {food} safe for {target}?"
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt}
    ]
    
    tools_used = []
    
    for _ in range(3):
        response = client.chat.completions.create(
            model=model_name, 
            messages=messages, 
            tools=tools,
            temperature=0.1
        )
        msg = response.choices[0].message
        
        if msg.tool_calls:
            messages.append(msg)
            for call in msg.tool_calls:
                args = json.loads(call.function.arguments)
                
                if call.function.name == "query_food_guidelines_rag":
                    query_arg = args.get("query", food)
                    tools_used.append(f"query_food_guidelines_rag('{query_arg}')")
                    result = query_food_guidelines_rag(query_arg)
                
                elif call.function.name == "get_health_profile":
                    target_arg = args.get("target", target)
                    tools_used.append(f"get_health_profile('{target_arg}')")
                    result = get_health_profile(target_arg)
                else:
                    result = "Unknown tool."
                    
                messages.append({"role": "tool", "tool_call_id": call.id, "content": result})
        else:
            break

    if return_metadata:
        return {"content": msg.content or "", "tools_used": tools_used}
    return msg.content

if __name__ == "__main__":
    print("Testing chocolate for baby:")
    print(analyze_food_safety("chocolate", "baby"))
    print("\n---------------------------\n")
    print("Testing whole grapes for baby:")
    print(analyze_food_safety("whole grapes", "baby"))
