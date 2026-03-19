# backend/app/utils/pdf_export.py
from pathlib import Path


def pdf_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def write_simple_pdf(
    file_path: str | Path,
    title: str,
    lines: list[str],
) -> str:
    target_path = Path(file_path)
    target_path.parent.mkdir(parents=True, exist_ok=True)

    safe_title = pdf_escape(title)
    safe_lines = [pdf_escape(line) for line in lines]

    content_lines = ["BT", "/F1 18 Tf", "50 780 Td", f"({safe_title}) Tj"]
    y_offset = 0

    for line in safe_lines:
        y_offset -= 24
        content_lines.extend(["/F1 12 Tf", f"0 {y_offset} Td", f"({line}) Tj"])

    content_lines.append("ET")
    stream_content = "\n".join(content_lines).encode("latin-1", errors="replace")

    objects: list[bytes] = []
    objects.append(b"1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n")
    objects.append(b"2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n")
    objects.append(
        b"3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
        b"/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj\n"
    )
    objects.append(
        b"4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n"
    )
    objects.append(
        f"5 0 obj << /Length {len(stream_content)} >> stream\n".encode("latin-1")
        + stream_content
        + b"\nendstream endobj\n"
    )

    pdf = bytearray(b"%PDF-1.4\n")
    offsets = [0]

    for obj in objects:
        offsets.append(len(pdf))
        pdf.extend(obj)

    xref_offset = len(pdf)
    pdf.extend(f"xref\n0 {len(objects) + 1}\n".encode("latin-1"))
    pdf.extend(b"0000000000 65535 f \n")

    for offset in offsets[1:]:
        pdf.extend(f"{offset:010d} 00000 n \n".encode("latin-1"))

    pdf.extend(
        (
            f"trailer << /Size {len(objects) + 1} /Root 1 0 R >>\n"
            f"startxref\n{xref_offset}\n%%EOF"
        ).encode("latin-1")
    )

    target_path.write_bytes(pdf)
    return str(target_path).replace("\\", "/")
