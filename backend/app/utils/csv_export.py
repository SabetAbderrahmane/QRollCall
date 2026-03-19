# backend/app/utils/csv_export.py
from pathlib import Path


def escape_csv_value(value: str) -> str:
    cleaned = value.replace('"', '""')
    return f'"{cleaned}"'


def write_csv_file(
    file_path: str | Path,
    headers: list[str],
    rows: list[list[str]],
) -> str:
    target_path = Path(file_path)
    target_path.parent.mkdir(parents=True, exist_ok=True)

    lines = [",".join(headers)]
    for row in rows:
        escaped_row = [escape_csv_value(value) for value in row]
        lines.append(",".join(escaped_row))

    target_path.write_text("\n".join(lines), encoding="utf-8")
    return str(target_path).replace("\\", "/")
