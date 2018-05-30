import sys
import yaml

document = """
  a: 1
  b:
    c: 3
    d: 4
"""

# Python env doesn't pass in an argument
def main():
    return yaml.dump(yaml.load(document))

if __name__ == "__main__":
    res = main()
    print(res)
