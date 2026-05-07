"""Shared utility helpers for JSON I/O, backups, and placeholder safety."""
import json
import os
import shutil
import logging
import re
from datetime import datetime

logging.basicConfig(
    filename='app.log',
    level=logging.INFO,
    format='%(asctime)s | %(levelname)s | %(message)s'
)
logger = logging.getLogger(__name__)

def backup_file(path: str):
    """Create a timestamped backup copy in the local ``backups`` folder."""
    if os.path.exists(path):
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_dir = 'backups'
        os.makedirs(backup_dir, exist_ok=True)
        filename = os.path.basename(path)
        shutil.copy(path, os.path.join(backup_dir, f"{filename}.{timestamp}.bak"))

def load_json(path: str) -> list | dict:
    """Load a JSON file and return an empty list when loading fails."""
    if not os.path.exists(path):
        return []
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading {path}: {e}")
        return []

def save_json(data: list | dict, path: str):
    """Persist JSON atomically by writing to a temporary file first."""
    temp_path = f"{path}.tmp"
    try:
        with open(temp_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        os.replace(temp_path, path)
    except Exception as e:
        logger.error(f"Error saving {path}: {e}")
        if os.path.exists(temp_path):
            os.remove(temp_path)

def mask_placeholders(text: str) -> tuple[str, list[str]]:
    """Replace ``{placeholder}`` segments so translators do not mutate them."""
    if not isinstance(text, str):
        return str(text), []
    placeholders = re.findall(r"\{[^}]+\}", text)
    masked = re.sub(r"\{[^}]+\}", "__PH__", text)
    return masked, placeholders

def restore_placeholders(text: str, placeholders: list[str]) -> str:
    """Restore masked placeholder markers into translated text in order."""
    for ph in placeholders:
        text = text.replace("__PH__", ph, 1)
    return text