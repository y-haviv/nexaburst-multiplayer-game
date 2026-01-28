# Contributing to NexaBurst

Thank you for your interest in NexaBurst!

## About This Repository

NexaBurst is a **portfolio project** showcasing full-stack game development, cross-platform engineering (Flutter), backend integration (Firebase), and localization workflows. While this is primarily a personal project for demonstration purposes, we welcome feedback, discussions, and interest in the codebase.

## Ways to Engage

### 📧 Code Reviews & Feedback
If you're reviewing this code for hiring decisions, technical interviews, or learning purposes, please feel free to:
- Submit issues with constructive feedback or questions
- Point out architectural improvements or best practices
- Suggest optimization opportunities

### 🐛 Bug Reports
If you discover a bug or issue, please:
1. Check existing issues to avoid duplicates
2. Create a detailed issue with:
   - Steps to reproduce
   - Expected vs. actual behavior
   - Your environment (Flutter version, OS, device)
   - Screenshots if applicable

### 💡 Feature Ideas
While this is a completed portfolio piece, feature suggestions are welcome for educational discussion. Please note that acceptance is not guaranteed for modifications.

## Development Setup

### Prerequisites
- Flutter SDK (3.8.1+)
- Dart (included with Flutter)
- Android Studio or VS Code with Flutter extensions
- For Python scripts: Python 3.8+

### Local Development

```bash
# Clone the repository
git clone https://github.com/y-haviv/nexaburst-multiplayer-game.git
cd nexaburst-multiplayer-game

# Install Flutter dependencies
cd nexaburst
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Analyze code for issues
flutter analyze
```

### Working with Helper Scripts

```bash
# Install Python dependencies
cd appendices/helper_scripts
pip install -r requirements.txt

# Copy .env template
cp .env.example .env

# Edit .env with your credentials (if testing translations/AI features)
# Then run scripts
python main.py --help
```

## Code Standards

### Dart/Flutter
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` before committing
- Format code with `flutter format`
- Prefer meaningful variable names and comprehensive comments
- MVVM architecture should be respected for new features

### Python
- Follow [PEP 8](https://pep8.org/) style guide
- Use type hints for functions
- Include docstrings for modules and classes
- Run code through `pylint` or `flake8` if modifying

### Documentation
- Update READMEs when changing functionality
- Add inline comments for complex logic
- Document public APIs clearly

## Commit Guidelines

While this is a portfolio project, clear commit history is valuable:

```
format: Brief, imperative description (max 72 chars)

- Bullet points for multiple changes
- Reference issue numbers if applicable (#123)
```

Examples:
```
Improve game stage performance by optimizing animations
Refactor authentication flow for clearer state management
Add support for 15 new languages in localization pipeline
```

## Testing Before Submission

If you're making changes:
1. **Dart/Flutter**: `flutter test` passes
2. **Analysis**: `flutter analyze` shows no errors
3. **Formatting**: Code follows conventions
4. **Documentation**: READMEs are updated if needed

## Reporting Security Issues

⚠️ **Do NOT open public issues for security vulnerabilities.**

Please report security concerns privately:
- **GitHub Security Advisory**: Use this repository's "Report a vulnerability" feature if available
- **GitHub Profile**: Contact through the associated GitHub profile
- **Reference**: Include "Security Report - NexaBurst" in any communication

See [SECURITY.md](SECURITY.md) for more details.

## Questions?

- Review [README.md](README.md) for general project info
- Check [nexaburst/README.md](nexaburst/README.md) for architecture details
- See [appendices/helper_scripts/README.md](appendices/helper_scripts/README.md) for script documentation

## Licensing

By submitting feedback, issues, or code suggestions, you acknowledge that:
- The project is licensed under the Proprietary License (see [LICENSE](LICENSE))
- Contributions remain within the portfolio context
- Respectful, constructive discourse is expected

Thank you for being part of this project's journey! 🚀
