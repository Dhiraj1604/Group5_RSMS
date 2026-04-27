import sys

def check_braces(filename):
    with open(filename, 'r') as f:
        lines = f.readlines()
        count = 0
        for i, line in enumerate(lines):
            for char in line:
                if char == '{':
                    count += 1
                elif char == '}':
                    count -= 1
            print(f"{i+1}: {count} | {line.strip()}")

check_braces(sys.argv[1])
