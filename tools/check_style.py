import ast
import io
import re
import subprocess
import tokenize
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DART_TOKENS = re.compile(
    r"(?P<string>r?(?:\"\"\"[\s\S]*?\"\"\"|'{3}[\s\S]*?'{3}|"
    r"\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*'))"
    r"|(?P<block>/\*[\s\S]*?\*/)|(?P<line>//[^\r\n]*)"
)


def word_count(text):
    return len(re.findall(r"\b[\w'-]+\b", text))


def violations(source, suffix):
    errors = []
    comments = []
    if suffix == ".py":
        tree = ast.parse(source)
        for node in ast.walk(tree):
            if isinstance(
                node, (ast.Module, ast.ClassDef, ast.FunctionDef, ast.AsyncFunctionDef)
            ):
                doc = ast.get_docstring(node, clean=False)
                if doc and word_count(doc) > 45:
                    errors.append(
                        f"line {node.body[0].lineno}: docstring exceeds 45 words"
                    )
        for token in tokenize.generate_tokens(io.StringIO(source).readline):
            if token.type == tokenize.COMMENT:
                comments.append((token.start[0], token.end[0], token.string))
    elif suffix == ".dart":
        for match in DART_TOKENS.finditer(source):
            if match.lastgroup == "string":
                continue
            first = source.count("\n", 0, match.start()) + 1
            last = first + match.group().count("\n")
            comments.append((first, last, match.group()))
    else:
        for number, line in enumerate(source.splitlines(), 1):
            if line.lstrip().startswith("#"):
                comments.append((number, number, line))
    block = []
    end = -2
    first = 0
    for start, stop, text in comments + [(len(source.splitlines()) + 2, 0, "")]:
        if start > end + 1:
            if word_count("\n".join(block)) > 25:
                errors.append(f"line {first}: comment block exceeds 25 words")
            block = []
            first = start
        block.append(text)
        end = stop
    return errors


def main():
    paths = (
        subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
        .decode()
        .split("\0")
    )
    errors = []
    for name in filter(None, paths):
        path = ROOT / name
        if path.suffix in {".py", ".dart", ".yml", ".yaml", ".toml"}:
            errors.extend(
                f"{name}: {error}"
                for error in violations(path.read_text(), path.suffix)
            )
    if errors:
        raise SystemExit("\n".join(errors))
    print("Comment and docstring limits passed")


if __name__ == "__main__":
    main()
