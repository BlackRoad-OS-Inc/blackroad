#!/usr/bin/env python3
"""
BR PDF-READ — macOS Vision framework handwriting OCR for PDFs
Usage: python3 br-pdf-read.py <pdf_file> [page_range]
       python3 br-pdf-read.py file.pdf          # all pages
       python3 br-pdf-read.py file.pdf 1        # page 1 only
       python3 br-pdf-read.py file.pdf 1-4      # pages 1 through 4
       python3 br-pdf-read.py file.pdf ppms     # OCR pre-converted PPMs in /tmp
"""

import sys
import os
import subprocess
import time

# ── Vision framework via pyobjc ────────────────────────────────────────────────
import objc
import Quartz
objc.loadBundle('Vision',
    bundle_path='/System/Library/Frameworks/Vision.framework',
    module_globals=globals())
from Foundation import NSURL

# ── OCR one image file via Vision ──────────────────────────────────────────────
def ocr_image_path(image_path):
    """Run Vision VNRecognizeTextRequest on an image file. Returns text string."""
    url = NSURL.fileURLWithPath_(image_path)

    results = []
    done = [False]

    def handler(request, error):
        if error:
            results.append(f"[vision error: {error}]")
        else:
            for obs in (request.results() or []):
                candidates = obs.topCandidates_(1)
                if candidates and len(candidates) > 0:
                    results.append(str(candidates[0].string()))
        done[0] = True

    request = VNRecognizeTextRequest.alloc().initWithCompletionHandler_(handler)
    request.setRecognitionLevel_(1)           # 1 = accurate
    request.setUsesLanguageCorrection_(True)
    request.setRecognitionLanguages_(["en-US"])

    img_handler = VNImageRequestHandler.alloc().initWithURL_options_(url, {})
    img_handler.performRequests_error_([request], None)

    timeout, start = 30, time.time()
    while not done[0] and (time.time() - start) < timeout:
        time.sleep(0.05)

    return "\n".join(results)

# ── OCR pre-existing PPMs in /tmp ─────────────────────────────────────────────
def ocr_existing_ppms(prefix="/tmp/halting_page"):
    import glob
    files = sorted(glob.glob(f"{prefix}*.ppm"))
    if not files:
        print(f"No PPM files found matching {prefix}*.ppm")
        return
    print(f"Found {len(files)} pages\n{'='*60}", flush=True)
    for i, ppm_path in enumerate(files, 1):
        print(f"\n── PAGE {i} ({os.path.basename(ppm_path)}) ──", flush=True)
        # Convert PPM → PNG via PIL (Vision handles PNG better than raw PPM)
        tmp_png = f"/tmp/br_ocr_page_{i}.png"
        try:
            from PIL import Image
            img = Image.open(ppm_path)
            # Downscale to ~150 DPI equivalent for faster OCR (still very readable)
            w, h = img.size
            img = img.resize((w // 2, h // 2), Image.LANCZOS)
            img.save(tmp_png)
            text = ocr_image_path(tmp_png)
            print(text, flush=True)
        except Exception as e:
            print(f"[ERROR on page {i}: {e}]", flush=True)
        finally:
            if os.path.exists(tmp_png):
                os.remove(tmp_png)

# ── OCR a PDF file page by page ───────────────────────────────────────────────
def ocr_pdf(pdf_path, start_page=1, end_page=None):
    # Get page count
    result = subprocess.run(
        ["pdfinfo", pdf_path], capture_output=True, text=True)
    total_pages = 1
    for line in result.stdout.splitlines():
        if line.startswith("Pages:"):
            total_pages = int(line.split(":")[1].strip())
            break

    if end_page is None:
        end_page = total_pages

    print(f"PDF: {os.path.basename(pdf_path)}")
    print(f"Pages: {total_pages} total, reading {start_page}–{end_page}")
    print("=" * 60, flush=True)

    for page in range(start_page, end_page + 1):
        print(f"\n── PAGE {page}/{total_pages} ──", flush=True)
        tmp_png = f"/tmp/br_ocr_page_{page}.png"
        tmp_ppm_base = f"/tmp/br_ocr_p"
        try:
            # Render single page at 200 DPI → pipe through PIL resize → PNG
            subprocess.run([
                "pdftoppm", "-r", "200",
                "-f", str(page), "-l", str(page),
                pdf_path, tmp_ppm_base
            ], check=True, capture_output=True)

            # Find the generated file (pdftoppm zero-pads the number)
            import glob
            ppms = glob.glob(f"{tmp_ppm_base}*.ppm")
            if not ppms:
                print("[no image generated]", flush=True)
                continue
            ppm_path = ppms[0]

            from PIL import Image
            img = Image.open(ppm_path)
            img.save(tmp_png)
            os.remove(ppm_path)

            text = ocr_image_path(tmp_png)
            print(text, flush=True)

        except subprocess.CalledProcessError as e:
            print(f"[pdftoppm failed on page {page}: disk full?]", flush=True)
            break
        except Exception as e:
            print(f"[ERROR on page {page}: {e}]", flush=True)
        finally:
            if os.path.exists(tmp_png):
                os.remove(tmp_png)

# ── Entry point ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    arg = sys.argv[1]

    # Special mode: use pre-existing PPMs
    if arg == "ppms":
        prefix = sys.argv[2] if len(sys.argv) > 2 else "/tmp/halting_page"
        ocr_existing_ppms(prefix)
        sys.exit(0)

    if not os.path.exists(arg):
        print(f"File not found: {arg}")
        sys.exit(1)

    start, end = 1, None
    if len(sys.argv) > 2:
        page_arg = sys.argv[2]
        if "-" in page_arg:
            parts = page_arg.split("-")
            start, end = int(parts[0]), int(parts[1])
        else:
            start = end = int(page_arg)

    ocr_pdf(arg, start, end)
