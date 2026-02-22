# Helper Scripts — Localization & Content Generation

## Overview

This directory contains Python utilities for managing game content, automating translations, and generating quiz questions. These scripts support the full localization pipeline for **100+ languages**.

---

## Quick Start

### 1. Install Dependencies

```bash
# Navigate to helper_scripts directory
cd appendices/helper_scripts

# Install Python packages
pip install -r requirements.txt

# Python 3.8+ required
python --version
```

### 2. Configure Environment

```bash
# Copy the environment template
cp .env.example .env

# Edit .env with your API keys (only needed for OpenAI features)
# For basic translation, .env is optional
```

### 3. Run Main Script

```bash
# See available commands
python main.py --help

# Translate a file
python main.py translate path/to/file.json

# Generate questions using AI
python main.py generate-questions --count 10

# Fetch trivia from API
python main.py fetch-trivia --count 20
```

---

## Directory Structure

```
helper_scripts/
├── main.py                  # CLI entry point
├── requirements.txt         # Python dependencies
├── .env                     # Environment configuration (local only)
├── .env.example            # Template for .env (version controlled)
├── .gitignore             # Git ignore patterns
│
├── config/                 # Configuration & Constants
│   ├── __init__.py
│   └── languages.py        # Language mappings and targets
│
├── core/                   # Core Utilities
│   ├── __init__.py
│   ├── translator.py       # Translation engine
│   ├── utils.py            # File I/O and helpers
│   └── __pycache__/        # (auto-generated, ignored)
│
└── fetchers/               # Data Fetchers & Generators
    ├── __init__.py
    ├── base.py             # Base fetcher abstract class
    ├── trivia.py           # Trivia API fetcher
    ├── ai_generator.py     # OpenAI GPT question generator
    └── __pycache__/        # (auto-generated, ignored)
```

---

## Module Reference

### `config/languages.py`

Defines language mappings and target languages for translation.

```python
LANGUAGE_MAP = {
    'english': 'en',
    'spanish': 'es',
    'french': 'fr',
    # ... 100+ languages
}

TARGET_LANGUAGES = ['en', 'es', 'fr', 'de', ...]
```

**Usage:**
```python
from config.languages import LANGUAGE_MAP, TARGET_LANGUAGES
```

### `core/translator.py`

Main translation engine using Google Translate.

**Class: `TranslationEngine`**

```python
from core.translator import TranslationEngine

engine = TranslationEngine()

# Translate text
result = engine.translate("Hello", target_lang="es")
# result: "Hola"

# Translate entire JSON structure
data = {"en": {"title": "Welcome", "description": "..."}}
translated = engine.translate_recursive(data, "es")
```

**Features:**
- Handles strings, lists, and nested dictionaries
- Caches translations (avoids redundant API calls)
- Graceful fallback for unsupported languages

### `core/utils.py`

File I/O and utility functions.

**Functions:**
```python
from core.utils import load_json, save_json, backup_file

# Load JSON
data = load_json("path/to/file.json")

# Save JSON (pretty-printed)
save_json(data, "path/to/file.json")

# Backup before modification
backup_file("path/to/file.json")  # Creates .bak
```

### `fetchers/base.py`

Abstract base class for data fetchers.

```python
from fetchers.base import BaseFetcher

class MyFetcher(BaseFetcher):
    def fetch(self, **kwargs):
        """Implement fetch logic"""
        return [{...}]
```

### `fetchers/trivia.py`

Fetches trivia questions from OpenTDB API (free, no key required).

```python
from fetchers.trivia import TriviaFetcher

fetcher = TriviaFetcher()

# Fetch 10 questions
questions = fetcher.fetch(amount=10, category=9)  # 9 = General Knowledge

# Result format:
# [{
#     "id": 0,
#     "en": {
#         "question": "...",
#         "answers": {...},
#         "correct_answer": "a"
#     }
# }]
```

### `fetchers/ai_generator.py`

Generates questions using OpenAI GPT (requires API key).

```python
from fetchers.ai_generator import IQGenerator

generator = IQGenerator()  # Reads OPENAI_API_KEY from .env

# Generate IQ questions
questions = generator.fetch(amount=5)

# Generates structured question JSON
```

---

## Common Workflows

### Translate Game Content to All Languages

```bash
# Step 1: Prepare English JSON
cat > lv01_questions.json << 'EOF'
[
  {
    "id": 1,
    "en": {
      "question": "What is 2+2?",
      "answers": {"a": "3", "b": "4", "c": "5", "d": "6"},
      "correct_answer": "b"
    }
  }
]
EOF

# Step 2: Translate to all languages
python main.py translate lv01_questions.json

# Result: Each question now has translations for all TARGET_LANGUAGES
```

### Generate AI Questions

```bash
# Generate 10 IQ questions
python main.py generate-questions --count 10 --output lv03_generated.json

# Script generates and translates automatically
```

### Fetch Trivia from API

```bash
# Fetch 50 trivia questions
python main.py fetch-trivia --count 50 --output lv01_trivia.json

# Questions are formatted and ready for game
```

### Update Translations for New Language

```python
# Edit config/languages.py
TARGET_LANGUAGES = ['en', 'es', 'fr', 'de', 'ja', 'new_lang_code']

# Re-run translation
python main.py translate lv01_questions.json
```

---

## Environment Configuration

### .env File (Local Only - Never Committed)

```env
# OpenAI API Key (for AI question generation)
OPENAI_API_KEY=sk-xxxxxxxxxxxxx

# Optional: Other API endpoints
TRIVIA_API_URL=https://opentdb.com/api.php
TRANSLATE_API_TIMEOUT=10
```

**Security Notes:**
- `.env` is in `.gitignore` (never committed to repo)
- `.env.example` shows template (safe to commit)
- Never share API keys or credentials

### Using Environment Variables

```python
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("OPENAI_API_KEY")
```

---

## Command Reference

```bash
# Show all available commands
python main.py --help

# Translate JSON file to all languages
python main.py translate <file_path>
  --output <output_path>  # Optional: specify output file

# Generate questions using AI
python main.py generate-questions
  --count <number>        # How many questions (default: 10)
  --output <file_path>    # Save to file
  --language <lang_code>  # Target language (default: en)

# Fetch questions from trivia API
python main.py fetch-trivia
  --count <number>        # How many questions
  --category <id>         # OpenTDB category (1-32)
  --output <file_path>    # Save to file

# Show supported languages
python main.py list-languages
```

---

## Data Format

All scripts work with JSON files in this format:

```json
[
  {
    "id": 1,
    "en": {
      "question": "Question text",
      "answers": {
        "a": "Option A",
        "b": "Option B",
        "c": "Option C",
        "d": "Option D"
      },
      "correct_answer": "a"
    },
    "es": {
      "question": "Texto de la pregunta",
      "answers": {
        "a": "Opción A",
        "b": "Opción B",
        "c": "Opción C",
        "d": "Opción D"
      },
      "correct_answer": "a"
    }
    // ... more languages
  }
]
```

Or for static text:

```json
{
  "en": {
    "title": "Welcome",
    "subtitle": "Play and Win"
  },
  "es": {
    "title": "Bienvenido",
    "subtitle": "Juega y Gana"
  }
  // ... more languages
}
```

---

## Extending the System

### Create Custom Fetcher

```python
# fetchers/custom_fetcher.py
from fetchers.base import BaseFetcher

class CustomFetcher(BaseFetcher):
    """Fetch questions from custom API"""
    
    def fetch(self, **kwargs):
        # Implement your logic
        return [{"id": 1, "en": {...}}]
```

### Add to Main CLI

```python
# main.py
from fetchers.custom_fetcher import CustomFetcher

# In main():
elif args.command == 'fetch-custom':
    fetcher = CustomFetcher()
    questions = fetcher.fetch(...)
```

### Add New Language

```python
# config/languages.py
TARGET_LANGUAGES = [
    'en', 'es', 'fr', 'de',
    'new_language_code'  # Add here
]

# Re-translate all files
python main.py translate your_file.json
```

---

## Troubleshooting

### "OpenAI API key not found"
- Ensure `.env` file exists
- Check `.env` has `OPENAI_API_KEY=your_key`
- Verify key is valid on OpenAI dashboard

### "Request timed out"
- Check internet connection
- Increase timeout in `.env`: `TRANSLATE_API_TIMEOUT=30`
- Try again (APIs may be temporarily down)

### "Invalid JSON format"
- Verify input JSON is valid: `python -m json.tool file.json`
- Ensure structure matches expected format
- Check for encoding issues (use UTF-8)

### Translation quality issues
- Verify language codes are correct
- Try smaller chunks first (test with 1-2 items)
- Review translation results manually

---

## Performance Tips

1. **Cache Translations** — Script caches results automatically
2. **Batch Operations** — Process multiple files in sequence
3. **API Rate Limits** — Space out requests if hitting limits
4. **Backup Files** — Script creates `.bak` before modifying

---

## Integration with Flutter App

### Where Output Goes

Translated files should be placed in:
```
nexaburst/assets/texts/
├── lv01_questions.json       # Trivia questions
├── lv02_wheel.json           # Wheel data
├── lv03.json                 # Logic questions
├── lv04.json                 # Social prediction
├── static_text.json          # UI text
└── [other_stage].json
```

### Loading in Flutter

```dart
// nexaburst/lib/models/data/service/translation_controllers.dart
final data = await rootBundle.loadString('assets/texts/lv01_questions.json');
final json = jsonDecode(data);
```

---

## Dependencies

```
requests==2.31.0              # HTTP requests
deep-translator==1.11.4       # Google Translate wrapper
openai==1.12.0                # OpenAI API
python-dotenv==1.0.1          # .env file handling
jsonschema==4.21.1            # JSON validation
```

See `requirements.txt` for exact versions.

---

## Security & Best Practices

✅ **Do:**
- Keep `.env` in `.gitignore`
- Use `.env.example` as template
- Rotate API keys regularly
- Validate JSON before processing
- Back up files before bulk operations

❌ **Don't:**
- Commit `.env` with real keys
- Share API keys in issues or PRs
- Use production keys for testing
- Ignore backup files (keep them safe)

---

## Contributing & Improvements

To extend the script system:

1. Create fetcher in `fetchers/`
2. Inherit from `BaseFetcher`
3. Implement `fetch()` method
4. Add command to `main.py`
5. Test with sample data
6. Document changes

---

## Resources

- [OpenTDB API](https://opentdb.com/api_config.php) — Trivia source
- [OpenAI API](https://platform.openai.com/) — GPT integration
- [Google Translate](https://cloud.google.com/translate) — Deep-Translator wrapper
- [Python Docs](https://docs.python.org/3/) — Python reference

---

## Support

For issues or questions:
- Check this README first
- Review `core/` and `fetchers/` source code
- Test with small samples first
- Verify all dependencies are installed

---

*Last Updated: 2026-01-28*
