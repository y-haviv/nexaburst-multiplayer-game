"""
Main entry point for the Content Engine CLI.
Handles fetching, generating, and bulk translating files.
"""
import argparse
from core.utils import load_json, save_json, backup_file
from core.translator import TranslationEngine
from config.languages import TARGET_LANGUAGES
from fetchers.trivia import TriviaFetcher
from fetchers.ai_generator import IQGenerator

def run_translation_service(file_path: str):
    """
    Detects data structure and processes translations for all target languages.
    """
    data = load_json(file_path)
    if not data:
        print(f"Error: No data in {file_path}")
        return

    engine = TranslationEngine()
    backup_file(file_path)

    # Process list-based files (Questions)
    if isinstance(data, list):
        for i, item in enumerate(data):
            print(f"[{i+1}/{len(data)}] Translating item...")
            if 'en' not in item: continue
            for lang in TARGET_LANGUAGES:
                if lang not in item:
                    item[lang] = engine.translate_recursive(item['en'], lang)
            save_json(data, file_path)

    # Process dict-based files (Static Text)
    elif isinstance(data, dict):
        if 'en' in data:
            for lang in TARGET_LANGUAGES:
                if lang not in data:
                    print(f"Translating static file to {lang}...")
                    data[lang] = engine.translate_recursive(data['en'], lang)
                    save_json(data, file_path)

    print("✅ Process complete.")

def main():
    parser = argparse.ArgumentParser(description="Content Engine Pro")
    subparsers = parser.add_subparsers(dest="command")

    # Fetching
    p_fetch = subparsers.add_parser('fetch')
    p_fetch.add_argument('--source', choices=['trivia', 'ai'], required=True)
    p_fetch.add_argument('--out', required=True)
    p_fetch.add_argument('--amount', type=int, default=10)

    # Translating
    p_trans = subparsers.add_parser('translate')
    p_trans.add_argument('--file', required=True)

    args = parser.parse_args()

    if args.command == 'fetch':
        fetcher = TriviaFetcher() if args.source == 'trivia' else IQGenerator()
        save_json(fetcher.fetch(args.amount), args.out)
    elif args.command == 'translate':
        run_translation_service(args.file)
    else:
        parser.print_help()

if __name__ == '__main__':
    main()