# Qualityfolio – VS Code Extension

Qualityfolio Extension is a VS Code extension that enables you to execute fenced code blocks directly within Markdown files using the integrated terminal. It provides an interactive web view for visualizing and editing test case documentation, simplifying the management of Evidence Block values and key-value pairs in Markdown.

## Key Features

- Displays a **Run** CodeLens above runnable fenced code blocks in Markdown.
- Supports language detection through:
  - The fenced code block language identifier.
  - Script shebangs.
- Executes multi-line interpreter scripts by writing them to a temporary file before invoking the appropriate interpreter.
- Built with **Deno** and **pnpm**.
- Optional custom labels for CodeLens titles.
- Streamlined workflow for editing Evidence Block values or adding new key-value pairs.
- **Qualityfolio Book Web View**: A custom editor providing an interactive visual representation of Markdown documents with built-in validation, YAML editing, and live code execution.

## Usage

### Run executable fenced code blocks

1. Open a Markdown file in VS Code.
2. Add a fenced code block with a supported language (e.g., `bash`, `python`, `deno`).
3. (Optional) Add a label to customize the CodeLens title:

   ```bash prepare-db
   echo "Setup DB"
   ```

   → CodeLens: **▶ Run prepare-db**

4. If no label is provided, the language name is used:

   ```python
   print("Hello World")
   ```

   → CodeLens: **▶ Run Python**

5. Click the **Run** CodeLens above the block to execute it.

### Updating Evidence Value or Adding a New Key-Value Pair in Test Cases

1. Open the Markdown file in the editor where the test cases are located.
2. Right-click inside the editor and select **Qualityfolio...** from the context menu (or press **Ctrl+Alt+G**).
3. Click **Generate**. A quick-select dropdown will appear with available test cases.
4. Select the test case(s) you wish to update or add a new key-value pair and click **OK**.
5. Choose the **key** that you want to update. This will show the existing values currently available in the file.
6. Select an existing value from the list, or to add a **new value**, click **+ Add new**, type the new value, and press **Enter**.
7. **Review and verify** the changes to ensure the update or new key-value pair is correctly applied.

### Viewing Documents in Qualityfolio Book

1. Right-click on a Markdown file in the Explorer panel.
2. Select **Open in Qualityfolio Book** from the context menu.
3. A new editor tab will open displaying your Markdown document in an interactive web view with:
   - Visual rendering of all content (headings, paragraphs, code blocks).
   - Test cases and evidence blocks with validation status.
   - Real-time validation feedback panel.
   - Interactive editing capabilities for YAML evidence blocks.

## Requirements

- Visual Studio Code
- (Development only) **Deno** and **pnpm**

## Development Setup

1. Install prerequisites:
   - pnpm: `npm install -g pnpm`
   - Deno (v2.5+): Refer to official installation docs

2. Clone the repository and install dependencies:

   ```sh
   git clone <repo-url>
   deno install
   deno task build
   deno task watch
   ```

   > Note: This extension depends on the **spry package**. Install it from the project repository.

3. Launch the extension in debug mode:
   - Open the project in VS Code
   - Press **F5** to start an Extension Development Host
   - Open any Markdown file to test the "Run" CodeLens

## Build & Packaging

1. Bundle and package the extension:

   ```sh
   pnpm vsce package --no-dependencies
   ```

2. Install the packaged extension:

   ```sh
   code --install-extension ./qualityfolio-extension-0.0.1.vsix
   ```

3. Install the extension for Cursor IDE:

   ```sh
   cursor --install-extension ./qualityfolio-extension-0.0.1.vsix
   ```

## Contributing

Contributions are welcome. Please submit issues or pull requests following standard development practices.
