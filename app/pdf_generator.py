from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from io import BytesIO
import re

class ScreenplayPDFGenerator:
    """Generate professional screenplay PDFs with Courier font"""
    
    # Industry standard measurements (in inches)
    LEFT_MARGIN = 1.5
    RIGHT_MARGIN = 1.0
    TOP_MARGIN = 1.0
    BOTTOM_MARGIN = 1.0
    
    # Element indentations (from left margin)
    SCENE_HEADING_INDENT = 0
    ACTION_INDENT = 0
    CHARACTER_INDENT = 2.0
    DIALOGUE_INDENT = 1.0
    PARENTHETICAL_INDENT = 1.5
    TRANSITION_INDENT = 4.0
    
    # Element widths (industry standard)
    DIALOGUE_WIDTH = 4.0  # ~35-40 characters with Courier 12pt
    PARENTHETICAL_WIDTH = 3.0
    
    def __init__(self):
        self.page_width, self.page_height = letter
        
    def create_pdf(self, screenplay_data: dict, output_path: str = None) -> BytesIO:
        """Create a PDF from screenplay data"""
        buffer = BytesIO()
        
        # Create document
        doc = SimpleDocTemplate(
            buffer if not output_path else output_path,
            pagesize=letter,
            leftMargin=self.LEFT_MARGIN * inch,
            rightMargin=self.RIGHT_MARGIN * inch,
            topMargin=self.TOP_MARGIN * inch,
            bottomMargin=self.BOTTOM_MARGIN * inch
        )
        
        # Build story
        story = []
        
        # Title page
        if screenplay_data.get('title'):
            story.extend(self._create_title_page(screenplay_data))
            story.append(PageBreak())
        
        # Screenplay content
        story.extend(self._create_screenplay_content(screenplay_data.get('content', '')))
        
        # Build PDF
        doc.build(story, onFirstPage=self._add_page_number, onLaterPages=self._add_page_number)
        
        if not output_path:
            buffer.seek(0)
            return buffer
        
        return None
    
    def _create_title_page(self, screenplay_data: dict) -> list:
        """Create title page elements"""
        story = []
        
        # Create styles
        title_style = ParagraphStyle(
            'Title',
            fontName='Courier',
            fontSize=12,
            alignment=TA_CENTER,
            spaceAfter=12
        )
        
        author_style = ParagraphStyle(
            'Author',
            fontName='Courier',
            fontSize=12,
            alignment=TA_CENTER,
            spaceAfter=6
        )
        
        # Add spacing to center vertically
        story.append(Spacer(1, 3 * inch))
        
        # Title
        title = screenplay_data.get('title', 'Untitled')
        story.append(Paragraph(f'<b>{title.upper()}</b>', title_style))
        story.append(Spacer(1, 0.5 * inch))
        
        # Author
        author = screenplay_data.get('author', '')
        if author:
            story.append(Paragraph(f'by', author_style))
            story.append(Paragraph(author, author_style))
        
        return story
    
    def _create_screenplay_content(self, content: str) -> list:
        """Create screenplay content elements"""
        from app.screenplay import FountainParser
        
        parser = FountainParser()
        elements = parser.parse(content)
        
        story = []
        
        for element in elements:
            elem_type = element['type']
            elem_content = element['content']
            
            if elem_type == 'scene_heading':
                story.append(self._create_scene_heading(elem_content))
                story.append(Spacer(1, 12))
                
            elif elem_type == 'action':
                story.append(self._create_action(elem_content))
                story.append(Spacer(1, 12))
                
            elif elem_type == 'character':
                story.append(self._create_character(elem_content))
                story.append(Spacer(1, 6))
                
            elif elem_type == 'parenthetical':
                story.append(self._create_parenthetical(elem_content))
                story.append(Spacer(1, 6))
                
            elif elem_type == 'dialogue':
                story.append(self._create_dialogue(elem_content))
                story.append(Spacer(1, 12))
                
            elif elem_type == 'transition':
                story.append(self._create_transition(elem_content))
                story.append(Spacer(1, 12))
        
        return story
    
    def _create_scene_heading(self, text: str) -> Paragraph:
        """Create scene heading paragraph"""
        style = ParagraphStyle(
            'SceneHeading',
            fontName='Courier-Bold',
            fontSize=12,
            alignment=TA_LEFT,
            leftIndent=self.SCENE_HEADING_INDENT * inch
        )
        return Paragraph(text.upper(), style)
    
    def _create_action(self, text: str) -> Paragraph:
        """Create action paragraph"""
        style = ParagraphStyle(
            'Action',
            fontName='Courier',
            fontSize=12,
            alignment=TA_LEFT,
            leftIndent=self.ACTION_INDENT * inch
        )
        return Paragraph(text, style)
    
    def _create_character(self, text: str) -> Paragraph:
        """Create character name paragraph"""
        style = ParagraphStyle(
            'Character',
            fontName='Courier',
            fontSize=12,
            alignment=TA_LEFT,
            leftIndent=self.CHARACTER_INDENT * inch
        )
        return Paragraph(text.upper(), style)
    
    def _create_parenthetical(self, text: str) -> Paragraph:
        """Create parenthetical paragraph"""
        style = ParagraphStyle(
            'Parenthetical',
            fontName='Courier',
            fontSize=12,
            alignment=TA_LEFT,
            leftIndent=self.PARENTHETICAL_INDENT * inch,
            rightIndent=(6.5 - self.PARENTHETICAL_INDENT - self.PARENTHETICAL_WIDTH) * inch
        )
        return Paragraph(text, style)
    
    def _create_dialogue(self, text: str) -> Paragraph:
        """Create dialogue paragraph"""
        style = ParagraphStyle(
            'Dialogue',
            fontName='Courier',
            fontSize=12,
            alignment=TA_LEFT,
            leftIndent=self.DIALOGUE_INDENT * inch,
            rightIndent=(6.5 - self.DIALOGUE_INDENT - self.DIALOGUE_WIDTH) * inch
        )
        return Paragraph(text, style)
    
    def _create_transition(self, text: str) -> Paragraph:
        """Create transition paragraph"""
        style = ParagraphStyle(
            'Transition',
            fontName='Courier',
            fontSize=12,
            alignment=TA_RIGHT
        )
        return Paragraph(text.upper(), style)
    
    def _add_page_number(self, canvas, doc):
        """Add page number to each page"""
        page_num = canvas.getPageNumber()
        if page_num > 1:  # Don't number title page
            text = f"{page_num - 1}."
            canvas.setFont('Courier', 12)
            canvas.drawRightString(
                self.page_width - self.RIGHT_MARGIN * inch,
                self.page_height - 0.5 * inch,
                text
            )
