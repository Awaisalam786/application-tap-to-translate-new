#!/usr/bin/env python3
"""
Generates a legally safe, genuine scanned German PDF fixture.
The PDF contains ONLY a rendered bitmap image (no vector text stream),
simulating a real scanned book/document page with:
- German umlauts: ä, ö, ü, Ä, Ö, Ü
- Eszett: ß
- Punctuation and German quotes: „ ... “
- Multiline text
- Two distinct columns with a wide gutter for negative testing
- Hyphenated German words: Bundes- / regierung
- Normal body text and multiple font sizes (38pt, 24pt, 18pt, 15pt, 11pt)
"""

import os
from PIL import Image, ImageDraw, ImageFont

def generate_scanned_pdf(output_pdf_path: str, output_png_path: str):
    # Standard A4 at 150 DPI: 1240 x 1754 pixels
    width, height = 1240, 1754
    img = Image.new('RGB', (width, height), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)

    font_path = "C:/Windows/Fonts/arial.ttf"
    font_bold_path = "C:/Windows/Fonts/arialbd.ttf"
    font_italic_path = "C:/Windows/Fonts/ariali.ttf"

    title_font = ImageFont.truetype(font_bold_path, 38)
    subtitle_font = ImageFont.truetype(font_path, 22)
    heading_font = ImageFont.truetype(font_bold_path, 20)
    body_font = ImageFont.truetype(font_path, 16)
    quote_font = ImageFont.truetype(font_italic_path, 16)
    small_font = ImageFont.truetype(font_path, 12)

    # 1. Header & Title (Single column banner)
    y = 90
    draw.text((100, y), "Deutsches Lesebuch: Sprache & Wissen", fill=(20, 20, 30), font=title_font)
    y += 55
    draw.text((100, y), "Historische Perspektiven und moderne Entwicklungen in Deutschland", fill=(70, 70, 80), font=subtitle_font)
    y += 40

    # Decorative separator line
    draw.line([(100, y), (width - 100, y)], fill=(180, 185, 195), width=2)
    y += 45

    # 2. Two-Column Layout
    # Column 1: x: 100 to 580 (width: 480)
    # Gutter:   x: 580 to 660 (width: 80 - generous whitespace for gutter negative hit testing)
    # Column 2: x: 660 to 1140 (width: 480)

    col1_x = 100
    col1_w = 480
    col2_x = 660
    col2_w = 480

    start_y = y

    # --- COLUMN 1 ---
    cur_y = start_y
    draw.text((col1_x, cur_y), "1. Die Relevanz der deutschen Sprache", fill=(30, 40, 70), font=heading_font)
    cur_y += 35

    col1_paragraphs = [
        "Die deutsche Sprache zeichnet sich durch einen außergewöhnlichen Reichtum an zusammengesetzten Wörtern und präzisen Ausdrücken aus.",
        "Schon früh entwickelten Schriftsteller wie Johann Wolfgang von Goethe und Friedrich Schiller unvergessliche Werke, welche die europäische Kulturgeschichte nachhaltig prägten.",
        "Besonders bemerkenswert sind die deutschen Umlaute wie in Mädchen, Möglichkeiten, Bücher und Prüfungen, sowie das traditionsreiche Schriftzeichen Eszett (ß), welches in Fußball, Straße, groß und fleißig vorkommt.",
        "Der Philosoph Ludwig Wittgenstein formulierte treffend: „Die Grenzen meiner Sprache bedeuten die Grenzen meiner Welt.“ Dieser Leitsatz betont die fundamentale Bedeutung des sprachlichen Ausdrucks für das menschliche Denken.",
        "Ein sorgfältiges Studium der Grammatik eröffnet tiefe Einblicke in komplexe historische Zusammenhänge."
    ]

    for p in col1_paragraphs:
        words = p.split(' ')
        line = ""
        is_quote = "„" in p
        active_font = quote_font if is_quote else body_font
        for w in words:
            test_line = line + (" " if line else "") + w
            bbox = draw.textbbox((col1_x, cur_y), test_line, font=active_font)
            if (bbox[2] - bbox[0]) > col1_w:
                draw.text((col1_x, cur_y), line, fill=(35, 35, 35), font=active_font)
                cur_y += 26
                line = w
            else:
                line = test_line
        if line:
            draw.text((col1_x, cur_y), line, fill=(35, 35, 35), font=active_font)
            cur_y += 38

    # --- COLUMN 2 ---
    cur_y = start_y
    draw.text((col2_x, cur_y), "2. Wirtschaft, Wissenschaft & Zukunft", fill=(30, 40, 70), font=heading_font)
    cur_y += 35

    col2_paragraphs = [
        "In der modernen Wirtschaft spielen technologische Innovationen eine Schlüsselrolle für nachhaltiges Wachstum und Wohlstand.",
        # Hyphenated word across line boundary: Bundes- / regierung
        "Die Bundes-\nregierung fördert gezielt Forschungsprojekte an Universitäten und Forschungsinstituten in ganz Deutschland.",
        "Deutschland zählt weltweit zu den führenden Nationen im Maschinenbau, in der Informationstechnik und in den Umwelttechnologien.",
        "Studierende am Karlsruher Institut für Technologie (KIT) bearbeiten anspruchsvolle Fragestellungen im Bereich der Künstlichen Intelligenz.",
        "Eine präzise Übersetzung wissenschaftlicher Texte erleichtert den internationalen Austausch und überwindet sprachliche Barrieren.",
        "Durch kontinuierliche Weiterbildung sichern Fachkräfte die Zukunftsfähigkeit unserer Gesellschaft."
    ]

    for p in col2_paragraphs:
        if "\n" in p:
            parts = p.split("\n")
            for part in parts:
                draw.text((col2_x, cur_y), part, fill=(35, 35, 35), font=body_font)
                cur_y += 26
            cur_y += 12
        else:
            words = p.split(' ')
            line = ""
            for w in words:
                test_line = line + (" " if line else "") + w
                bbox = draw.textbbox((col2_x, cur_y), test_line, font=body_font)
                if (bbox[2] - bbox[0]) > col2_w:
                    draw.text((col2_x, cur_y), line, fill=(35, 35, 35), font=body_font)
                    cur_y += 26
                    line = w
                else:
                    line = test_line
            if line:
                draw.text((col2_x, cur_y), line, fill=(35, 35, 35), font=body_font)
                cur_y += 38

    # Footer separator & footnote
    draw.line([(100, 1620), (width - 100, 1620)], fill=(200, 205, 210), width=1)
    draw.text((100, 1635), "Dokument für OCR-Validierung • Phase 8B Hardwaretest • Tap-to-Translate", fill=(120, 120, 120), font=small_font)
    draw.text((width - 150, 1635), "Seite 1 von 1", fill=(120, 120, 120), font=small_font)

    # Save as PNG
    os.makedirs(os.path.dirname(output_png_path), exist_ok=True)
    img.save(output_png_path, "PNG")
    print(f"Saved PNG to {output_png_path}")

    # Save as PDF (image-only scanned PDF)
    os.makedirs(os.path.dirname(output_pdf_path), exist_ok=True)
    img.save(output_pdf_path, "PDF", resolution=150.0)
    print(f"Saved scanned PDF to {output_pdf_path}")

if __name__ == "__main__":
    generate_scanned_pdf(
        output_pdf_path="assets/scanned_german_test.pdf",
        output_png_path="assets/scanned_german_test.png",
    )
