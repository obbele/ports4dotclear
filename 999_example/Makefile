# Slave Makefile for managing a single message folder
#
# Please keep the part one, two and three of this file always in their
# original order.

# First part: modifying global variable, if needed
##################################################

# Define here additional files to process while creating XHTML document
# (use in target "make all" and its derivative "make view" and "make
# publish" )
# e.g.
# ADDITIONAL_FILES = Media/foobar
ADDITIONAL_FILES = Media/SVG.svg

# Second part: Now sourcing generic ../Scripts/Makefile.generic
###############################################################

include ../Scripts/Makefile.generic

# Thrid part: Defining additional targets
#########################################

# for instance, if any $(ADDITIONAL_FILES) was set:
# Media/foobar: foobar.src
# 	my_super_script <$^ >$@

Media/SVG.svg: Misc/SVG.svg
	$(SCRIPTS)/ResizeSVG.pl <$^ >$@
