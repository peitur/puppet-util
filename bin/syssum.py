#!/usr/bin/python3

#from pathlib import Path
import re
import os

ROOTPATH = "/proc"
STATFILE = "stat"
STATUSFILE = "status"

EXECSTATE = {
 'R': "running",
 'S': "sleeping", 
 'D': "disk sleep", 
 'T': "stopped", 
 'T': "tracing stop", 
 'Z': "zombie",
 'X': "dead"	
}

def is_daemon( pid ):
	filename = ROOTPATH+"/"+pid+"/"+STATFILE
	try:
		fd = open( filename, "r" )

		line = fd.readline()

		fd.close()

		elements = line.split()
		if( elements[3] == "1" ):
			return True

		return False

	except Exception as error:
		raise

	return False


def list_processes( path ):

	pre = re.compile('[0-9]+')
	proclist = []

	try:
#		path = Path( path )
#		for x in path.iterdir():
#			xs = x.name
		
		for xs in os.listdir( path ):

			if pre.match( xs ):
				proclist.append( xs )

		return proclist

	except Exception as error:
		raise

	return None

def list_ppid( path, ppid ):

	processlist = list_processes( path )

	result = []
	for pid in processlist:
		filename = path+"/"+pid+"/"+STATFILE

		try:
			fd = open( filename, "r" )
			line = fd.readline()
			fd.close()

			elements = line.split()
			if( elements[3] == str( ppid ) ):
				result.append( pid )			


		except Exception as error:
			raise


	return result



def process_info_stat( pid ):
	filename = ROOTPATH+"/"+pid+"/"+STATFILE

	try:
		fd = open( filename, "r" )
		line = fd.readline().strip()
		fd.close()

		info = line.split()
		info[1] = info[1].strip('()')

		return info

	except Exception as error:
		raise

	return None


def process_info_status( pid ):
	filename = ROOTPATH+"/"+pid+"/"+STATUSFILE

	info = {}

	try:
		fd = open( filename, "r" )
		for line in fd:
			if re.match( r'^Pid:', line ): info['pid'] = line.strip().split()[1]
			if re.match( r'^PPid:', line ): info['ppid'] = line.strip().split()[1]
			if re.match( r'^Name:', line ): info['name'] = line.strip().split()[1]
			if re.match( r'^Threads:', line ): info['threads'] = line.strip().split()[1]
			if re.match( r'^VmSize:', line ): info['size'] = line.strip().split()[1]
			if re.match( r'^VmPeak:', line ): info['peak'] = line.strip().split()[1]
			if re.match( r'^VmLib:', line ): info['csize'] = line.strip().split()[1]
			if re.match( r'^VmSwap:', line ): info['swaped'] = line.strip().split()[1]
			if re.match( r'^State:', line ): info['state'] = EXECSTATE[ line.strip().split()[1] ]

		return info

	except Exception as error:
		raise

	return None


def process_info( pid ):
	return process_info_status( pid )

def filter_process( name, value, daemon = False ):

	result = []
	try:

		if daemon:
			processlist = list_ppid( ROOTPATH, "1")
		else:
			processlist = list_processes( ROOTPATH )


		for p in processlist:
			info = process_info( p )

			if name in info: 
				if( isinstance( value, int ) ):
					if( int( info[name] ) >= value ): 
						result.append( info )
				else:
					if( info[name] == value ):
						result.append( info ) 

		return result
	except Exception as error:
		raise

	return result


############################################################################

plist = list_processes( ROOTPATH )
dlist = []
for p in plist:
	if( is_daemon( p ) ): 
		dlist.append( p )


print("Found %(plist_len)i processes of which %(dlist_len)i are daemons" % { 'plist_len':len(plist), 'dlist_len': len( dlist ) })
print("Local daemons are:")
#for d in dlist:
#	print( "%(pid)5s > %(process_info)s " % {'pid': d, 'process_info': process_info_stat( d )[1] } )
#	print( "\t > %(cpid)s " % {'cpid': list_ppid( ROOTPATH, d ) } )

for d in dlist:
	info = process_info( d )
	print("inf: %(info)s" % { 'info': info.__str__() })
	print("%(pid)s > %(name)s S: %(state)s" % {'pid': d , 'name': info['name'], 'state': info['state'] })
	print( "\t > %(cpid)s " % {'cpid': list_ppid( ROOTPATH, d ) } )


print("1F: %(info)s" % { 'info': filter_process( 'state', 'running') })
print("2F: %(info)s" % { 'info': filter_process( 'threads', 5 ) })
print("3F: %(info)s" % { 'info': filter_process( 'name', 'smbd') })
print("4F: %(info)s" % { 'info': filter_process( 'swaped', 1 ) })
print("5F: %(info)s" % { 'info': filter_process( 'size', 500000 ) })
print("6F: %(info)s" % { 'info': filter_process( 'name', 'smbd', True ) })

if isinstance( 10, int ): print("1Number")
if isinstance( "10", int ): print("2Number")
if isinstance( "10", str ): print("2String")
if isinstance( "10", str ): print("3String")

#print( int("123"))
#print( int("abc")) throws exception
