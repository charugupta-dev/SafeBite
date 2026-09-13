import os
import json
from pathlib import Path
from openai import OpenAI
from dotenv import load_dotenv

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

# --- MOCK DATA FOR OUR TOOLS ---
FOOD_DB = {
    "banana": "Ingredients: 100% natural banana. High in potassium, vitamin B6, and natural sugars.",
    "chocolate": "Ingredients: High sugar, cocoa mass, milk powder, caffeine, artificial flavors.",
    "chips": "Ingredients: Potatoes, palm oil, heavy salt, artificial colors (Red 40)."
}

PROFILES_DB = {
    "baby": "Age: 8 months. Rules: STRICTLY NO added sugar, NO caffeine, NO honey, NO artificial flavors. Only soft natural foods.",
    "parent": "Age: 65 years. Rules: Diabetic and high blood pressure. Must have low sugar and low sodium.",
    "me": "Age: 30 years. Rules: Lactose intolerant. No dairy."
}

# --- TOOL FUNCTIONS ---
def get_ingredient_details(food):
    print(f"🔧 tool called: get_ingredient_details({food})")
    return FOOD_DB.get(food.lower(), "Unknown food. Assume it might have basic preservatives.")

def get_health_profile(target):
    print(f"🔧 tool called: get_health_profile({target})")
    return PROFILES_DB.get(target.lower(), "Healthy adult with no specific restrictions.")

tools = [
    {
        "type": "function",
        "function": {
            "name": "get_ingredient_details",
            "description": "Get the ingredients and nutritional info of a specific food.",
            "parameters": {
                "type": "object",
                "properties": {"food": {"type": "string", "description": "the food name, e.g., banana or chocolate"}},
                "required": ["food"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_health_profile",
            "description": "Get the dietary restrictions and health rules for a specific person.",
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
        "You are Safebite, a Food Safety AI. Your job is to tell the user if a food is safe for a specific person.\n"
        "1. ALWAYS call BOTH tools (get_ingredient_details AND get_health_profile) before answering.\n"
        "2. Answer with a clear '🟢 SAFE', '🟡 CAUTION', or '🔴 UNSAFE' on the first line.\n"
        "3. Provide 2-3 short bullet points explaining why based on the ingredients and rules."
    )
    
    user_prompt = f"Is {food} safe for {target}?"
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt}
    ]
    
    tools_used = []
    
    for i in range(3): # max 3 turns for tool calling
        response = client.chat.completions.create(
            model=model_name, 
            messages=messages, 
            tools=tools,
            temperature=0.2
        )
        msg = response.choices[0].message
        
        if msg.tool_calls:
            messages.append(msg)
            for call in msg.tool_calls:
                args = json.loads(call.function.arguments)
                
                if call.function.name == "get_ingredient_details":
                    food_arg = args.get("food", food)
                    tools_used.append(f"get_ingredient_details({food_arg})")
                    result = get_ingredient_details(food_arg)
                
                elif call.function.name == "get_health_profile":
                    target_arg = args.get("target", target)
                    tools_used.append(f"get_health_profile({target_arg})")
                    result = get_health_profile(target_arg)
                else:
                    result = "Unknown tool."
                    
                messages.append({"role": "tool", "tool_call_id": call.id, "content": result})
        else:
            # The model gave a final answer (no tools called)
            break

    if return_metadata:
        return {"content": msg.content or "", "tools_used": tools_used}
    return msg.content

if __name__ == "__main__":
    print(analyze_food_safety("chocolate", "baby"))
    print("\n----------------\n")
    print(analyze_food_safety("banana", "baby"))
