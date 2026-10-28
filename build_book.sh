#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Universal KDP Book Builder & GitHub Pages Documentation Script
# Engine: LuaLaTeX (Native Variable Font Support & Font Cache Reset)
# Repository: https://github.com/chinthakadegunadasa/lpi-ex701-200-preparation-guide-devops-tools-engineer.git
# ==============================================================================

# --- Universal Configuration & Environment Defaults ---
BOOK_TITLE="${BOOK_TITLE:-The Ultimate Handbook of DevOps Practitioner}"
BOOK_REPO_URL="${BOOK_REPO_URL:-https://github.com/chinthakadegunadasa/lpi-ex701-200-preparation-guide-devops-tools-engineer.git}"
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
LATEX_HEADER_FILE="prepress_header.tex"

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
        --target) TARGET_FILES=("${TARGET_FILES[@]}" "$2"); shift 2 ;;
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
        rm -f "$TEMP_PY" "$COMBINED_MD" "$LATEX_HEADER_FILE"
    fi
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

echo "=== [Step 0/8] Pre-flight Dependency & Font Cache Checks ==="
MISSING_DEPS=()
for cmd in pandoc lualatex python3 soffice gs pdftk pdfinfo pdffonts pdfimages pdftoppm fc-list git luaotfload-tool; do
    command -v "$cmd" &> /dev/null || MISSING_DEPS=("${MISSING_DEPS[@]}" "$cmd")
done
python3 -c "import docx" &> /dev/null || MISSING_DEPS=("${MISSING_DEPS[@]}" "python-docx")
python3 -c "import uno" &> /dev/null || MISSING_DEPS=("${MISSING_DEPS[@]}" "python3-uno")
python3 -c "import PIL" &> /dev/null || MISSING_DEPS=("${MISSING_DEPS[@]}" "python3-pil")

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "Error: Missing required dependencies: ${MISSING_DEPS[*]}"
    exit 1
fi

echo "Refreshing LuaLaTeX font cache..."
luaotfload-tool -u -f &>/dev/null || true
echo "All system dependencies verified."

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
            while IFS= read -r file; do FILES=("${FILES[@]}" "$file"); done < <(find "$target" -maxdepth 1 -name "*.md" | sort -V)
        elif [[ -f "$target" ]]; then
            FILES=("${FILES[@]}" "$target")
        fi
    done
else
    [[ -f "title.md" ]] && FILES=("${FILES[@]}" "title.md")
    [[ -f "Introduction.md" ]] && FILES=("${FILES[@]}" "Introduction.md")
    while IFS= read -r file; do FILES=("${FILES[@]}" "$file"); done < <(find . -maxdepth 1 -name "Chapter*.md" | sort -V)
    while IFS= read -r file; do FILES=("${FILES[@]}" "$file"); done < <(find . -maxdepth 1 -name "Appendix_*.md" | sort)
    if [ ${#FILES[@]} -eq 0 ]; then
        while IFS= read -r file; do FILES=("${FILES[@]}" "$file"); done < <(find . -maxdepth 1 -name "*.md" ! -name "README.md" ! -name "TOC.md" | sort -V)
    fi
fi

if [ ${#FILES[@]} -eq 0 ]; then
    echo "Error: No manuscript markdown source files found!"
    exit 1
fi

echo "=== [Step 2/8] Rebuilding reference.docx (Trim: ${TRIM_WIDTH}\" x ${TRIM_HEIGHT}\", Fonts: Google Sans Flex / Google Sans Code) ==="
rm -rf "$REF_DOC"
pandoc --print-default-data-file reference.docx > "$REF_DOC"

python3 - "$TRIM_WIDTH" "$TRIM_HEIGHT" << 'EOF'
import sys
import docx
from docx.enum.text import WD_ALIGN_PARAGRAPH

width = float(sys.argv[1])
height = float(sys.argv[2])

doc = docx.Document('reference.docx')
for section in doc.sections:
    section.page_width = docx.shared.Inches(width)
    section.page_height = docx.shared.Inches(height)
    section.top_margin = docx.shared.Inches(0.75)
    section.bottom_margin = docx.shared.Inches(0.75)
    section.left_margin = docx.shared.Inches(0.875)
    section.right_margin = docx.shared.Inches(0.875)

for style in doc.styles:
    try:
        if style.font is not None:
            if style.name in ['Normal', 'Body Text', 'List Bullet', 'List Number']:
                style.font.name = 'Google Sans Flex'
            elif style.name in ['Monospace', 'Code', 'Verbatim', 'Source Code']:
                style.font.name = 'Google Sans Code'
        if hasattr(style, 'paragraph_format') and style.paragraph_format is not None:
            if style.name in ['Normal', 'Body Text']:
                style.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    except Exception:
        pass

doc.save('reference.docx')
EOF

echo "=== [Step 3/8] Combining Manuscript & Injecting Drop Caps for PDF ==="
> "$COMBINED_MD"
ODD_PAGE_BREAK=$'\n\n```{=openxml}\n<w:p><w:pPr><w:sectPr><w:type w:val="oddPage"/></w:sectPr></w:pPr></w:p>\n```\n\n'

python3 - "$COMBINED_MD" "$ODD_PAGE_BREAK" "${FILES[@]}" << 'EOF_COMBINE'
import sys, re

combined_file = sys.argv[1]
odd_page_break = sys.argv[2]
file_list = sys.argv[3:]

out_content = []

if "title.md" in file_list:
    with open("title.md", "r", encoding="utf-8") as f:
        out_content.append(f.read())
    out_content.append(odd_page_break)

first = True
for fpath in file_list:
    if fpath == "title.md":
        continue
    if not sys.platform.startswith('win'):
        fpath = fpath.lstrip('./')
    try:
        with open(fpath, "r", encoding="utf-8") as f:
            text = f.read()
    except Exception:
        continue

    lines = text.split("\n")
    injected = False
    new_lines = []
    for line in lines:
        if not injected and line.strip() and not line.strip().startswith('#') and not line.strip().startswith('`') and not line.strip().startswith('!'):
            match = re.match(r'^([A-Za-z])(.*)$', line.strip())
            if match:
                first_char = match.group(1)
                rest_word = match.group(2)
                line = f"\\lettrine[lines=3]{{{first_char}}}{{{rest_word[0:4]}}}{rest_word[4:]}"
                injected = True
        new_lines.append(line)
    
    chapter_text = "\n".join(new_lines)

    if first and "title.md" not in file_list:
        out_content.append(chapter_text)
        first = False
    else:
        out_content.append(odd_page_break)
        out_content.append(chapter_text)
        first = False

with open(combined_file, "w", encoding="utf-8") as f:
    f.write("\n".join(out_content))
EOF_COMBINE

python3 - "$TOC_MD" "$BOOK_TITLE" "${FILES[@]}" << 'EOF_TOC'
import sys, os, re

toc_out_file = sys.argv[1]
book_title = sys.argv[2]
file_list = sys.argv[3:]

toc_lines = [
    f"# Table of Contents",
    f"",
    f"Official documentation and study guide for **{book_title}**.",
    f"",
    f"---",
    ""
]

for fpath in file_list:
    fpath = fpath.lstrip('./')
    if fpath in ['TOC.md', 'README.md']:
        continue
    if not os.path.isfile(fpath):
        continue

    try:
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        continue

    h1_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
    if h1_match:
        chapter_title = h1_match.group(1).strip()
    else:
        chapter_title = os.path.splitext(os.path.basename(fpath))[0].replace('_', ' ').title()

    toc_lines.append(f"## [{chapter_title}]({fpath})")

    subheaders = re.findall(r'^(#{2,3})\s+(.+)$', content, re.MULTILINE)
    for hashes, sub_title in subheaders:
        level = len(hashes)
        slug = re.sub(r'[^a-z0-9]+', '-', sub_title.lower()).strip('-')
        if level == 2:
            toc_lines.append(f"  * [{sub_title}]({fpath}#{slug})")
        elif level == 3:
            toc_lines.append(f"    * [{sub_title}]({fpath}#{slug})")
    toc_lines.append("")

with open(toc_out_file, 'w', encoding='utf-8') as f:
    f.write("\n".join(toc_lines) + "\n")

print(f"Generated GitHub Pages compatible TOC.md: {toc_out_file}")
EOF_TOC

echo "=== [Step 4/8] Compiling High-Resolution Prepress PDF via LuaLaTeX ==="
mkdir -p "$BUILD_DIR"
UNOPTIMIZED_PDF="$BUILD_DIR/temp_combined.pdf"

python3 - "$LATEX_HEADER_FILE" "$FONT_FAMILY" "$CODE_FONT_FAMILY" << 'EOF_HEADER'
import sys

header_file = sys.argv[1]
font_family = sys.argv[2]
code_font_family = sys.argv[3]

latex_template = r"""
\usepackage{fontspec}
\setmainfont{__BODY_FONT__}
\setmonofont[Scale=0.85]{__CODE_FONT__}

\usepackage{amssymb}
\usepackage{newunicodechar}
\newunicodechar{→}{\ensuremath{\rightarrow}}
\newunicodechar{✓}{\ensuremath{\checkmark}}
\newunicodechar{✗}{\ensuremath{\times}}

\usepackage{microtype}
\emergencystretch=3em
\hyphenpenalty=500
\exhyphenpenalty=500
\tolerance=200
\sloppy

\hbadness=10000
\vbadness=10000

\usepackage{lettrine}
\usepackage{tocloft}
\renewcommand{\cftdot}{.}
\renewcommand{\cftdotsep}{1.5}
\renewcommand{\cftchapleader}{\cftdotfill{\cftdotsep}}
\renewcommand{\cftsecleader}{\cftdotfill{\cftdotsep}}
\renewcommand{\cftsubsecleader}{\cftdotfill{\cftdotsep}}

\usepackage{fancyhdr}
\usepackage{titlesec}

\titleformat{\chapter}[display]
  {\normalfont\huge\bfseries\centering}
  {\chaptertitlename\ \thechapter}{20pt}{\Huge}
\titleformat{\section}
  {\normalfont\Large\bfseries\centering}
  {\thesection}{1em}{}
\titleformat{\subsection}
  {\normalfont\large\bfseries\centering}
  {\thesubsection}{1em}{}

\pagestyle{fancy}
\fancyhf{}
\setlength{\headheight}{14.5pt}
\fancyhead[C]{\nouppercase{\leftmark}}
\fancyfoot[C]{\thepage}
\renewcommand{\headrulewidth}{0.1pt}
\renewcommand{\footrulewidth}{0.1pt}

\makeatletter
\let\oldfrontmatter\frontmatter
\renewcommand{\frontmatter}{%
  \oldfrontmatter
  \pagenumbering{roman}
  \pagestyle{plain}
}
\let\oldmainmatter\mainmatter
\renewcommand{\mainmatter}{%
  \oldmainmatter
  \pagenumbering{arabic}
  \pagestyle{fancy}
}
\makeatother

\usepackage{fvextra}
\usepackage{xcolor}

\fvset{breaklines=true, breakanywhere=true}

\makeatletter
\let\oldHighlighting\Highlighting
\let\oldendHighlighting\endHighlighting
\renewenvironment{Highlighting}{%
  \oldHighlighting
  \fvset{breaklines=true, breakanywhere=true, fontsize=\small, frame=single, framerule=0.5pt, rulecolor=\color{black!30}}%
}{%
  \oldendHighlighting
}
\makeatother

% Break long inline code paths cleanly without throwing errors on TeX escape commands
\OldTexttt
\let\oldtexttt\texttt
\renewcommand{\texttt}[1]{%
  \oldtexttt{\hyphenchar\font=`\/\discretionary{/}{/}{}\ZeroWidthSpace #1}%
}

\usepackage{graphicx}
\usepackage{caption}
\captionsetup[figure]{font=it,justification=centering,singlelinecheck=false}
\let\Oldincludegraphics\includegraphics
\renewcommand{\includegraphics}[2][]{%
  \begin{center}
    \Oldincludegraphics[width=1.0\textwidth,keepaspectratio]{#2}%
  \end{center}
}
"""

latex_content = latex_template.replace("__BODY_FONT__", font_family) \
                               .replace("__CODE_FONT__", code_font_family)

with open(header_file, 'w', encoding='utf-8') as f:
    f.write(latex_content.strip() + "\n")
EOF_HEADER

if [[ "$OUTPUT_FORMAT" == "all" || "$OUTPUT_FORMAT" == "pdf" ]]; then
    pandoc "$COMBINED_MD" \
      --from=markdown+tex_math_single_backslash+tex_math_dollars \
      --pdf-engine=lualatex \
      --toc \
      --toc-depth=3 \
      --top-level-division=chapter \
      -V documentclass=book \
      -V classoption=openright,twoside,11pt \
      -V geometry="paperwidth=${TRIM_WIDTH}in,paperheight=${TRIM_HEIGHT}in,margin=1in,inner=1.25in,outer=1in,headsep=0.2in" \
      -V linestretch=1.15 \
      -V title="$BOOK_TITLE" \
      -H "$LATEX_HEADER_FILE" \
      -o "$UNOPTIMIZED_PDF"
fi

echo "=== [Step 5/8] Compiling DOCX & EPUB Formats (with Full Justification & Dynamic TOC) ==="
PANDOC_ARGS=(
    "$COMBINED_MD"
    --from=markdown+tex_math_single_backslash+tex_math_dollars
    --to=docx
    --output="$INTERMEDIATE_DOCX"
    --reference-doc="$REF_DOC"
    --toc
    --toc-depth=3
    --metadata=title="$BOOK_TITLE"
)
[[ -f "references.bib" ]] && PANDOC_ARGS=("${PANDOC_ARGS[@]}" "--citeproc" "--bibliography=references.bib")
pandoc "${PANDOC_ARGS[@]}"

if [[ "$OUTPUT_FORMAT" == "epub" || "$OUTPUT_FORMAT" == "all" ]]; then
    EPUB_ARGS=(
        "$COMBINED_MD"
        --from=markdown+tex_math_single_backslash+tex_math_dollars
        --to=epub3
        --output="$FINAL_EPUB"
        --toc
        --toc-depth=3
        --metadata=title="$BOOK_TITLE"
    )
    if [[ "$SKIP_COVER" == false && -f "$COVER_IMG" ]]; then
        EPUB_ARGS=("${EPUB_ARGS[@]}" "--epub-cover-image=$COVER_IMG")
    fi
    pandoc "${EPUB_ARGS[@]}"
fi

# LibreOffice Python bridge script (Fixed camelCase API)
cat << 'EOF_LO' > "$TEMP_PY"
import uno
import sys
import os

local_context = uno.getComponentContext()
resolver = local_context.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", local_context)
try:
    context = resolver.resolve("uno:socket,host=localhost,port=2002;urp;StarOffice.ComponentContext")
except Exception as e:
    sys.exit(1)

desktop = context.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", context)
cwd = os.getcwd()
docx_path = os.path.join(cwd, sys.argv[1])
url = f"file://{docx_path}"

properties = []
p = uno.createUnoStruct('com.sun.star.beans.PropertyValue')
p.Name = 'Hidden'
p.Value = True
properties.append(p)

doc = desktop.loadComponentFromURL(url, "_blank", 0, tuple(properties))
indexes = doc.getDocumentIndexes()
for i in range(indexes.getCount()):
    index = indexes.getByIndex(i)
    index.update()

doc.store()
doc.close(True)
EOF_LO

soffice --headless --accept="socket,host=localhost,port=2002;urp;" &
LO_PID=$!
sleep 3
python3 "$TEMP_PY" "$INTERMEDIATE_DOCX" || true
mv "$INTERMEDIATE_DOCX" "$FINAL_DOCX"

echo "=== [Step 6/8] Optimizing Interior PDF & Applying Watermark ==="
if [[ "$OUTPUT_FORMAT" == "all" || "$OUTPUT_FORMAT" == "pdf" ]]; then
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.6 -dPDFSETTINGS=/prepress -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$FINAL_PDF" "$UNOPTIMIZED_PDF"

    if [[ -n "$WATERMARK_TEXT" ]]; then
        echo "Applying watermark: $WATERMARK_TEXT"
        python3 - "$FINAL_PDF" "$WATERMARK_TEXT" << 'EOF_WM'
import sys
from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
import io

pdf_in = sys.argv[1]
watermark_text = sys.argv[2]

packet = io.BytesIO()
can = canvas.Canvas(packet, pagesize=letter)
can.setFont("Helvetica-Bold", 40)
can.setFillColorRGB(0.8, 0.8, 0.8, alpha=0.3)
can.saveState()
can.translate(300, 400)
can.rotate(45)
can.drawCentredString(0, 0, watermark_text)
can.restoreState()
can.save()

packet.seek(0)
watermark_pdf = PdfReader(packet)
watermark_page = watermark_pdf.pages[0]

reader = PdfReader(pdf_in)
writer = PdfWriter()

for page in reader.pages:
    page.merge_page(watermark_page)
    writer.add_page(page)

with open(pdf_in, "wb") as f:
    writer.write(f)
EOF_WM
    fi
fi

echo "=== [Step 7/8] Cover Integration & Final Assembly ==="
if [[ "$SKIP_COVER" == false && "$OUTPUT_FORMAT" != "epub" ]]; then
    if [[ -f "$FRONT_COVER_PDF" && -f "$FINAL_PDF" ]]; then
        pdftk "$FRONT_COVER_PDF" "$FINAL_PDF" cat output "${BUILD_DIR}/temp_with_front.pdf"
        mv "${BUILD_DIR}/temp_with_front.pdf" "$FINAL_PDF"
    fi
    if [[ -f "$BACK_COVER_PDF" && -f "$FINAL_PDF" ]]; then
        pdftk "$FINAL_PDF" "$BACK_COVER_PDF" cat output "${BUILD_DIR}/temp_with_back.pdf"
        mv "${BUILD_DIR}/temp_with_back.pdf" "$FINAL_PDF"
    fi
fi

echo "=== [Step 8/8] Build Complete ==="
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

cat << EOF_REPORT > "$BUILD_REPORT"
Build Execution Summary
=======================
Book Title: $BOOK_TITLE
Build Time: ${ELAPSED} seconds
Generated Files:
- PDF:  $FINAL_PDF
- DOCX: $FINAL_DOCX
- EPUB: $FINAL_EPUB
- TOC:  $TOC_MD
EOF_REPORT

cat "$BUILD_REPORT"
