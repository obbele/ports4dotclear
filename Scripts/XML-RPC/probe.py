#!/usr/bin/python
# -*- coding: utf-8 -*-
# 2010-01-09
# © Copyright 2010 John Obbele. All Rights Reserved.
#
"""
Probe a XML-RPC server for a brief list of methods, including their
signature and a short description
ref: http://xmlrpc-c.sourceforge.net/introspection.html

See also, for API references:
http://www.sixapart.com/developers/xmlrpc/
and
http://infinite-sushi.com/2005/12/programmatic-interfaces-the-movabletype-xmlrpc-api/
"""

import xmlrpclib

def listMethods(s):
    for method in s.system.listMethods():
        print method
        print s.system.methodSignature(method)
        print s.system.methodHelp(method)
        print

if __name__ == '__main__':
    server = xmlrpclib.Server("http://myServer/dc2/index.php?xmlrpc/default")
    listMethods(server)
