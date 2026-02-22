# 📂 NexaBurst Appendices: Behind the Scenes

Welcome to the appendices for NexaBurst! This directory is more than just an archive; it's a behind-the-scenes look at the engineering, experimentation, and automation that support the main application.

Here you'll find artifacts that showcase the full development lifecycle, from early-stage prototypes to the powerful tools that make a global-scale app possible. These materials are intended for educational purposes and to provide deeper insight into our development process.

---

## Contents

This directory is organized into two main parts:

1.  **🧪 Experimental Prototype** — A deep dive into a sensor-based game mechanic that was prototyped but not included in the final app.
2.  **🛠️ Automation Pipeline** — The Python scripts that power the game's localization and content generation for over 100 languages.

---

## 🧪 Experimental Prototype: Sensor-Based Gameplay

This folder contains a standalone Flutter experiment exploring a "The Floor is Lava" game mechanic using device motion sensors.

-   **Concept**: Players would physically jump or raise their device to avoid virtual lava, with height changes detected by the accelerometer.
-   **What it Demonstrates**:
    -   Real-time signal processing in Flutter.
    -   The challenges of sensor fusion (accelerometer, gyroscope).
    -   Turning a physical concept into a software algorithm, including handling noise, drift, and calibration.
-   **Why It's Here**: This prototype was a valuable exploration into the limits of mobile sensors for gameplay. While ultimately excluded from the final app due to accuracy limitations and device hardware variance, it serves as an excellent educational case study on R&D, prototyping, and making pragmatic product decisions.

> **➡️ Dive into the code and technical write-up in the `experimental_game_level_hight` README.**

---

## 🛠️ Automation Pipeline: Localization & Content Engine

This folder contains a powerful set of Python scripts designed to automate content management and scale the game for a global audience.

-   **Purpose**: To programmatically manage all translatable text and generate dynamic game content, removing the need for manual data entry.
-   **Key Features**:
    -   **Automated Translation**: Translates all game content (UI text, trivia questions) into **100+ languages** using third-party APIs.
    -   **AI-Powered Content Generation**: Uses OpenAI's GPT to create unique logic puzzles and other game questions.
    -   **API Integration**: Fetches fresh trivia questions from external sources like the OpenTDB API.
-   **Impact**: This pipeline is the backbone of NexaBurst's internationalization (i18n) strategy. It demonstrates how to efficiently build and maintain a multilingual application with minimal manual effort, ensuring the game is accessible worldwide.

> **➡️ Explore the scripts and see the setup guide in the `helper_scripts` README.**

---

## 🚀 How to Explore

-   **For Flutter Developers**: Check out the `experimental_game_level_hight` directory to see a practical (and challenging) example of using device sensors for gameplay.
-   **For Backend & DevOps Engineers**: The `helper_scripts` provide a great example of a content automation pipeline that could be adapted for CI/CD workflows to manage application content.

We hope these materials provide valuable insights into our engineering practices.

---
