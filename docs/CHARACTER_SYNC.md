# Character Editor ↔ Main Editor Synchronization

## Overview

Screen Dreams now provides **two-way synchronization** between the character editor and the main screenplay editor, with **idempotent parsing** and **character bible export**. This feature ensures that character descriptions and arc notes are never lost and can be edited from either interface.

## Key Features

### 1. Inline Fountain Annotations
Character descriptions and arc notes are stored directly in the screenplay text using valid Fountain boneyard syntax:

```
JOHN
[[DESCRIPTION: Retired detective, world-weary but sharp.]]
[[ARC: Learns to trust again after betrayal.]]
(whispering)
Is anyone here?
```

- **Format**: `[[DESCRIPTION: ...]]` and `[[ARC: ...]]` lines
- **Location**: Immediately after the first occurrence of a character cue
- **Visual**: Purple italic highlighting in the main editor
- **Standard**: Valid Fountain syntax, invisible in PDF export

### 2. Idempotent Parsing
Running Parse multiple times never loses character data:

- **Upsert by name**: Characters are never deleted/reset on re-parse
- **Preserve existing data**: Description and arc_notes never overwritten
- **Read annotations**: Populates empty DB fields from inline annotations
- **Safe**: Existing character data is always preserved

### 3. Automatic Two-Way Sync
Changes flow seamlessly between interfaces:

- **Character card save → screenplay text**: Edits in character editor automatically write annotations to the screenplay
- **Parse → character cards**: Reads annotations into empty database fields
- **No data loss**: Edits survive re-parse, annotations stay in text
- **Transparent**: User sees annotations in editor, PDF stays clean

### 4. Character Bible PDF Export
Generate a professional character documentation PDF:

- **Route**: GET `/api/screenplay/<id>/character-bible-pdf`
- **Filename**: `{screenplay_title}_char_bible.pdf`
- **Content**: Title page + each character with description and arc notes
- **Professional**: Courier font, proper formatting, page numbers

## User Workflow

### Writing Phase
1. Write screenplay in main editor using Fountain format
2. Add character cues (JOHN, MARY, etc.) with dialogue
3. Optionally add inline annotations manually or via character editor

### Character Management
1. Click **Parse** → characters detected and created automatically
2. Go to **Characters** page → edit descriptions and arc notes
3. Click **Save** → annotations automatically written back to screenplay text
4. Re-run **Parse** → character data preserved, annotations read back

### Export Options
- **Screenplay PDF**: Clean screenplay only (annotations stripped)
- **Character Bible PDF**: Character documentation only
- Both documents are industry-standard and professional

## Technical Details

### FountainParser Extensions
- `read_annotations(text, character)` - Read DESCRIPTION/ARC blocks for a character
- `write_annotations(text, character, desc, arc)` - Insert/update annotation lines
- `strip_annotations(text)` - Remove all annotation lines (for PDF export)
- `format_screenplay_content()` - Preserves annotation lines during formatting

### API Endpoints
- `POST /api/screenplay/<id>/parse` - Idempotent character parsing with annotation reading
- `PUT /api/character/<id>` - Update character and sync annotations to screenplay
- `GET /api/screenplay/<id>/pdf` - Export screenplay (annotations stripped)
- `GET /api/screenplay/<id>/character-bible-pdf` - Export character bible

### Editor Features
- Syntax highlighting overlay for annotation lines (purple italic)
- Real-time sync between textarea and highlight layer
- Annotation syntax guide in sidebar
- Visual distinction from screenplay content

## Benefits

### For Writers
- **Never lose character data**: Edits survive re-parsing
- **Edit anywhere**: Update characters in character editor or main editor
- **Professional exports**: Separate screenplay and character documentation
- **Industry standard**: Uses valid Fountain format

### For Development
- **Idempotent operations**: Safe to re-parse anytime
- **Clean separation**: Screenplay text stays clean, annotations handled separately
- **Extensible**: Framework supports additional annotation types
- **Performance**: Efficient parsing and synchronization

## Examples

### Before This Feature
1. Write screenplay with characters
2. Click Parse → characters created (names only)
3. Edit character descriptions in character editor
4. Re-run Parse → all descriptions lost
5. No way to export character documentation

### After This Feature
1. Write screenplay with characters
2. Click Parse → characters created with inline annotations
3. Edit character descriptions in character editor
4. Annotations automatically appear in screenplay text
5. Re-run Parse → character data preserved
6. Export Character Bible PDF for documentation

## File Structure

```
docs/
├── CHARACTER_SYNC.md          # This documentation
└── assets/
    └── images/
        └── character-bible.jpg  # Character Bible export example

app/
├── screenplay.py              # FountainParser with annotation methods
├── routes.py                  # Updated API endpoints
├── pdf_generator.py           # Character Bible PDF generation
└── templates/
    ├── editor.html            # Annotation highlighting overlay
    └── characters.html        # Export Character Bible button
```

## Quality Assurance

### Idempotency Tests
- Multiple parse runs never lose character data
- Annotations survive re-parsing
- Character card edits persist
- No duplicate annotation lines

### Two-Way Sync Tests
- Character card edits appear in screenplay text
- Inline annotations populate character cards
- Both directions work seamlessly
- No data corruption or loss

### PDF Export Tests
- Screenplay PDF contains no annotation lines
- Character Bible PDF contains only character data
- Both use proper Courier formatting
- Professional appearance

### Editor Highlighting Tests
- Annotation lines highlighted in purple italic
- Other screenplay content unchanged
- Real-time sync with typing and scrolling
- No performance impact

## Future Enhancements

### Potential Additions
- AI integration with character annotations
- Additional annotation types (notes, themes, locations)
- Export to other formats (Word, Plain Text)
- Character relationship mapping
- Scene character tracking

### Extensibility
The annotation framework supports easy extension for new annotation types while maintaining backward compatibility with existing Fountain files.

## Migration Guide

### For Existing Projects
1. Open existing screenplay
2. Click Parse to detect characters
3. Edit character descriptions in character editor
4. Annotations will be automatically added to your screenplay text
5. Future parses will preserve all character data

### For New Projects
1. Write screenplay with characters
2. Click Parse to create characters
3. Add descriptions and arc notes in character editor
4. Annotations appear automatically in screenplay text
5. Export Character Bible PDF as needed

## Conclusion

This feature provides a complete solution for character management in Screen Dreams, ensuring that character data is never lost, can be edited from multiple interfaces, and can be exported professionally. The implementation maintains industry standards while providing modern convenience features.
