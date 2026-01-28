# Appendices

This folder contains supporting materials, experimental prototypes, development utilities, and project documentation created during the project lifecycle.

## Contents

### experimental_game_level_hight/
An experimental Flutter prototype exploring sensor-based height estimation for a potential "The Floor Is Lava" game stage. Includes:
- `calculation_height.dart` — Algorithms and utilities for processing accelerometer and orientation sensor data.
- `main.dart` — Standalone demo application for testing height estimation with device motion sensors.

This experiment was not integrated into the final application but demonstrates algorithmic exploration and sensor integration.

### final_presentation/
Presentation materials and recorded demos:
- `project_presentation.pptm` — Complete slide deck covering project requirements, design decisions, architecture, and results.
- `videos/` — Short recorded walkthroughs:
  - `Join_Creation_Game_Video.mp4` — Room creation and joining flow.
  - `Video_Registration_Settings.mp4` — User registration and profile configuration.
  - `Debug_mode_video.mp4` — Development sandbox and game mechanics demonstration.

### helper_scripts/
Python utilities and automation scripts organized into modular components:
- **Main entry**: `main.py` — Primary script orchestrator.
- **Configuration**: `requirements.txt` — Python dependencies and versions.
- **Modules**:
  - `config/` — Configuration management:
    - `languages.py` — Language code mappings and localization configuration.
  - `core/` — Core utilities:
    - `translator.py` — Translation processing and generation.
    - `utils.py` — Helper functions and utilities.
  - `fetchers/` — Data fetching and generation:
    - `base.py` — Base fetcher class and interfaces.
    - `trivia.py` — Trivia question fetching and processing.
    - `ai_generator.py` — AI-powered content generation utilities.
- **Environment**: `.env` — Configuration environment variables.
- **Git ignore**: `.gitignore` — Git ignore patterns for the helper_scripts directory.

### development_process_in_stages.pdf
Comprehensive document detailing the project development phases, milestones, decisions, and outcomes throughout the entire development lifecycle.

## Usage

- **For interviews and presentations**: Review `final_presentation/` for a complete product narrative and run the demo videos.
- **For localization and content**: Reference `helper_scripts/` to understand how language files and game content are generated and to regenerate translations if needed.
- **For experimentation**: `experimental_game_level_hight/` documents sensor exploration; refer to this if you plan sensor-based features.
- **For project overview**: See `development_process_in_stages.pdf` for a detailed chronological account of the development process.
