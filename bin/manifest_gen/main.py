#!/usr/bin/env python3
import os

if __name__ == '__main__':
    app_name = os.environ.get('APP_NAME')
    container = os.environ.get('CONTAINER')
    service = os.environ.get('SERVICE')
    url = os.environ.get('URL', '')
    public = os.environ.get('PUBLIC', 'False')
    manifest = '''
#@data/values

---
service: %s
container: %s
url: %s
port: 8080
	'''
    print(manifest % (service, container, url))
