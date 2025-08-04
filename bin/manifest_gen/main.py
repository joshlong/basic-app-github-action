#!/usr/bin/env python3
import os

if __name__ == '__main__':
    container = os.environ.get('CONTAINER')
    service = os.environ.get('SERVICE')
    url = os.environ.get('URL', '')
    public = os.environ.get('PUBLIC', 'False')
    port = os.environ.get('PORT')


    def empty(v: str) -> bool:
        return v is None or v == ''


    if empty(url):
        if empty(port):
            port = '8080'

        manifest = '''
#@data/values

---
service: %s
container: %s
url: %s
port: 8080
        '''
    else:
        manifest = '''
#@data/values

---
service: %s
container: %s
	'''
    print(manifest % (service, container, url))
