"""
Core functionality package including utilities and the translation engine.
"""
from .utils import load_json, save_json, backup_file, mask_placeholders, restore_placeholders
from .translator import TranslationEngine