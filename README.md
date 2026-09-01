# AI Engineering Learning

A collection of AI and LLM experiments, tools, and mini-applications.

## Projects & Scripts

- **`app.py`**: Gradio web application for the AI Website Summarizer.
- **`summariser.py`**: Summarizes webpage content using OpenAI or Groq API.
- **`scraper.py`**: Clean web scraper using `requests` and `BeautifulSoup4` with headers.
- **`a.py`**: Sample script interacting with Groq LLM.

## Setup & Installation

1. **Clone the repository:**
   ```bash
   git clone <repo-url>
   cd AIEngineeringLearning
   ```

2. **Create and activate a virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment variables:**
   Copy the template and fill in your API key:
   ```bash
   cp .env.example .env
   ```
   Add either `GROQ_API_KEY` or `OPENAI_API_KEY` to `.env`.

5. **Run the Gradio App:**
   ```bash
   python app.py
   ```
