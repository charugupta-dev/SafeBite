import os
from pathlib import Path

from dotenv import load_dotenv
from openai import OpenAI

from python_files.scraper import fetch_website_contents

load_dotenv(dotenv_path=Path(__file__).resolve().parent / ".env")

if os.getenv("GROQ_API_KEY"):
    client = OpenAI(
        api_key=os.getenv("GROQ_API_KEY"),
        base_url="https://api.groq.com/openai/v1",
    )
    model_name = "groq/compound-mini"
elif os.getenv("OPENAI_API_KEY"):
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    model_name = "gpt-4o-mini"
else:
    raise ValueError("No API key found. Add OPENAI_API_KEY or GROQ_API_KEY to your .env file.")

system_prompt = """You analyze the contents of a website and
give a short, friendly summary. Ignore navigation menus.
Respond in markdown."""


def summarize(url):
    website = fetch_website_contents(url)
    response = client.chat.completions.create(
        model=model_name,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": f"Summarize this website:\n\n{website}"},
        ],
    )
    return response.choices[0].message.content