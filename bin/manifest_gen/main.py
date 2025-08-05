#!/usr/bin/env python3
import os

container = os.environ.get('CONTAINER')
service = os.environ.get('SERVICE')
url = os.environ.get('URL', '')
public = (os.environ.get('PUBLIC', 'False')).lower() == 'true'
port = os.environ.get('PORT')
ns=os.environ.get('NS','default')

def empty(v: str) -> bool:
    return v is None or v == ''


manifest = '''
#@data/values

---
prefix: %s
service: %s
container: %s
'''
args = [ns, service, container]

if public and not empty(url):
    if empty(port):
        port = '8080'
    manifest = '''
#@data/values

---
prefix: %s
service: %s
container: %s
url: %s
port: %s
        '''
    args = [ns,service, container, url, port]

print(manifest.strip() % tuple(args))