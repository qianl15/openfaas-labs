import sys
from flask import request
from flask import current_app

import numpy as np

# Python env doesn't pass in an argument
# we can get request data by request.headers, request.get_data()
def main():
    current_app.logger.info("Received request")
    msg = '---HEADERS---\n{}\n--BODY--\n{}\n-----\n'.format(request.headers, request.get_data())

    x = np.array(([1,2,3],[4,5,6],[7,8,9]))
    y = np.array(([.1,.2,.3],[.4,.5,.6],[.7,.8,.9]))
    z = np.matmul(x,y)
    zz = np.array2string(z)

    msg2 = '--RESULT--\n{}\n-----\n'.format(zz)
    msg += msg2

    current_app.logger.info(msg)

    # You can return any http status code you like, simply place a comma after
    # your return statement, and typing in the status code.
    return msg, 200

