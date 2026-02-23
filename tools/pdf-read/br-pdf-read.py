#!/usr/bin/env python3
"""
BR PDF-READ — extract PDF pages as viewable images
Usage: python3 br-pdf-read.py <pdf_file> <page_number>
       python3 br-pdf-read.py file.pdf 1
Outputs: ~/.blackroad/pdf_ocr_tmp/page_NNN.jpg
"""
import sys, os, subprocess, glob
from PIL import Image

WORK = os.path.expanduser("~/.blackroad/pdf_ocr_tmp")
os.makedirs(WORK, exist_ok=True)

def extract_page(pdf_path, page_num):
    prefix = os.path.join(WORK, f"_raw_{page_num:03d}")
    out    = os.path.join(WORK, f"page_{page_num:03d}.jpg")

    subprocess.run([
        "pdfimages", "-j",
        "-f", str(page_num), "-l", str(page_num),
        pdf_path, prefix
    ], check=True, capture_output=True)

    extracted = sorted(glob.glob(f"{prefix}*.ppm") + glob.glob(f"{prefix}*.jpg"))
    if not extracted:
        print(f"No image found for page {page_num}")
        sys.exit(1)

    img = Image.open(extracted[0])
    img.save(out, quality=90)
    for f in extracted:
        os.remove(f)
    return out

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    pdf, page = sys.argv[1], int(sys.argv[2])
    path = extract_page(pdf, page)
    print(path)
