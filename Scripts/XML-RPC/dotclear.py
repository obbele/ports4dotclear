#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright 2010 John Obbele
#
#               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                        Version 2, December 2004
#
# Copyright (C) 2004
# Sam Hocevar 14 rue de Plaisance, 75014 Paris, France
# Everyone is permitted to copy and distribute verbatim or modified
# copies of this license document, and changing it is allowed as long as
# the name is changed.
#
#               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#   0. You just DO WHAT THE FUCK YOU WANT TO.


"""
Remotely manage DotClear2 posts from the CLI.

Using a small configuration file (which default to default.cfg), list,
create, modify or delete blog posts. If the configuration file set a
text editor name, it will be used to edit the content of the post.

For more information on MovableType API, see
http://www.sixapart.com/developers/xmlrpc/
"""

import xmlrpclib, xml.dom.minidom
import ConfigParser, datetime, getpass
from optparse import OptionParser
import tempfile, os, os.path, sys

CFG_DEFAULT = "default.cfg"
BALISE = u"<!-- {0} EXCERPT SEPARATOR {1} -->".format(":"*22, ":"*22)
XHTML_TEMPLATE = u"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>XML-RPC post preview</title>
    <style type="text/css">
        body {{
            width : 57em;
            margin : 1em auto;
            color : #111;
            background : #eee;
        }}
        pre {{
            margin : 0 8em;
            padding : 0.5em 2em;
            background : #ddd;
        }}
    </style>
</head>
<body>
{0}
</body>
</html>
"""

def error(msg):
    print >>sys.stderr, "Error: "+msg

def display_XMLRPC_errors(msg, fault):
    error(("Fail to " + msg + "\n"+\
          "error code = {0}\n"+\
          "error message = {1}\n").format(fault.faultCode,
                                          fault.faultString))

def wrap_with_template(input):
    return XHTML_TEMPLATE.format(input)

def find_config_file(filename):
    if os.path.exists( filename) :
        return filename
    if os.path.exists( filename + ".cfg") :
        return filename + ".cfg"

    # Search in script folder
    progname = sys.argv[0]
    basedir = os.path.dirname( progname)
    filename2 = os.path.join( basedir, filename)

    if os.path.exists( filename2) :
        return filename2
    if os.path.exists( filename2 + ".cfg") :
        return filename2 + ".cfg"

    # Otherwise, we are screwed
    raise IOError("cannot find configuration file")

class MyBlog():
    def __init__(self, config_file):
        """ Read the  configuration file
            and create a xmlrpclib """

        config_file = find_config_file( config_file)
        config = ConfigParser.ConfigParser()
        config.read(config_file)

        # Handy preferences
        self.editor = os.environ.get('EDITOR')
        if not self.editor :
            self.editor = "/bin/vi"

        try:
            self.https_warning = not config.getboolean(
                'Common',
                'disable_https_warning')
        except (ConfigParser.NoSectionError, ConfigParser.NoOptionError):
            self.https_warning = False

        try:
            self.auto_publish = config.getboolean('Common', 'publish')
        except (ConfigParser.NoSectionError, ConfigParser.NoOptionError):
            self.auto_publish = False

        try:
            self.auto_comments = config.getboolean('Common', 'comments')
        except (ConfigParser.NoSectionError, ConfigParser.NoOptionError):
            self.auto_comments = False

        try:
            self.auto_pings = config.getboolean('Common', 'pings')
        except (ConfigParser.NoSectionError, ConfigParser.NoOptionError):
            self.auto_pings = False

        # Blog configuration
        try :
            self.blogid = config.get('Blog', "blogid")
        except ConfigParser.NoSectionError as e:
            error("config file is ill-formatted !\n-->{0}\n".format(e))

        self.url = config.get('Blog', "url")
        if (self.https_warning and self.url[0:5] != "https"):
            error("URL is not secured\nUse https instead of http\n")

        self.username = config.get('Blog', "username")
        try :
            self.password = config.get('Blog', "password")
        except ConfigParser.NoOptionError:
            self.password = getpass.getpass(
                "Please enter your password for %s:\n" % self.url)

        try :
            self.server = xmlrpclib.Server( self.url )
        except xmlrpclib.Fault as fault:
            display_XMLRPC_errors("connect to server", fault)

        print "Using XML-RPC connection to", self.url 

    def _selectCategories(self):
        "return an array of struct with categoryId and isPrimary fields"

        categories = self.server.mt.getCategoryList(
            self.blogid, self.username, self.password)

        for i,c in enumerate(categories):
            print i,c['description']
        r = None
        while (r == None) :
            try :
                choice = int(raw_input("categorie number ?\n"))
                if (choice < len(categories)) and ( choice >= 0 ):
                    r = [{'categoryId':categories[choice]['categoryId']}]
                else :
                    error("Out of bound !")
            except ValueError:
                error("Not a integer !")
        return r

    def _setCategorie(self, postid):
        categories = self._selectCategories()
        try :
            self.server.mt.setPostCategories(
                postid,
                self.username, self.password,
                categories
            )
        except xmlrpclib.Fault as fault:
            display_XMLRPC_errors("set category", fault)

    def _externalEditor(self,prev_content):
        """
        Dump existing content to a temporary file and open it for
        modification with self.editor.
        Check XML syntax too.
        """
        f, filename = tempfile.mkstemp()
        fd = os.fdopen(f, 'wb')
        fd.write(prev_content.encode("utf-8"))
        fd.close()

        # Looping on "data" until we get well-formatted XML
        valid_xml = False
        text = ""
        while not valid_xml:
            try :
                raw_input("Launching external text editor." +
                          "Press enter to continue")
                os.system(self.editor + " " +filename)

                #Retrieve edited text
                with open(filename, 'rb') as f:
                    text = f.read()

                # Parse our XHTML file
                doc = xml.dom.minidom.parseString(text)
                text = doc.getElementsByTagName("body")[0].toxml()
                text = text.replace("<body>", "").replace("</body>", "")

                #All is fine, break loop
                valid_xml = True

            except xml.parsers.expat.ExpatError as err:
                error("Not valid XML\n{0}\n"+\
                      "Please, try again".format(err))
            except Exception as err :
                error("Unknown error while parsing XML\n"+\
                      "error type = {0}\n"+\
                      "error display = {1}\n"+\
                      "Please, try again".format(type(err), err))

        os.unlink(filename)
        return text

    def listLastPosts(self, number):
        """
        List the last `number` posts
        """

        try :
            entries = self.server.mt.getRecentPostTitles(
                 self.blogid, self.username,
                 self.password, number)

            for e in entries :
                if ("categories" in e) :
                    category = e['categories'][0]
                else :
                    category = 'nil'
                print "{0} :: {1} in cat. {2} (tags: {3})".format(
                    e['postid'],
                    e['title'],
                    category,
                    e['mt_keywords'])

        except xmlrpclib.Fault as fault:
            display_XMLRPC_errors("get list of recent posts", fault)

        print # add a blank line

    def showPost(self, id):
        """
        Print the raw content (xHTML) of post `id`
        """
        post = self._extractPost(id)
        date = datetime.datetime.strptime(post['dateCreated'].value,
                                          "%Y%m%dT%H:%M:%S")

        print "-" * 79
        print "[ {0} ] === {1} ===".format(post['postid'],
                                           post['title'])
        if 'categories' in post :
            print "By {0} on {1} - {2}".format( post['userid']
                                              , date.ctime()
                                              , post['categories'][0])
        else :
            print "By {0} on {1}".format(post['userid'], date.ctime())

        print "( tags: {0} )".format(post['mt_keywords'])
        print 
        print post['formatted_text']
        print 
        print "Link:", post['link']
        print "permaLink:", post['permaLink']
        print "-" * 79

    def _fillPost(self, useRawHTML, old_data=None):
        # Initialize empty dictionnary ct (aka content)
        # to send through self.server.metaWeblog.newPost(
        ct = {}

        # if no old_data, create a fake one
        if old_data == None:
            old_data = { 'title': None
                       , 'mt_keywords': None
                       , 'formatted_text': BALISE
                       , 'mt_excerpt': None
                       , 'mt_description': None}

        def updateField(prompt, string=None):
            if (string == None) or (string == "") :
                return raw_input(prompt)
            else :
                r = raw_input(prompt + " [default:" + string + "]\n")
                if r == "" :
                    return string
                else :
                    return r

        # Now get information
        ct['title'] = updateField( "Title?\n", old_data['title'])
        ct['mt_keywords'] = updateField(
           "Tags? (comma separated lists)?\n",
            old_data['mt_keywords'])

        # Categories are not included in the struct "ct"
        # see _setCategorie()

        # Get excerpt/ct
        # Method0: stdin
        if useRawHTML:
            with open( useRawHTML, 'rb') as f:
                data = f.read()
            # Parse our XHTML file
            doc = xml.dom.minidom.parseString(data)
            text = doc.getElementsByTagName("body")[0].toxml("utf-8")
            #text = text.decode() # convert bytes to string
            text = text.replace("<body>", "").replace("</body>", "")
            ct['mt_excerpt'], ct['description'] = text.split(BALISE)

        # Method1: custom editor
        elif self.editor :
            prev_data = old_data['formatted_text']
            data = self._externalEditor( wrap_with_template(prev_data) )
            # if no ct before balise, Python
            # s.split throw an exception
            if data.find(BALISE) == 1 :
                ct['description'] = data[len(BALISE):]
            else :
                ct['mt_excerpt'], ct['description'] = data.split(BALISE)

        # Method2: input
        else :
            ct['mt_excerpt'] = updateField(
                "Excerpt? (beware of xHTML tags !)\n",
                old_data['mt_excerpt'])
            ct['description'] = updateField(
                "Main ct? (beware of xHTML tags !)\n",
                old_data['description'])

        # Process the rest of the attributes (comments, pings, ...)
        def set_boolean( prompt, default):
            if default == True:
                return raw_input(prompt + "[Y|n]") != "n"
            else:
                return raw_input(prompt + "[y|N]") != "y"

        ct['mt_allow_comments'] = set_boolean( "Allow comments ?"
                                             , self.auto_comments)
        ct['mt_allow_pings'] = set_boolean( "Allow pings ?"
                                          , self.auto_pings)
        publish = set_boolean( "Publish ?" , self.auto_publish)

        return ct, publish

    def newPost(self, useRawHTML):
        """ Create a post from scratch. """
        print 
        content, publish = self._fillPost(useRawHTML)

        # Upload to server
        try :
            postid = self.server.metaWeblog.newPost(
                self.blogid, self.username, self.password,
                content, publish
            )
        except xmlrpclib.Fault as fault:
            display_XMLRPC_errors("post the new entry", fault)
        else :
            self._setCategorie(postid)
            print "New post created with ID =", postid

    def editPost(self, id, useRawHTML):
        """ Modify post given its ID. """
        old_data = self._extractPost(id)
        print 
        content, publish = self._fillPost(useRawHTML, old_data)

        # Upload to server
        try :
            self.server.metaWeblog.editPost(
                id, self.username, self.password,
                content, publish
            )
            if raw_input("Change category ?[y|N] ") == "y" :
                self._setCategorie(id)
        except xmlrpclib.Fault as fault:
            display_XMLRPC_errors("edit entry", fault)

    def deletePost(self, postid):
        #N.B. the first value ('appkey') is ignored
        # the fourth value is a boolean named 'Publish' and I cannot
        # figure it out its use
        try :
            self.server.blogger.deletePost(
                "appkey", postid, self.username, self.password, True)
        except xmlrpclib.Fault as fault:
            display_XMLRPC_errors("delete post", fault)

    def _extractPost(self, id):
        """ Return post content. """
        try :
            data =  self.server.metaWeblog.getPost(
                id, self.username, self.password
            )
            data['formatted_text'] = "\t" + data['mt_excerpt'] +\
                                        "\n\t" + BALISE + "\n\t" +\
                                        data['description']
        except xmlrpclib.Fault as fault:
            display_XMLRPC_errors("get post content", fault)

        return data

    def printPost(self, id):
        """ Print post content to STDOUT. """
        print self._extractPost(id)['formatted_text']

    def uploadFile(self, filename, name="Dummy name", type="DummyType"):
        """Upload any type of file to the server

        If not given, name defaults to 'filename'.
        The 'type' variable doesn't seem to be used.
        """

        with open(filename, 'rb') as f:
            data = f.read()

        if (name == "Dummy name"):
            name = filename

        data = {'name': name,
                'type': type,
                'bits': xmlrpclib.Binary(data),
                'overwrite': True}

        try:
            r = self.server.wp.uploadFile(
                    self.blogid, self.username, self.password, data)
        except xmlrpclib.Fault as fault:
            display_XMLRPC_errors("upload file " + filename, fault)

        #FIXME: do we really need to split the url ?
        try:
            r['url'] = r['url'].split('?')[1]
        except IndexError:
            from urlparse import urlparse
            r['url'] = urlparse(r['url']).path

        print "uploaded file file =", r['file']
        print "uploaded file url =", r['url']
        print "uploaded file type =", r['type']

if __name__ == '__main__':
    parser = OptionParser()
    parser.add_option("-c", "--conf",
                      action="store", dest="configfile",
                      default=CFG_DEFAULT, metavar="FILE",
                      help="Read configuration from filename "
                           "[default: %default]")
    parser.add_option("-l", "--list",
                      action="store", dest="list",
                      metavar="N",
                      help="List the last N posts")
    parser.add_option("-n", "--new",
                      action="store_true", dest="new",
                      help="Create a new entry")
    parser.add_option("-s", "--show",
                      action="store", dest="show",
                      metavar="ID",
                      help="Show post given its ID")
    parser.add_option("-x", "--extract",
                      action="store", dest="extract",
                      metavar="ID",
                      help="Print to stdout the content of post ID")
    parser.add_option("-e", "--edit",
                      action="store", dest="edit",
                      metavar="ID",
                      help="Edit a post given its ID "
                      "using your favorite $EDITOR")
    parser.add_option("-d", "--delete",
                      action="store", dest="delete",
                      metavar="ID",
                      help="Delete an entry")
    parser.add_option("-w", "--wrap",
                      action="store_true", dest="wrap",
                      help="Read stdin and wrap it inside internal\
                      XHTML template")
    parser.add_option("-r", "--raw",
                      action="store", dest="raw",
                      metavar="FILE",
                      help="Do not wrap HTML code with headers")
    parser.add_option("-u", "--upload",
                      action="store", dest="upload_file",
                      metavar="FILE",
                      help="Upload a file to the server")

    (options, args) = parser.parse_args()

    # Check if we can work withtout XML-RPC connection
    if options.wrap:
        # Due to some serious pitfalls in python Unicode support
        # for stdin and stdout, trying to use a clever trick
        # for more information, see:
        #     http://wiki.python.org/moin/PrintFails
        import locale
        enc = locale.getpreferredencoding()

        input = sys.stdin.read()

        # Before processing data in Python, decode them
        uinput = input.decode(enc)

        output = wrap_with_template( uinput)

        # Before outputing data, re-encode them for the pipe
        output = output.encode(enc)

        print output
        exit(0)

    # All remaining options need a XML-RPC connection
    # instanciate it through a MyBlog object
    myblog = MyBlog(options.configfile)

    if options.upload_file:
        myblog.uploadFile( options.upload_file)
    if options.list :
        myblog.listLastPosts(options.list)
    if options.new :
        myblog.newPost(options.raw)
    if options.show :
        myblog.showPost(options.show)
    if options.extract :
        myblog.printPost(options.extract)
    if options.edit :
        myblog.editPost(options.edit, options.raw)
    if options.delete :
        myblog.deletePost(options.delete)

    sys.exit(0);
