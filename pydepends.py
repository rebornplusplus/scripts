#!/usr/bin/python3

# This script generates the list of python modules a certain python file
# or module is dependent on. It goes through the python source files
# (with .py extension) and parses the import statements. It currently
# parses the following two syntaxes:
#
#     import foo, bar.a.b as y, x.y.z
#     from foo import bar
#
# In the first syntax, it would consider foo, bar and x as dependencies.
# In the second syntax, it would consider foo as dependency.
#
# USAGE
# -----
#
#     pydepends.py [-h] [--source] path
#
#     Find python modules dependency.
#
#     positional arguments:
#     path        path of the python file or module
#
#     options:
#     -h, --help  show this help message and exit
#     --source    print source files
#
# EXAMPLES
# --------
#
#     pydepends.py --source /usr/lib/python3.10/xml/
#     pydepends.py pydepends.py

import argparse
import os
import pathlib


def find_word(s: str, word: str):
    words = s.split()
    for w in words:
        if w == word:
            return True
    return False


def starts_with_word(s: str, word: str):
    if not s.startswith(word):
        return False
    return len(s) > len(word) and s[len(word)].isspace()


def parse_deps(s: str):
    if s.startswith("."):
        return ""
    dep = s.split(".")[0].strip()
    if find_word(dep, "as"):
        return dep.split("as")[0].strip()
    return dep


def parse_line(line: str):
    deps = []
    sources = []
    #
    if starts_with_word(line, "import"):
        sources = line[6:].split(",")
    if starts_with_word(line, "from") and find_word(line, "import"):
        sources = line[4 : line.index("import")].split(",")
    #
    if sources != "":
        for source in sources:
            dep = parse_deps(source.strip())
            if dep != "":
                deps.append(dep)
    return sorted(set(deps))


def find_deps(filepath: str):
    deps = []
    with open(filepath) as file:
        for line in file:
            deps += parse_line(line.strip())
    return deps


def walk_recursive(path: str, depsource: dict):
    deps = []
    pobj = pathlib.Path(path)
    if pobj.is_file() and path.endswith(".py"):
        new_deps = find_deps(path)
        deps += new_deps
        if depsource != None:
            for d in new_deps:
                depsource[d] = path
    if pobj.is_dir():
        for entry in os.scandir(path):
            deps += walk_recursive(entry.path, depsource)
    return deps


def main():
    parser = argparse.ArgumentParser(description="Find python modules dependency.")
    parser.add_argument("--source", action="store_true", help="print source files")
    parser.add_argument("path", help="path of the python file or module")
    args = parser.parse_args()
    #
    if not pathlib.Path(args.path).exists():
        print("error: path does not exist")
        exit(1)
    #
    depsource = {}
    if not args.source:
        depsource = None
    deplist = walk_recursive(args.path, depsource)
    deps = sorted(set(deplist))
    #
    for dep in deps:
        if args.source:
            print("{0: <30}".format(dep), depsource[dep])
        else:
            print(dep)


if __name__ == "__main__":
    main()
