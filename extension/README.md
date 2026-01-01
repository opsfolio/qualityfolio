# Run Spry – VS Code Extension

**Run Spry** is a lightweight Visual Studio Code extension that enables you to execute fenced code blocks directly within Markdown files using the integrated terminal. It also simplifies editing Evidence Block values or adding new key-value pairs, enhancing your workflow within Markdown documentation.

## Key Features

* Adds a **Run** CodeLens above runnable fenced code blocks in Markdown files.
* Supports automatic language detection through:
  * The fenced code block language identifier (e.g., `python`, `bash`).
  * Script shebangs.
* Executes multi-line interpreter scripts by writing them to a temporary file before invoking the appropriate interpreter.
* Built with **Deno** and **pnpm**.
* Allows optional custom labels for CodeLens titles.
* Facilitates editing Evidence Block values or adding new key-value pairs within Markdown files through a streamlined workflow:

## Installation

To install **Run Spry**, you can download and install the pre-packaged extension for **Visual Studio Code** or **Cursor IDE** from the links below:

### For Visual Studio Code:

1. Download the **Run Spry** extension package:

   * [Run Spry Extension for VS Code](./run-spry-markdown-0.0.1.vsix)
2. Install the extension:

   * Open **Visual Studio Code**.
   * Go to the Extensions view (press `Ctrl+Shift+X` or `Cmd+Shift+X`).
   * Click on the ellipsis (`...`) in the top-right corner and select **Install from VSIX...**.
   * Browse and select the `.vsix` file you downloaded.
   * Complete the Installation process.

### For Cursor IDE:

1. Download the **Run Spry** extension package:

   * [Run Spry Extension for Cursor IDE](./run-spry-markdown-0.0.1.vsix)
2. Install the extension:

   * Open **Cursor IDE**.
   * Go to the Extensions menu and select **Install Extension**.
   * Browse and select the `.vsix` file you downloaded.
   * Complete the Installation process.
  
   Install the extension in VS Code:
   * Open **Visual Studio Code**.
   * Install it with `code --install-extension ./run-spry-markdown-0.0.1.vsix`

### Updating Evidence Value or Adding a New Key-Value Pair in Test Cases

1. **Open the Markdown file** in the editor where the test cases are located.
2. **Right-click** anywhere inside the editor to open the context menu.
3. From the context menu, select **Spry...**.
4. Click on **Generate**. A quick-select dropdown will appear with available test cases.
5. Select the **test case(s)** you wish to update or add a new key-value pair and click the **Ok** button.
6. Choose the **key** that you want to update. This will show the existing values currently available in the file.
7. Select an existing value from the list, or to add a **new value**, click **+ Add new**, type the new value, and press **Enter**.
8. **Review and verify** the changes to ensure the update or new key-value pair is correctly applied.

## Requirements

* **Visual Studio Code** or **Cursor IDE**.
* **Run Spry** extension file (`.vsix`).

> **Note:** This extension is built with **Deno** and **pnpm** for development, but these tools are not required for normal usage.

## Contributing

Contributions are welcome. Please submit issues or pull requests following standard development practices.

## License

To be added.

## Release Notes

* **1.0.0** – Initial release.
