# Screen Dreams Screenwriter - Usage Guide

## Getting Started

### 1. Start the Application

```bash
python3 run.py
```

The application will be available at http://localhost:5000

### 2. Login

The Screen Dreams Screenwriter requires authentication to protect your screenplays. You can:

- **Use the demo account**: Username `demo`, Password `demo123`
- **Create a new account**: Click "Create Account" to register

### 3. Create Your First Screenplay

1. Click "New Screenplay" on the home page
2. Enter a title and author name
3. Click "Create"

### 4. Write Using Fountain Format

The editor uses Fountain format, which is simple and intuitive:

#### Scene Headings
Start with INT. or EXT. followed by location and time:
```
INT. COFFEE SHOP - DAY
EXT. PARK - NIGHT
```

#### Action Lines
Just write regular text:
```
John walks into the room and looks around nervously.
```

#### Character Names
Write the character name in ALL CAPS on its own line:
```
JOHN
```

#### Dialogue
Write dialogue after the character name:
```
JOHN
I can't believe this is happening.
```

#### Parentheticals
Add character direction in parentheses:
```
JOHN
(whispering)
We need to leave now.
```

#### Transitions
Write transitions in ALL CAPS:
```
FADE OUT.
CUT TO:
DISSOLVE TO:
```

### 4. Auto-Save

The editor automatically saves your work every 3 seconds. You'll see the save status in the bottom right corner.

### 5. Export to PDF

Click the "Export PDF" button to generate a professional screenplay PDF with:
- Courier 12pt font (industry standard)
- Proper margins (1.5" left, 1" right, 1" top/bottom)
- Page numbers
- Industry-standard formatting

### 6. Manage Characters

1. Click "Characters" to view all characters
2. Click "Parse" first to extract characters from your screenplay
3. Add descriptions and character arc notes
4. Use "AI Suggestion" to get character development ideas (requires Ollama)

### 7. Organize Scenes

1. Click "Scenes" to view all scenes
2. Click "Parse Scenes" to extract scenes from your screenplay
3. View scene headings, locations, and time of day
4. See scene content previews

### 8. AI Assistant (Optional)

If you have Ollama installed and running:

1. Install Ollama from https://ollama.ai
2. Run: `ollama pull llama2`
3. The AI status indicator will show "🤖 AI Ready"
4. Use AI features:
   - Character arc suggestions
   - Plot development ideas
   - Dialogue enhancement

## Keyboard Shortcuts

While writing in the editor:
- **Ctrl+S** - Manual save
- **Tab** - Indent (for dialogue)

## Tips for Better Screenplays

### Scene Headings
- Always start with INT. or EXT.
- Be specific with locations
- Use standard times: DAY, NIGHT, DAWN, DUSK, MORNING, AFTERNOON, EVENING

### Character Names
- Use ALL CAPS for character names
- Be consistent with character names throughout
- Add (V.O.) for voice-over: `JOHN (V.O.)`
- Add (O.S.) for off-screen: `MARY (O.S.)`

### Dialogue
- Keep it natural and concise
- Use parentheticals sparingly
- Show character personality through speech patterns

### Action Lines
- Write in present tense
- Be visual and specific
- Keep paragraphs short (3-4 lines max)

### Page Count
- The editor shows approximate page count
- Industry standard: ~1 page = 1 minute of screen time
- Feature films: 90-120 pages
- TV episodes: 30-60 pages

## Example Screenplay Structure

```
INT. COFFEE SHOP - DAY

Sarah enters nervously, looking around.

SARAH
(to herself)
Where is he?

The BARISTA calls out.

BARISTA
Next in line!

Sarah approaches the counter.

SARAH
Black coffee, please.

She takes her coffee and sits down.

A MAN IN A HAT enters and walks to her table.

MAN IN HAT
You have something that belongs to me.

SARAH
(defensive)
I don't know what you're talking about.

FADE OUT.
```

## Troubleshooting

### Characters Not Showing Up
- Make sure character names are in ALL CAPS
- Click "Parse" in the Characters section
- Character names must be on their own line

### Scenes Not Parsing
- Ensure scene headings start with INT. or EXT.
- Include a dash and time of day: `INT. LOCATION - DAY`
- Click "Parse Scenes" to refresh

### PDF Not Formatting Correctly
- Check that your Fountain syntax is correct
- Scene headings must start with INT./EXT.
- Character names must be ALL CAPS

### AI Not Working
- Ensure Ollama is installed and running
- Check that the model is downloaded: `ollama pull llama2`
- Verify Ollama is running on port 11434

## Advanced Features

### Import Existing Screenplays
Currently supports:
- Fountain format (.fountain files)
- Plain text files

### Export Options
- PDF with Courier font (primary)
- Fountain format (for sharing/backup)

### Database
All screenplays are stored in a SQLite database (`screen_dreams.db`) in the project directory.

## Best Practices

1. **Save Often**: Although auto-save is enabled, manually save important changes
2. **Parse Regularly**: Parse scenes and characters after major edits
3. **Use Consistent Formatting**: Stick to Fountain conventions
4. **Backup Your Work**: Export PDFs and Fountain files regularly
5. **Character Development**: Use the character management features to track arcs
6. **Scene Organization**: Review the scenes view to check pacing and structure

## Support

For issues or questions:
- Check the README.md file
- Review Fountain format documentation at fountain.io
- Ensure all dependencies are installed correctly
