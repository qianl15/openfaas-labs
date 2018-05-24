import requests
import random

def handle(req):
    """handle a request to the function
    Args:
        req (str): request body
    """
    r = requests.get("http://api.open-notify.org/astros.json")
    result = r.json()
    index = random.randint(0, len(result["people"]) - 1)
    name = result["people"][index]["name"]

    return "{} is in space".format(name)
