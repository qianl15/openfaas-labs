import sys
import yaml

document = """
  a: 1
  b:
    c: 3
    d: 4
"""

def main(context):
    return yaml.dump(yaml.load(document))

if __name__ == "__main__":
    res = main("abc")
    print res
