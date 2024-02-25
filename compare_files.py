import sys

# ANSI escape code for red color
RED = "\033[91m"
# ANSI escape code for reset color
RESET = "\033[0m"
def read_field_names(file):
    # Read the second line of the file and split it by '|'
    with open(file, 'r') as f:
        field_line = f.readlines()[1]
    return [field.strip() for field in field_line.split('|')]


def compare_files(file1, file2):
    # Read field names from both files
    field_names1 = read_field_names(file1)
    field_names2 = read_field_names(file2)

    # Read table data from both files
    with open(file1, 'r') as f1, open(file2, 'r') as f2:
        next(f1)  # Skip the first two lines (header and field names)
        next(f2)
        for line1, line2 in zip(f1, f2):
            fields1 = [field.strip() for field in line1.split('|')]
            fields2 = [field.strip() for field in line2.split('|')]

            # Compare corresponding fields
            for i, (field1, field2) in enumerate(zip(fields1, fields2)):
                if field1 != field2:
                    print(f"----------------------------------------------------------------")
                    print(f"{RED}Error: Mismatch in '{field_names1[i]}' {RESET}")
                    print(f"{file1} : {field1}")
                    print(f"{file2} : {field2}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python compare_files.py file1 file2")
        sys.exit(1)

    file1 = sys.argv[1]
    file2 = sys.argv[2]
    compare_files(file1, file2)
