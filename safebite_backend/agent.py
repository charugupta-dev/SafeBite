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

PRICES = {"shoes": 799, "hat": 399, "bag": 1420, "shorts": 1299, "pants": 1699}

def get_price(item):
    print(f"🔧 tool called: get_price({item})")     # so you SEE it happen
    return f"₹{PRICES.get(item.lower(), 'unknown')}"

tools = [{
    "type": "function",                                      # A function. (That's the only kind you'll use for a long time — just write this line as-is.)
    "function": {
        "name": "get_price",                                 # function name, which is how the model will call it.
        "description": "Get the price of a shop item the user asks about.",  # description of what the function does, which is how the model will know when to call it.
        "parameters": {                                       # the parameters the function takes, which is how the model will know what to pass to it.
            "type": "object",
            "properties": {"item": {"type": "string", "description": "the item name"}},
            "required": ["item"],
        },
    },
}]


def agent(user_message, return_metadata=False):
    messages = [{"role": "user", "content": user_message}]
    tools_used = []

    response = client.chat.completions.create(          # ① send message + tools menu
        model=model_name, messages=messages, tools=tools)
    msg = response.choices[0].message

    if msg.tool_calls:                                  # ② did it ask for a tool?
        messages.append(msg)
        for call in msg.tool_calls:
            args = json.loads(call.function.arguments)  # ③ read its request, run it
            item = args.get("item", "")
            tools_used.append(f"get_price({item})")
            result = get_price(item)
            messages.append({"role": "tool", "tool_call_id": call.id, "content": result})
        response = client.chat.completions.create(      # ④ send tool result back
            model=model_name, messages=messages)
        msg = response.choices[0].message

    if return_metadata:
        return {"content": msg.content or "", "tools_used": tools_used}
    return msg.content

if __name__ == "__main__":
    print(agent("How much is the bag?"))        # → tool fires → "₹799"
    print(agent("Hi! What can you help with?")) # → no tool → just chats