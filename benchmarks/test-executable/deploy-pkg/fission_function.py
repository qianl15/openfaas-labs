import os
import sys
from flask import request
from flask import current_app
from executable import Executable

def main():
    current_app.logger.info("Received request")
    msg = '---HEADERS---\n{}\n--BODY--\n{}\n-----\n'.format(request.headers, request.get_data())
    current_app.logger.info(msg)
	
    # Get request body
    reqStr = request.get_data().decode("utf-8")
    current_app.logger.info(reqStr)

    # Call executable binary
    exe = Executable('bins/hello')
    result = exe.run(reqStr)
    current_app.logger.info('OUT: {}\nERR: {}\nRET: {}'.format(
        exe.stdout, exe.stderr, exe.returncode))

    return result, 200

if __name__ == "__main__":
    reqStr = "haha"
    exe = Executable('bins/hello')
    result = exe.run(reqStr)
    print('OUT: {}\nERR: {}\nRET: {}'.format(
        exe.stdout, exe.stderr, exe.returncode))
    print(result)


