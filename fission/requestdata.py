import sys
from flask import request
from flask import current_app

# Python env doesn't pass in an argument
# we can get request data by request.headers, request.get_data()
def main():
    current_app.logger.info("Received request")
    msg = '---HEADERS---\n{}\n--BODY--\n{}\n-----\n'.format(request.headers, request.get_data())
    current_app.logger.info(msg)

    # You can return any http status code you like, simply place a comma after
    # your return statement, and typing in the status code.
    return msg, 200

