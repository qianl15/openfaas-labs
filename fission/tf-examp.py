import sys
from flask import request
from flask import current_app

import numpy as np
import tensorflow as tf

# Python env doesn't pass in an argument
# we can get request data by request.headers, request.get_data()
def main():
    current_app.logger.info("Received request")
    msg = '---HEADERS---\n{}\n--BODY--\n{}\n-----\n'.format(request.headers, request.get_data())

    x = int(request.get_data())
    y = 3
    add_op = tf.add(x, y)
    mul_op = tf.multiply(x, y)
    useless = tf.multiply(x, add_op)
    pow_op = tf.pow(add_op, mul_op)
    with tf.Session() as sess:
      z = sess.run(pow_op)

    zz = str(z)

    msg2 = '--RESULT--\n{}\n-----\n'.format(zz)
    msg += msg2

    current_app.logger.info(msg)

    # You can return any http status code you like, simply place a comma after
    # your return statement, and typing in the status code.
    return msg, 200

