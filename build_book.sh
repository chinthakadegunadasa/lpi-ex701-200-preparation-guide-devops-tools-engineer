#!/usr/bin/env bash
set -euo pipefail

# --- Universal Configuration & Environment Defaults ---
BOOK_TITLE="${BOOK_TITLE:-The Ultimate Handbook of DevOps Practitioner}"
BOOK_REPO_URL="${BOOK_REPO_URL:-}"
SLUG_TITLE=$(echo "$BOOK_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

INTERMEDIATE_DOCX="temp_combined.docx"
FINAL_DOCX="${FINAL_DOCX:-${SLUG_TITLE}-KDP.docx}"
FINAL_PDF="${FINAL_PDF:-${SLUG_TITLE}-KDP.pdf}"
FINAL_EPUB="${FINAL_EPUB:-${SLUG_TITLE}.epub}"
BUILD_DIR="build_out"
COMBINED_MD="combined_manuscript.md"
TOC_MD="TOC.md"
REF_DOC="reference.docx"
FRONT_COVER_PDF="${FRONT_COVER_PDF:-front_cover.pdf}"
BACK_COVER_PDF="${BACK_COVER_PDF:-back_cover.pdf}"
COVER_IMG="${COVER_IMG:-front_cover_flat.png}"
EPUB_CSS="epub.css"
BUILD_REPORT="build_report.txt"
TEMP_PY="update_toc_bridge.py"

LO_PID=""
DRY_RUN=false
SKIP_COVER=false
DEBUG=false
BUILD_PROFILE="${BUILD_PROFILE:-kdp}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-all}"
CUSTOM_OUTPUT=""
WATERMARK_TEXT="${WATERMARK_TEXT:-}"
FONT_FAMILY="${FONT_FAMILY:-Google Sans Flex}"
CODE_FONT_FAMILY="${CODE_FONT_FAMILY:-Google Sans Code}"
TRIM_WIDTH="${TRIM_WIDTH:-8.25}"
TRIM_HEIGHT="${TRIM_HEIGHT:-11.0}"
TARGET_FILES=()

START_TIME=$(date +%s)

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo) BOOK_REPO_URL="$2"; shift 2 ;;
        --title) BOOK_TITLE="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --skip-cover) SKIP_COVER=true; shift ;;
        --debug) DEBUG=true; shift ;;
        --output) CUSTOM_OUTPUT="$2"; shift 2 ;;
        --profile) BUILD_PROFILE="$2"; shift 2 ;;
        --format) OUTPUT_FORMAT="$2"; shift 2 ;;
        --font) FONT_FAMILY="$2"; shift 2 ;;
        --code-font) CODE_FONT_FAMILY="$2"; shift 2 ;;
        --watermark) WATERMARK_TEXT="$2"; shift 2 ;;
        --target) TARGET_FILES+=("$2"); shift 2 ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --repo <url>         Git repository URL containing manuscript markdown files"
            echo "  --title <title>      Set book title dynamically"
            echo "  --dry-run            Validate environment without building"
            echo "  --skip-cover         Skip merging covers or embedding EPUB cover images"
            echo "  --debug              Preserve intermediate build artifacts"
            echo "  --output <file>      Specify custom output filename base"
            echo "  --profile <name>     Set build profile ('kdp' or 'draft')"
            echo "  --format <fmt>       Output format ('pdf', 'epub', 'docx', or 'all')"
            echo "  --font <name>        Override body font family"
            echo "  --code-font <name>   Override monospace font family"
            echo "  --watermark <text>   Apply diagonal watermark across interior PDF"
            echo "  --target <file/dir>  Specify individual file or directory"
            echo "  --help               Display this help message"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -n "$CUSTOM_OUTPUT" ]]; then
    FINAL_PDF="${CUSTOM_OUTPUT}.pdf"
    FINAL_DOCX="${CUSTOM_OUTPUT}.docx"
    FINAL_EPUB="${CUSTOM_OUTPUT}.epub"
fi

# --- Robust Cleanup Trap ---
cleanup() {
    local exit_code=$?
    if [[ -n "$LO_PID" ]] && kill -0 "$LO_PID" 2>/dev/null; then
        kill "$LO_PID" 2>/dev/null || true
        wait "$LO_PID" 2>/dev/null || true
    fi
    if [[ "$DEBUG" != true ]]; then
        rm -f "$TEMP_PY" "$COMBINED_MD"
    fi
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

echo "=== [Step 0/8] Pre-flight Dependency Checks ==="
MISSING_DEPS=()
for cmd in pandoc python3 soffice gs pdftk pdfinfo pdffonts pdfimages pdftoppm fc-list git; do
    command -v "$cmd" &> /dev/null || MISSING_DEPS+=("$cmd")
done
python3 -c "import docx" &> /dev/null || MISSING_DEPS+=("python-docx")
python3 -c "import uno" &> /dev/null || MISSING_DEPS+=("python3-uno")
python3 -c "import PIL" &> /dev/null || MISSING_DEPS+=("python3-pil (Pillow)")

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "Error: Missing required dependencies: ${MISSING_DEPS[*]}"
    exit 1
fi

# --- Remote Repository Ingestion ---
if [[ -n "$BOOK_REPO_URL" ]]; then
    echo "=== Fetching Manuscript Files from Remote GitHub Repository ==="
    echo "Repository URL: $BOOK_REPO_URL"
    git clone --depth 1 "$BOOK_REPO_URL" temp_repo_workspace
    shopt -s nullglob
    cp -rn temp_repo_workspace/* ./ 2>/dev/null || true
    rm -rf temp_repo_workspace
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run mode successful. Exiting."
    exit 0
fi

echo "=== [Step 1/8] Assembling & Validating Manuscript Source Files ==="
FILES=()
if [ ${#TARGET_FILES[@]} -gt 0 ]; then
    for target in "${TARGET_FILES[@]}"; do
        if [[ -d "$target" ]]; then
            while IFS= read -r file; do FILES+=("$file"); done < <(find "$target" -maxdepth 1 -name "*.md" | sort -V)
        elif [[ -f "$target" ]]; then
            FILES+=("$target")
        fi
    done
else
    [[ -f "title.md" ]] && FILES+=("title.md")
    [[ -f "Introduction.md" ]] && FILES+=("Introduction.md")
    while IFS= read -r file; do FILES+=("$file"); done < <(find . -maxdepth 1 -name "Chapter*.md" | sort -V)
    while IFS= read -r file; do FILES+=("$file"); done < <(find . -maxdepth 1 -name "Appendix_*.md" | sort)
    if [ ${#FILES[@]} -eq 0 ]; then
        while IFS= read -r file; do FILES+=("$file"); done < <(find . -maxdepth 1 -name "*.md" ! -name "README.md" ! -name "TOC.md" | sort -V)
    fi
fi

if [ ${#FILES[@]} -eq 0 ]; then
    echo "Error: No manuscript markdown source files found!"
    exit 1
fi

echo "=== [Step 2/8] Rebuilding reference.docx (Trim: ${TRIM_WIDTH}\" x ${TRIM_HEIGHT}\") ==="
rm -rf "$REF_DOC"
pandoc --print-default-data-file reference.docx > "$REF_DOC"

python3 - "$TRIM_WIDTH" "$TRIM_HEIGHT" << 'EOF'
import sys
import docx
from docx.shared import Inches

width = float(sys.argv[1])
height = float(sys.argv[2])

doc = docx.Document('reference.docx')
for section in doc.sections:
    section.page_width = Inches(width)
    section.page_height = Inches(height)
    section.top_margin = Inches(0.75)
    section.bottom_margin = Inches(0.75)
    section.left_margin = Inches(0.875)
    section.right_margin = Inches(0.875)
doc.save('reference.docx')
EOF

echo "=== [Step 3/8] Combining Manuscript Files & Generating TOC.md for GitHub Pages ==="
> "$COMBINED_MD"
ODD_PAGE_BREAK=$'\n\n```{=openxml}\n<w:p><w:pPr><w:sectPr><w:type w:val="oddPage"/></w:sectPr></w:pPr></w:p>\n```\n\n'

if [[ -f "title.md" && ${#TARGET_FILES[@]} -eq 0 ]]; then
    cat "title.md" >> "$COMBINED_MD"
    echo -e "$ODD_PAGE_BREAK" >> "$COMBINED_MD"
fi

FIRST=true
for f in "${FILES[@]}"; do
    [[ "$f" == "title.md" && ${#TARGET_FILES[@]} -eq 0 ]] && continue
    if [[ "$FIRST" == true && ! -f "title.md" ]]; then
        cat "$f" >> "$COMBINED_MD"
        FIRST=false
    else
        echo "$ODD_PAGE_BREAK" >> "$COMBINED_MD"
        cat "$f" >> "$COMBINED_MD"
        FIRST=false
    fi
done

python3 - "$COMBINED_MD" "$TOC_MD" << 'EOF_TOC'
import sys, re

md_file = sys.argv[1]
toc_out_file = sys.argv[2]

with open(md_file, 'r', encoding='utf-8') as f:
    content = f.read()

cleaned = re.sub(r'(?i)#+\s+Table of Contents.*?(?=\n#|\Z)', '', content, flags=re.DOTALL)

with open(md_file, 'w', encoding='utf-8') as f:
    f.write(cleaned)

headers = re.findall(r'^(#{1,4})\s+(.+)$', cleaned, re.MULTILINE)

toc_lines = [
    f"# Table of Contents",
    f"",
    f"*Auto-generated table of contents for **{sys.argv[0]}** website & documentation.*\n",
    ""
]

for hashes, title in headers:
    level = len(hashes)
    if level > 3:
        continue
    indent = "    " * (level - 1)
    slug = re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')
    toc_lines.append(f"{indent}* [{title}](#{slug})")

with open(toc_out_file, 'w', encoding='utf-8') as f:
    f.write("\n".join(toc_lines) + "\n")

print(f"Generated GitHub Pages TOC file: {toc_out_file}")
EOF_TOC

echo "=== [Step 4/8] Compiling Intermediate Formats & Forcing Odd-Numbered TOC Page ==="
PANDOC_ARGS=(
    "$COMBINED_MD"
    --from=markdown
    --to=docx
    --output="$INTERMEDIATE_DOCX"
    --reference-doc="$REF_DOC"
    --toc
    --toc-depth=3
    --metadata=title="$BOOK_TITLE"
)
[[ -f "references.bib" ]] && PANDOC_ARGS+=(--citeproc --bibliography=references.bib)
pandoc "${PANDOC_ARGS[@]}"

if [[ "$OUTPUT_FORMAT" == "epub" || "$OUTPUT_FORMAT" == "all" ]]; then
    EPUB_CMD=(pandoc "$COMBINED_MD" --from=markdown --to=epub3 --output="$FINAL_EPUB" --toc --toc-depth=3 --metadata=title="$BOOK_TITLE")
    [[ "$SKIP_COVER" == false && -f "$COVER_IMG" ]] && EPUB_CMD+=(--epub-cover-image="$COVER_IMG")
    [[ -f "$EPUB_CSS" ]] && EPUB_CMD+=(--css="$EPUB_CSS")
    "${EPUB_CMD[@]}"
fi

python3 - << 'EOF'
import docx
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

doc = docx.Document('temp_combined.docx')
toc_found = False
for p in doc.paragraphs:
    text = p.text.strip()
    if "Table of Contents" in text or "Contents" in text:
        pPr = p._p.get_or_add_pPr()
        sectPr = OxmlElement('w:sectPr')
        type_elem = OxmlElement('w:type')
        type_elem.set(qn('w:val'), 'oddPage')
        sectPr.append(type_elem)
        pPr.append(sectPr)
        toc_found = True
        break

if not toc_found and len(doc.paragraphs) > 1:
    for p in doc.paragraphs[1:10]:
        if p._p.xpath('.//w:fldSimple[contains(@w:instr, "TOC")]') or p._p.xpath('.//w:fldChar'):
            pPr = p._p.get_or_add_pPr()
            sectPr = OxmlElement('w:sectPr')
            type_elem = OxmlElement('w:type')
            type_elem.set(qn('w:val'), 'oddPage')
            sectPr.append(type_elem)
            pPr.append(sectPr)
            break

doc.save('temp_combined.docx')
print("Odd-page TOC constraint successfully enforced.")
EOF

echo "=== [Step 5/8] Updating Native TOC Fields & Rendering PDF via LibreOffice ==="
mkdir -p "$BUILD_DIR"
UNOPTIMIZED_PDF="$BUILD_DIR/temp_combined.pdf"

soffice --headless --accept="socket,host=127.0.0.1,port=2002;urp;" &
LO_PID=$!
sleep 3

cat << 'EOF' > "$TEMP_PY"
import os
import sys
import uno
from com.sun.star.beans import PropertyValue

def convert_docx_with_socket_toc(input_docx, output_pdf):
    localContext = uno.getComponentContext()
    resolver = localContext.ServiceManager.createInstanceWithContext(
        "com.sun.star.bridge.UnoUrlResolver", localContext
    )
    ctx = resolver.resolve("uno:socket,host=127.0.0.1,port=2002;urp;StarOffice.ComponentContext")
    smgr = ctx.ServiceManager
    desktop = smgr.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)
    
    doc_url = uno.systemPathToFileUrl(os.path.abspath(input_docx))
    doc = desktop.loadComponentFromURL(doc_url, "_blank", 0, (PropertyValue("Hidden", 0, True, 0),))
    
    if hasattr(doc, "refresh"):
        doc.refresh()
        
    try:
        indexes = doc.getDocumentIndexes()
        for i in range(indexes.getCount()):
            indexes.getByIndex(i).update()
    except Exception as e:
        print(f"Notice during TOC update: {e}")

    docx_url = uno.systemPathToFileUrl(os.path.abspath(input_docx))
    doc.storeToURL(docx_url, (PropertyValue("FilterName", 0, "MS Word 2007 XML", 0),))

    pdf_url = uno.systemPathToFileUrl(os.path.abspath(output_pdf))
    doc.storeToURL(pdf_url, (PropertyValue("FilterName", 0, "writer_pdf_Export", 0),))
    doc.close(True)

if __name__ == "__main__":
    convert_docx_with_socket_toc(sys.argv[1], sys.argv[2])
EOF

python3 "$TEMP_PY" "$INTERMEDIATE_DOCX" "$UNOPTIMIZED_PDF"

kill "$LO_PID" 2>/dev/null || true
wait "$LO_PID" 2>/dev/null || true
LO_PID=""

cp "$INTERMEDIATE_DOCX" "$FINAL_DOCX"
rm -f "$TEMP_PY" "$INTERMEDIATE_DOCX" "$COMBINED_MD"

if [[ "$OUTPUT_FORMAT" == "docx" ]]; then
    exit 0
fi

OPTIMIZED_INTERIOR="$BUILD_DIR/optimized_interior.pdf"
GS_SETTINGS="/prepress"
[[ "$BUILD_PROFILE" == "draft" ]] && GS_SETTINGS="/screen"

gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS="$GS_SETTINGS" \
   -dNOPAUSE -dQUIET -dBATCH -dEmbedAllFonts=true -dSubsetFonts=true \
   -sOutputFile="$OPTIMIZED_INTERIOR" "$UNOPTIMIZED_PDF"
rm -f "$UNOPTIMIZED_PDF"

if [[ -n "$WATERMARK_TEXT" ]]; then
    WATERMARKED_PDF="$BUILD_DIR/watermarked_interior.pdf"
    cat << PS_EOF > "$BUILD_DIR/watermark.ps"
/Helvetica-Bold findfont 48 scalefont setfont 0.93 setgray
1 1 { pop gsave 250 400 translate 45 rotate 0 0 moveto ($WATERMARK_TEXT) show grestore } for
PS_EOF
    gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile="$WATERMARKED_PDF" "$BUILD_DIR/watermark.ps" "$OPTIMIZED_INTERIOR" 2>/dev/null || true
    [[ -f "$WATERMARKED_PDF" ]] && mv "$WATERMARKED_PDF" "$OPTIMIZED_INTERIOR"
    rm -f "$BUILD_DIR/watermark.ps"
fi

echo "=== [Step 7/8] Cover Integration & Final Assembly ==="
FINAL_OUTPUT_PATH="$OPTIMIZED_INTERIOR"
if [[ "$SKIP_COVER" == false && -f "$FRONT_COVER_PDF" && -f "$BACK_COVER_PDF" ]]; then
    MERGED_PDF="$BUILD_DIR/final_book_with_covers.pdf"
    pdftk "$FRONT_COVER_PDF" "$OPTIMIZED_INTERIOR" "$BACK_COVER_PDF" cat output "$MERGED_PDF"
    FINAL_OUTPUT_PATH="$MERGED_PDF"
elif [[ "$SKIP_COVER" == false && -f "$FRONT_COVER_PDF" ]]; then
    MERGED_PDF="$BUILD_DIR/final_book_with_covers.pdf"
    pdftk "$FRONT_COVER_PDF" "$OPTIMIZED_INTERIOR" cat output "$MERGED_PDF"
    FINAL_OUTPUT_PATH="$MERGED_PDF"
fi

mv "$FINAL_OUTPUT_PATH" "$FINAL_PDF"
rm -rf "$BUILD_DIR"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

cat << REPORT > "$BUILD_REPORT"
=== KDP Build Report ===
Date: $(date)
Book Title: $BOOK_TITLE
Duration: ${ELAPSED} seconds
Build Profile: $BUILD_PROFILE
Output Format: $OUTPUT_FORMAT

Generated Artifacts:
  - DOCX: $FINAL_DOCX
  - TOC:  $TOC_MD
$([[ "$OUTPUT_FORMAT" == "all" || "$OUTPUT_FORMAT" == "pdf" ]] && echo "  - PDF:  $FINAL_PDF")
$([[ "$OUTPUT_FORMAT" == "all" || "$OUTPUT_FORMAT" == "epub" ]] && echo "  - EPUB: $FINAL_EPUB")
REPORT

echo "=== [Step 8/8] Build Complete ==="
