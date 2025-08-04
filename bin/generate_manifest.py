#!/usr/bin/env python3
import os,sys,time,re

if __name__ == '__main__' :
	app_name=os.env  ['APP_NAME']
	container = os.env['CONTAINER']
	service = os.env ['SERVICE']
	url = os.env ('URL' ,'')
	public = os.env.get('PUBLIC','False')
	manifest='''
#@data/values

---
service: %s
container: %s
url: %s
port: 8080
	'''
	print (manifest %(service , container , url))