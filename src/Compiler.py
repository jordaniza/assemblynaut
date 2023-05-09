# Super simple bytecode compiler for EVM opcodes
# This compiler:
# Parses all lines in the passed file
# Removes all comments and empty lines
# Concatenates all remaining lines into a single string
# Writes the string to the destination test file


class Compiler:
    """
    Simple builder pattern compiler to remove whitespace and comments from a file
    """

    lines: list[str]

    def __init__(self, file):
        with open(file) as f:
            self.lines = f.readlines()

    def remove_whitespace(self):
        self.lines = [line.strip() for line in self.lines]
        self.lines = [line.replace(" ", "") for line in self.lines]
        return self

    def remove_comments(self):
        lines = []
        for line in self.lines:
            if "//" not in line:
                lines.append(line)
            else:
                lines.append(line.split("//")[0])
        self.lines = lines
        return self

    def remove_empty_lines(self):
        self.lines = [line for line in self.lines if line]
        return self

    def compile(self):
        return "".join(self.lines)


def is_identifier(line: str):
    identifier = "bytes solverBytecode"
    return identifier in line


def inject_bytecode(line: str, bytecode: str):
    return f'{line.split("hex")[0]}hex"{bytecode}";\n'


def write_bytecode(bytecode: str):
    with open("test/MagicNum.t.sol", "r+") as sol:
        lines = sol.readlines()
        bytecode_index = next(
            (i for i, line in enumerate(lines) if is_identifier(line)), None
        )
        if bytecode_index is None:
            # identifier not found in file
            return
        lines[bytecode_index] = inject_bytecode(lines[bytecode_index], compiled)
        # move the file pointer to the beginning of the file
        sol.seek(0)
        # write the modified lines back to the file
        sol.writelines(lines)
        # truncate the file in case the new contents are shorter than the old contents
        sol.truncate()


compiled = (
    Compiler("test/MagicNumSolver")
    .remove_empty_lines()
    .remove_comments()
    .remove_whitespace()
    .compile()
)

write_bytecode(compiled)
