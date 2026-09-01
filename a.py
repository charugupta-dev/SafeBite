import os
from pathlib import Path

from dotenv import load_dotenv
from openai import OpenAI

load_dotenv(dotenv_path=Path(__file__).resolve().parent / ".env")

api_key = os.getenv("GROQ_API_KEY")
if not api_key:
    raise ValueError("GROQ_API_KEY is missing. Add it to the .env file.")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.groq.com/openai/v1",
)

response = client.chat.completions.create(
    model="groq/compound-mini",
    messages=[
        {"role": "system", "content": "You are a witty travel guide."},
        {"role": "user", "content": "Suggest one thing to do in Bangalore."},
    ],
    max_tokens=200,
)

print(response.choices[0].message.content)