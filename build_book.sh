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

# Refresh LuaLaTeX font database to prevent missing font metric errors
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
    except Exception:
        pass

doc.save('reference.docx')
EOF

echo "=== [Step 3/8] Combining Manuscript & Ensuring Dedicated Title Page Before TOC ==="
> "$COMBINED_MD"
ODD_PAGE_BREAK=$'\n\n```{=openxml}\n<w:p><w:pPr><w:sectPr><w:type w:val="oddPage"/></w:sectPr></w:pPr></w:p>\n```\n\n'

# Place title.md on a dedicated page before the Table of Contents
if [[ -f "title.md" ]]; then
    cat "title.md" >> "$COMBINED_MD"
    echo -e "$ODD_PAGE_BREAK" >> "$COMBINED_MD"
fi

FIRST=true
for f in "${FILES[@]}"; do
    [[ "$f" == "title.md" ]] && continue
    if [[ "$FIRST" == true && ! -f "title.md" ]]; then
        cat "$f" >> "$COMBINED_MD"
        FIRST=false
    else
        echo -e "$ODD_PAGE_BREAK" >> "$COMBINED_MD"
        cat "$f" >> "$COMBINED_MD"
        FIRST=false
    fi
done

# Python script to generate GitHub Pages compatible TOC.md
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

# Generate LaTeX header with drop caps, center headings, and wrapped code blocks
python3 - "$LATEX_HEADER_FILE" "$FONT_FAMILY" "$CODE_FONT_FAMILY" << 'EOF_HEADER'
import sys

header_file = sys.argv[1]
font_family = sys.argv[2]
code_font_family = sys.argv[3]

latex_template = r"""
\usepackage{fontspec}
\setmainfont{__BODY_FONT__}
\setmonofont{__CODE_FONT__}

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

% Center-align all heading levels
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
\fancyhead[LE,RO]{\nouppercase{\leftmark}}
\fancyfoot[C]{\thepage}
\renewcommand{\headrulewidth}{0.1pt}
\renewcommand{\footrulewidth}{0.0pt}

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
\DefineVerbatimEnvironment{Highlighting}{Verbatim}{
  breaklines=true,
  breakanywhere=true,
  fontsize=\small,
  commandchars=\\\{\},
  frame=single,
  framerule=0.5pt,
  rulecolor=\color{black!30},
  xleftmargin=0pt,
  xrightmargin=0pt,
  samepage
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
      --from=markdown+tex_math_single_backslash \
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

echo "=== [Step 5/8] Compiling DOCX & EPUB Formats (with Automated TOC) ==="
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
[[ -f "references.bib" ]] && PANDOC_ARGS=("${PANDOC_ARGS[@]}" "--citeproc" "--bibliography=references.bib")
pandoc "${PANDOC_ARGS[@]}"

if [[ "$OUTPUT_FORMAT" == "epub" || "$OUTPUT_FORMAT" == "all" ]]; then
    EPUB_CMD=(pandoc "$COMBINED_MD" --from=markdown --to=epub3 --output="$FINAL_EPUB" --toc --toc-depth=3 --metadata=title="$BOOK_TITLE")
    [[ "$SKIP_COVER" == false && -f "$COVER_IMG" ]] && EPUB_CMD=("${EPUB_CMD[@]}" "--epub-cover-image=$COVER_IMG")
    [[ -f "$EPUB_CSS" ]] && EPUB_CMD=("${EPUB_CMD[@]}" "--css=$EPUB_CSS")
    "${EPUB_CMD[@]}"
fi

python3 - << 'EOF'
import docx
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

doc = docx.Document('temp_combined.docx')

# 1. Enforce Odd-page constraint for TOC
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

# 2. Inject dynamic Word TOC field if missing
has_toc_field = any(p._p.xpath('.//w:fldSimple[contains(@w:instr, "TOC")]') or p._p.xpath('.//w:fldChar') for p in doc.paragraphs)
if not has_toc_field and len(doc.paragraphs) > 1:
    p_toc = doc.paragraphs[1]
    run = p_toc.add_run()
    fldChar1 = OxmlElement('w:fldChar')
    fldChar1.set(qn('w:fldCharType'), 'begin')
    instrText = OxmlElement('w:instrText')
    instrText.set(qn('xml:space'), 'preserve')
    instrText.text = 'TOC \\o "1-3" \\h \\z \\u'
    fldChar2 = OxmlElement('w:fldChar')
    fldChar2.set(qn('w:fldCharType'), 'separate')
    fldChar3 = OxmlElement('w:fldChar')
    fldChar3.set(qn('w:fldCharType'), 'end')
    r = run._r
    r.append(fldChar1)
    r.append(instrText)
    r.append(fldChar2)
    r.append(fldChar3)

# 3. Enlarge first letter of first paragraphs of chapters (Drop Cap styling approximation in docx)
for p in doc.paragraphs:
    if p.text and len(p.text) > 0 and p.style.name.startswith('Heading'):
        pass
    # Simple heuristic for body paragraphs following headings
    # We ensure font styling matches Google Sans Flex
    for run in p.runs:
        run.font.name = 'Google Sans Flex'

doc.save('temp_combined.docx')
print("DOCX styling, fonts, and automated TOC successfully enforced.")
EOF

cp "$INTERMEDIATE_DOCX" "$FINAL_DOCX"
rm -f "$INTERMEDIATE_DOCX"

echo "=== [Step 6/8] Optimizing Interior PDF & Applying Watermark ==="
OPTIMIZED_INTERIOR="$BUILD_DIR/optimized_interior.pdf"
GS_SETTINGS="/prepress"
[[ "$BUILD_PROFILE" == "draft" ]] && GS_SETTINGS="/screen"

if [ -f "$UNOPTIMIZED_PDF" ]; then
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
fi

echo "=== [Step 7/8] Cover Integration & Final Assembly ==="
FINAL_OUTPUT_PATH="$OPTIMIZED_INTERIOR"
if [[ "$SKIP_COVER" == false && -f "$FRONT_COVER_PDF" && -f "$BACK_COVER_PDF" && -f "$OPTIMIZED_INTERIOR" ]]; then
    MERGED_PDF="$BUILD_DIR/final_book_with_covers.pdf"
    pdftk "$FRONT_COVER_PDF" "$OPTIMIZED_INTERIOR" "$BACK_COVER_PDF" cat output "$MERGED_PDF"
    FINAL_OUTPUT_PATH="$MERGED_PDF"
elif [[ "$SKIP_COVER" == false && -f "$FRONT_COVER_PDF" && -f "$OPTIMIZED_INTERIOR" ]]; then
    MERGED_PDF="$BUILD_DIR/final_book_with_covers.pdf"
    pdftk "$FRONT_COVER_PDF" "$OPTIMIZED_INTERIOR" cat output "$MERGED_PDF"
    FINAL_OUTPUT_PATH="$MERGED_PDF"
fi

[[ -f "$FINAL_OUTPUT_PATH" ]] && mv "$FINAL_OUTPUT_PATH" "$FINAL_PDF"
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
