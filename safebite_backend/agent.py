import os
import json
from typing import Optional
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
def get_health_profile(target: str, age_months: int = 8, age_range: Optional[str] = None):
    target_clean = target.lower()
    if "baby" in target_clean or "child" in target_clean or "toddler" in target_clean:
        age_desc = f"Age Range: {age_range} (approx {age_months} months)" if age_range else f"Age: {age_months} months"
        return (
            f"Subject: Infant/Toddler, {age_desc}.\n"
            f"Official Pediatric Safety Rules (AAP, CDC, WHO):\n"
            f"- Under 12 months: Strictly NO honey (infant botulism risk).\n"
            f"- Under 24 months: Strictly NO added sugars/syrups (Cane sugar, HFCS, corn syrup, molasses).\n"
            f"- Under 36 months: Strictly NO artificial sweeteners (Sucralose, Aspartame), synthetic preservatives (Sodium Benzoate, Sodium Nitrite), or artificial dyes (Red 40, Yellow 5 / Tartrazine).\n"
            f"- Under 48-60 months: Strictly NO whole nuts, popcorn, marshmallows, or hard sticky candies (choking hazards).\n"
            f"- Any age: NO partially hydrogenated oils (trans fats), NO unpasteurized milk/juice.\n"
            f"- Safe: Plain whole fruits, vegetables, grains, purees without added sugars or additives."
        )
    elif "parent" in target_clean:
        return "Age: 65 years. Rules: Diabetic and high blood pressure. Low refined sugar, low sodium."
    elif "me" in target_clean:
        return "Age: 30 years. Rules: Lactose intolerant. No dairy."
    return "Healthy individual with no specific restrictions."

# --- TOOL FUNCTIONS ---
def query_food_guidelines_rag(query: str):
    """Searches official PDF and JSON hazard guidelines (WHO, CDC, AAP) in ChromaDB."""
    print(f"🔧 Tool called: query_food_guidelines_rag('{query}')")
    results = retrieve_relevant_guidelines(query, k=4)
    if not results:
        return "No specific document guidelines found."
    
    formatted = []
    for r in results:
        formatted.append(f"[{r['source']}]:\n{r['content']}")
    return "\n\n".join(formatted)

tools = [
    {
        "type": "function",
        "function": {
            "name": "query_food_guidelines_rag",
            "description": "Searches the official pediatric and nutritional safety library (WHO, CDC, AAP, FDA) for food safety rules, hazards, aliases, and recommendations.",
            "parameters": {
                "type": "object",
                "properties": {"query": {"type": "string", "description": "The key ingredients or food items to check against safety guidelines"}},
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

def analyze_food_safety(food: str, target: str = "baby", age_months: int = 8, age_range: Optional[str] = None, return_metadata=False):
    system_prompt = (
        "You are Safebite, an evidence-based AI Food Safety Assistant backed by medical guidelines (AAP, CDC, WHO, FDA).\n"
        "1. In 1 single tool call to 'query_food_guidelines_rag', query all suspect hazard ingredients together (e.g. 'sugar salt honey additives in cereal'). Do NOT make repeated sequential tool calls for every ingredient.\n"
        "2. After getting the guideline results, IMMEDIATELY formulate your final evaluation.\n"
        "3. LINE 1 OF YOUR RESPONSE MUST BE THE OVERALL VERDICT BADGE:\n"
        "   - '🔴 UNSAFE' if ANY ingredient is hazardous/prohibited for this age (e.g. honey <12 mo, added sugars/syrups <24 mo, dyes <36 mo, choking hazards).\n"
        "   - '🟡 CAUTION' if conditionally safe with special preparation.\n"
        "   - '🟢 SAFE' if all ingredients are safe and appropriate for this age.\n"
        "4. Follow with clear, parent-friendly bullet points explaining each ingredient, quoting hazards and health authorities (CDC, AAP, WHO, FDA).\n"
        "5. Keep it direct and factual."
    )
    
    age_str = f"{age_range} (approx {age_months} months)" if age_range else f"Age: {age_months} months"
    user_prompt = f"Evaluate these ingredients: '{food}' for {target} ({age_str})."
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt}
    ]
    
    tools_used = []
    final_content = ""
    
    for _ in range(4):
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
                    result = get_health_profile(target_arg, age_months=age_months)
                else:
                    result = "Unknown tool."
                    
                messages.append({"role": "tool", "tool_call_id": call.id, "content": result})
        else:
            final_content = msg.content or ""
            break

    if not final_content:
        # Prompt model to produce final answer if it exhausted tool loop
        messages.append({"role": "user", "content": "Please provide your final safety verdict and explanation now based on the findings above."})
        res = client.chat.completions.create(
            model=model_name,
            messages=messages,
            tools=tools,
            temperature=0.1
        )
        final_content = res.choices[0].message.content or ""

    if return_metadata:
        return {"content": final_content, "tools_used": tools_used}
    return final_content

if __name__ == "__main__":
    print("Testing mashed apple for baby:")
    print(analyze_food_safety("mashed apple", "baby"))
