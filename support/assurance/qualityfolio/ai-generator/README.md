# Text to Markdown Converter - SQLPage Application

A simple web application built with SQLPage that allows you to enter text and convert it to downloadable markdown files.

## Features

- ✍️ **Text Entry Form**: Enter title and content through a user-friendly web interface
- 💾 **Database Storage**: All entries are saved in a SQLite database
- 📋 **Entry Management**: View all saved entries in a searchable, sortable table
- ⬇️ **Markdown Export**: Download any entry as a properly formatted `.md` file
- 🎨 **Markdown Support**: Use markdown syntax in your content (bold, italic, headings, etc.)

## Prerequisites

You need to have SQLPage installed. Download it from:
- **Official releases**: https://github.com/lovasoa/SQLpage/releases
- **Or use Docker**: `docker pull lovasoa/sqlpage`

## Installation

1. **Download SQLPage** (if not already installed):
   - Go to https://github.com/lovasoa/SQLpage/releases
   - Download the appropriate version for Windows
   - Extract `sqlpage.exe` to this project directory or add it to your PATH

2. **Navigate to the project directory**:
   ```powershell
   cd "d:\MyFolder Ajesh\MyProjects\QualitiFolio_MD_SqlPage\QF_SQLPAGE"
   ```

## Running the Application

1. **Start the SQLPage server**:
   ```powershell
   sqlpage
   ```
   
   Or if sqlpage.exe is in the project directory:
   ```powershell
   .\sqlpage.exe
   ```

2. **Open your browser** and navigate to:
   ```
   http://localhost:8080
   ```

3. The database will be created automatically on first run.

## Usage

### Creating a New Entry

1. On the home page, enter a **Title** for your entry
2. Enter your **Content** in the text area (you can use markdown syntax)
3. Click **Save Entry**
4. You'll see a success message confirming the entry was saved

### Viewing Saved Entries

1. Click **View Saved Entries** from the home page
2. You'll see a table with all your entries showing:
   - ID
   - Title
   - Preview (first 100 characters)
   - Creation date/time
   - Download link

### Downloading as Markdown

1. In the entries list, click the **Download** link for any entry
2. A `.md` file will be downloaded with:
   - Title as H1 heading
   - Creation timestamp
   - Full content

## Project Structure

```
QF_SQLPAGE/
├── sqlpage/
│   ├── migrations/
│   │   └── 001_create_text_entries.sql    # Database schema
│   └── sqlpage.json                        # Configuration
├── index.sql                               # Main page with entry form
├── save_entry.sql                          # Form submission handler
├── entries.sql                             # List all entries
├── download.sql                            # Generate markdown download
└── README.md                               # This file
```

## Database Schema

The application uses a single table `text_entries`:

| Column     | Type     | Description                    |
|------------|----------|--------------------------------|
| id         | INTEGER  | Primary key (auto-increment)   |
| title      | TEXT     | Entry title                    |
| content    | TEXT     | Entry content                  |
| created_at | DATETIME | Timestamp (auto-generated)     |

## Markdown Format

Downloaded files follow this format:

```markdown
# [Entry Title]

---

**Created:** [Timestamp]

---

[Entry Content]
```

## Troubleshooting

**Server won't start:**
- Make sure port 8080 is not already in use
- Check that sqlpage.exe has execution permissions

**Database errors:**
- The database file `sqlpage.db` will be created automatically
- If you see migration errors, delete `sqlpage.db` and restart

**Download not working:**
- Make sure your browser allows downloads
- Check that the entry ID exists in the database

## Technologies Used

- **SQLPage**: Web framework using SQL files
- **SQLite**: Embedded database
- **Markdown**: Text formatting syntax

## License

This project is open source and available for personal and commercial use.
