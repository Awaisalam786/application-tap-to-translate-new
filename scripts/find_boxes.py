#!/usr/bin/env python3
"""
Locate words in the scanned screen image by finding green box contours.
"""
from PIL import Image

def find_boxes():
    img = Image.open(r"C:\Users\ABC\.gemini\antigravity\brain\f47c3bb9-e251-4430-b00d-0839624a39ab\android_vivo_scanned_opened.png")
    w, h = img.size

    # In Debug mode, green borders are drawn with stroke
    # Find all connected green horizontal lines
    green_mask = {}
    for y in range(700, 1250):
        for x in range(80, 1050):
            r, g, b, a = img.getpixel((x, y))
            # Green border detection
            if g > 130 and r < 100 and b < 100:
                green_mask[(x, y)] = True

    print(f"Total green pixels detected: {len(green_mask)}")

if __name__ == "__main__":
    find_boxes()
