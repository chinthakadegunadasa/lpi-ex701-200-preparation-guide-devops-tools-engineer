#!/usr/bin/env bash
# ==============================================================================
# Universal KDP Book Builder Script
# Target: The Ultimate Handbook of DevOps Practitioner
# Features: Prepress PDF styling, automated TOC generation, EPUB & DOCX outputs
# ==============================================================================

set -euo pipefail

# --- Pre-flight Checks ---
echo "=== [Step 0/8] Pre-flight Dependency Checks ==="
MISSING_DEPS=()
for cmd in pandoc libreoffice ghostscript pdftk; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_DEPS+=("$cmd")
    fi
done

if ! python3 -c "import uno" &> /dev/null; then
    MISSING_DEPS+=("python3-uno")
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "Error: Missing required dependencies: ${MISSING_DEPS[*]}"
    exit 1
fi
echo "All system dependencies verified."

# --- Parse Arguments ---
PROFILE="kdp"
OUTPUT_FORMAT="all"
REMOTE_REPO=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        --format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --repo)
            REMOTE_REPO="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# --- Step 1: Remote Repository Ingestion (Optional) ---
if [ -n "$REMOTE_REPO" ]; then
    echo "=== [Step 1/8] Cloning Remote Content Repository ==="
    TEMP_DIR=$(mktemp -d)
    git clone "$REMOTE_REPO" "$TEMP_DIR"
    cp -r "$TEMP_DIR"/*.md .
    rm -rf "$TEMP_DIR"
fi

# --- Step 2: Auto-generate Table of Contents (TOC.md) ---
echo "=== [Step 2/8] Generating Table of Contents (TOC.md) ==="
python3 -c "
import os
import re

def natural_sort_key(s):
    return [int(text) if text.isdigit() else text.lower() for text in re.split(r'(\d+)', s)]

md_files = [f for f in os.listdir('.') if f.endswith('.md') and f.lower() not in ['toc.md', 'readme.md', 'title.md']]
md_files.sort(key=natural_sort_key)

toc_lines = ['# Table of Contents\n\n']

for f in md_files:
    clean_name = os.path.splitext(f)[0]
    clean_title = re.sub(r'([a-zA-Z]+)(\d+)', r'\1 \2', clean_name).replace('_', ' ').replace('-', ' ').title()
    toc_lines.append(f'- [{clean_title}]({f})\n')
    
    # Parse headings from file
    with open(f, 'r', encoding='utf-8') as file:
        for line in file:
            match = re.match(r'^(#{2,3})\s+(.+)$', line)
            if match:
                level = len(match.group(1))
                heading = match.group(2).strip()
                indent = '  ' * (level - 1)
                anchor = heading.lower().replace(' ', '-').replace(':', '')
                toc_lines.append(f'{indent}- [{heading}]({f}#{anchor})\n')

with open('TOC.md', 'w', encoding='utf-8') as toc_file:
    toc_file.writelines(toc_lines)
print('TOC.md successfully updated.')
"

# --- Collect Markdown Input Files in Order ---
INPUT_FILES=()
if [ -f "title.md" ]; then
    INPUT_FILES+=("title.md")
fi
if [ -f "TOC.md" ]; then
    INPUT_FILES+=("TOC.md")
fi

while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    if [[ "$filename" != "TOC.md" && "$filename" != "README.md" && "$filename" != "title.md" ]]; then
        INPUT_FILES+=("$file")
    fi
done < <(find . -maxdepth 1 -name "*.md" -print0 | sort -z)

BOOK_TITLE="${BOOK_TITLE:-The Ultimate Handbook of DevOps Practitioner}"
BOOK_FILENAME="$(echo "$BOOK_TITLE" | tr ' ' '_')"

# --- Step 3: Compile Prepress PDF via XeLaTeX ---
if [[ "$OUTPUT_FORMAT" == "all" || "$OUTPUT_FORMAT" == "pdf" ]]; then
    echo "=== [Step 3/8] Compiling High-Resolution Prepress PDF ==="
    
    pandoc "${INPUT_FILES[@]}" \
      --from markdown+tex_math_single_backslash \
      --pdf-engine=xelatex \
      --top-level-division=chapter \
      -V documentclass=book \
      -V classoption=openright,twoside,11pt \
      -V papersize=a4 \
      -V geometry="margin=1in,inner=1.25in,outer=1in" \
      -V mainfont="Liberation Serif" \
      -V monofont="Liberation Mono" \
      -V linestretch=1.15 \
      -H <(cat <<'EOF'
      % --- 1. Fully Justified Paragraphs, Hyphenation & Single-Space Control ---
      \usepackage{microtype}
      \spaceskip=0.333em plus 0.1em minus 0.05em % Restricts word spacing to single character standard
      \hyphenpenalty=500
      \exhyphenpenalty=500

      % --- 6, 7 & 8. Headers, Footers, Roman Numerals & 0.1pt Rules ---
      \usepackage{fancyhdr}
      \usepackage{titlesec}
      \pagestyle{fancy}
      \fancyhf{}
      \fancyhead[LE,RO]{\nouppercase{\leftmark}} % 7. Dynamic Chapter Header
      \fancyhead[RE,LO]{The Ultimate Handbook of DevOps Practitioner}
      \fancyfoot[LE,RO]{\thepage}
      \renewcommand{\headrulewidth}{0.1pt} % 8. 0.1pt rule for header
      \renewcommand{\footrulewidth}{0.0pt}

      % Define Frontmatter handling for 5 & 6 (Title page isolation & Roman numerals for TOC)
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

      % --- 2. Left Justified Source Code Blocks ---
      \usepackage{fvextra}
      \usepackage{xcolor}
      \DefineVerbatimEnvironment{Highlighting}{Verbatim}{
        breaklines,
        commandchars=\\\{\},
        frame=single,
        framerule=0.5pt,
        rulecolor=\color{black!30},
        xleftmargin=0pt,
        samepage,
        raggedright % Ensures left justification
      }

      % --- 3 & 4. Image Center Justification, Italic Taglines & Margin Scaling ---
      \usepackage{graphicx}
      \usepackage{caption}
      \captionsetup[figure]{font=it,justification=centering,singlelinecheck=false}
      \let\Oldincludegraphics\includegraphics
      \renewcommand{\includegraphics}[2][]{%
        \begin{center}
          \Oldincludegraphics[width=0.95\textwidth,keepaspectratio]{#2}%
        \end{center}
      }
EOF
      ) \
      -o "${BOOK_FILENAME}.pdf"
      echo "PDF compilation complete: ${BOOK_FILENAME}.pdf"
fi

# --- Step 4: Compile Editable Word Document (.docx) ---
if [[ "$OUTPUT_FORMAT" == "all" || "$OUTPUT_FORMAT" == "docx" ]]; then
    echo "=== [Step 4/8] Compiling Word Document (.docx) ==="
    pandoc "${INPUT_FILES[@]}" --toc -o "${BOOK_FILENAME}.docx"
    echo "DOCX compilation complete: ${BOOK_FILENAME}.docx"
fi

# --- Step 5: Compile eBook (.epub) ---
if [[ "$OUTPUT_FORMAT" == "all" || "$OUTPUT_FORMAT" == "epub" ]]; then
    echo "=== [Step 5/8] Compiling eBook (.epub) ==="
    pandoc "${INPUT_FILES[@]}" --toc -o "${BOOK_FILENAME}.epub"
    echo "EPUB compilation complete: ${BOOK_FILENAME}.epub"
fi

# --- Step 6: Generate Build Report & Metrics ---
echo "=== [Step 6/8] Generating Build Metrics Report ==="
WORD_COUNT=$(cat "${INPUT_FILES[@]}" | wc -w)
PAGE_COUNT="N/A"
if [ -f "${BOOK_FILENAME}.pdf" ]; then
    PAGE_COUNT=$(pdfinfo "${BOOK_FILENAME}.pdf" | grep -i "Pages:" | awk '{print $2}')
fi

cat <<EOF > build_report.txt
==============================================================================
KDP Publication Build Metrics Report
==============================================================================
Book Title    : ${BOOK_TITLE}
Build Profile : ${PROFILE}
Total Words   : ${WORD_COUNT}
PDF Page Count: ${PAGE_COUNT}
Generated Files:
  - PDF  : ${BOOK_FILENAME}.pdf
  - DOCX : ${BOOK_FILENAME}.docx
  - EPUB : ${BOOK_FILENAME}.epub
  - TOC  : TOC.md
==============================================================================
EOF

echo "Build report saved to build_report.txt."
echo "=== [Step 8/8] Build Finished Successfully ==="
