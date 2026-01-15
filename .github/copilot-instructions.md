# Copilot Instructions for Rime Mate

## Project Overview

Rime Mate (Rime 配置助手) is a visual configuration assistant for the Rime input method on macOS, Linux, and Windows. It simplifies complex Rime configuration files through an intuitive terminal-based UI, making it accessible for non-programmer users.

**Key Features:**
- Visual configuration interface using Bubble Tea TUI framework
- One-click installation of dictionaries and language models
- Cross-platform support (macOS, Linux, Windows)
- Automatic handling of configuration paths and dependencies

## Project Structure

```
.
├── .github/
│   └── workflows/          # GitHub Actions CI/CD workflows
├── module/                 # Core functionality modules
│   ├── config.go           # Configuration management
│   ├── ohMyRime/           # Oh-my-rime integration (mint input method)
│   │   ├── lang_model.go   # Language model installation/removal
│   │   ├── module.go       # Module configuration
│   │   └── resources.go    # Resource URLs and constants
│   └── rimeIce/            # Rime Ice integration (coming soon)
├── util/                   # Utility functions
│   ├── download.go         # File download with fallback URLs
│   ├── log.go              # Logging utilities
│   ├── transform_path.go   # Cross-platform path handling
│   └── yaml_reader.go      # YAML configuration parsing
├── main.go                 # Application entry point
├── build_cli.go            # TUI implementation with Bubble Tea
├── build.sh                # Cross-platform build script
├── setup.sh                # Unix installation script
└── setup.ps1               # Windows installation script
```

## Build and Development Commands

### Building the Project

```bash
# Vendor dependencies first
go mod vendor

# Build for all platforms
./build.sh

# Or build manually for specific platform
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -mod=vendor -o output/rime-mate-linux-amd64 .
```

### Running the Application

```bash
# Run directly
go run .

# Or build and run
go build -o rime-mate . && ./rime-mate
```

### Testing

```bash
# Run tests (if available)
go test ./...

# Run tests with coverage
go test -cover ./...
```

### Code Quality

```bash
# Format code
go fmt ./...

# Lint code (if golangci-lint is installed)
golangci-lint run
```

## Coding Standards and Conventions

### General Guidelines

1. **Language**: Go 1.25.5
2. **Chinese Comments**: Use Chinese comments for user-facing functionality and UI strings
3. **English Comments**: Use English for technical implementation details and code documentation
4. **Error Handling**: Always handle errors explicitly; never ignore them

### Code Style

- Follow standard Go conventions (use `gofmt`)
- Use descriptive variable names in English
- Keep functions focused and single-purpose
- Prefer explicit error handling over panic

### UI/UX Conventions

- Use emoji icons for visual feedback (✅ ✗ 🚀 ❌)
- All user-facing text should be in Chinese
- Menu navigation: `↑`/`↓` or `j`/`k` for selection, `Enter` to confirm, `q` to quit
- Use Lipgloss styles consistently:
  - `titleStyle`: Green (#04B575), bold, for titles
  - `selectedStyle`: Pink (#FF7AB2), bold, for selected items
  - `disabledStyle`: Gray (#626262) for disabled items
  - `helpStyle`: Gray (#626262) for help text

### Module Organization

- Each input method (mint, rime-ice) should have its own module package
- Each module should implement standard interfaces from `module/config.go`
- Utilities should be in the `util/` package and be reusable

### Cross-Platform Considerations

- Always use cross-platform path handling via `util.TransformPath()`
- Detect OS using `runtime.GOOS`
- Test builds for all supported platforms: darwin/amd64, darwin/arm64, linux/amd64, linux/arm64, windows/amd64, windows/arm64
- Use appropriate file extensions (.command for macOS, .desktop for Linux, .bat for Windows)

### Download and Resource Management

- Always provide fallback URLs (GitHub + CNB mirror) for downloads
- Use `util.DownloadResource()` for all downloads
- Display progress feedback to users
- Handle network errors gracefully with user-friendly messages

## Git and Release Workflow

### Branch Naming

- Feature branches: `feature/description`
- Bug fixes: `fix/description`
- Copilot branches: `copilot/description`

### Commit Messages

- Use English for commit messages
- Format: `<type>: <description>`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
- Example: `feat: add language model installation for mint input`

### Release Process

1. Tag with version (e.g., `v1.0.0`)
2. GitHub Actions automatically builds for all platforms
3. Creates a draft release with binaries and setup scripts
4. Review and publish the release manually

## Important Boundaries

### DO NOT

- **Never commit secrets or API keys** into the repository
- **Never modify or delete vendor files** - use `go mod vendor` to regenerate
- **Never edit `.git/` directory or git configuration**
- **Never remove working code** unless fixing a bug or security vulnerability
- **Never add unnecessary dependencies** - prefer standard library when possible
- **Never break cross-platform compatibility** - test on all platforms
- **Never modify setup scripts** without testing on target platforms

### DO

- **Always test builds** using `./build.sh` before committing
- **Always handle errors** with user-friendly Chinese messages
- **Always use CGO_ENABLED=0** for cross-platform compatibility
- **Always vendor dependencies** before building releases
- **Always preserve existing functionality** when adding features
- **Always use semantic versioning** for releases

## Dependencies

- **Bubble Tea** (github.com/charmbracelet/bubbletea): Terminal UI framework
- **Lipgloss** (github.com/charmbracelet/lipgloss): Style definitions for TUI
- **go-yaml** (github.com/goccy/go-yaml): YAML parsing for Rime configs

## Testing Strategy

- Test builds on all supported platforms before releases
- Manual testing of TUI navigation and functionality
- Verify download functionality with both primary and fallback URLs
- Test path handling on different operating systems

## Common Tasks

### Adding a New Input Method Module

1. Create new package under `module/`
2. Implement required interfaces from `module/config.go`
3. Add menu entry in `build_cli.go`
4. Implement installation/removal functions
5. Add resource URLs in module's `resources.go`
6. Test on all platforms

### Adding a New Feature to Existing Module

1. Implement functionality in appropriate module file
2. Add menu option in `build_cli.go` if needed
3. Add error handling with Chinese user messages
4. Update README.md if user-facing
5. Test the feature manually

### Updating Dependencies

```bash
# Update specific dependency
go get -u github.com/charmbracelet/bubbletea@latest

# Update go.mod
go mod tidy

# Vendor dependencies
go mod vendor
```

## Additional Notes

- The application is designed for users who are not familiar with programming
- All error messages and UI text should be clear and in Chinese
- Prioritize user experience and simplicity over advanced features
- The setup scripts handle automatic updates by re-running the installation command
