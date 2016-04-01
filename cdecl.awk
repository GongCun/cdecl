#!/usr/bin/env awk -f
#
# The MIT License (MIT)
# 
# Copyright (c) 2016 Gong Cun <gong_cun@bocmacau.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

#==============================================================================
#
# This program expand the C declaration parser at the end of Chapter 5 in K&R's
# The C Programming Language, with function argument types, qualifiers like
# const, and so on.
# 
# Reference The C Answer Book, Second Edition, by Colvis L. Tondo and
# Scott E. Gimpel (Pearson Education), 0-13-109653-2 
#
# A description of the grammar is the following:
#
#   dcl:        optional *'s direct-dcl
#               optional qualifiers's direct-dcl
#
#   direct-dcl: name
#               (dcl)
#               direct-dcl(optional parm-dcl)
#               direct-dcl[optional size]
#
#   parm-dcl:   parm-dcl, dcl-spec dcl
#
#   dcl-spec:   type-spec dcl-spec
#               type-qual dcl-spec
#
#==============================================================================
      

#-+- Global variable -+-
# str, token, tokentype, out, datatype, i, name \
# prevtoken, i, j, k

function gettoken(  ch) {
    if (prevtoken == "YES") {
        prevtoken = "NO"
        return tokentype
    }
    while ((token = substr(str,i++,1)) == " ")
        ;
    if (token == "(") {
        if ((ch = substr(str,i++,1)) == ")") {
            token == "()"
            tokentype = "PARENS"
            if (DEBUG) printf(">>> token = %s; tokentype = %s <<<\n", token, tokentype)
            return tokentype
        } else {
            i--;
            tokentype = "("
            if (DEBUG) printf(">>> token = %s; tokentype = %s <<<\n", token, tokentype)
            return tokentype
        }
    } else if (token == "[") {
        while ((ch = substr(str, i++, 1)) != "]")
            token = token ch
        token = token ch
        tokentype = "BRACKETS"
        if (DEBUG) printf(">>> token = %s; tokentype = %s <<<\n", token, tokentype)
        return tokentype
    } else if (token ~ /[0-9a-zA-Z_\-]/) {
        while ((ch = substr(str, i++, 1)) ~ /[0-9a-zA-Z_\-]/)
            token = token ch
        i--
        tokentype = "NAME"
        if (DEBUG) printf(">>> token = %s; tokentype = %s <<<\n", token, tokentype)
        return tokentype
    } else
        tokentype = token
    if (DEBUG) printf(">>> token = %s; tokentype = %s <<<\n", token, tokentype)
    return tokentype
}

function dcl(  temp, stack, top) {
    if (DEBUG) print ">>> in dcl() <<<"
    for ( ; gettoken() == "*" || tokenqual() == "YES"; )
    	stack[++top] = token # start from 1
    dirdcl()
    while (top > 0) {
    	if ((temp = stack[top--]) == "*")
    		out = out "pointer to "
		else
			out = out temp " "
	}
}

function dirdcl(  type) {
    if (DEBUG) print ">>> in dirdcl() <<<"
    if (tokentype == "(") { # (dcl)
        dcl()
        if (tokentype != ")")
            printf("error: missing )\n")
    } else if (tokentype == "NAME") {
        if (length(name) == 0)
            name = token
    }
    else if (length(name) != 0)
        prevtoken = "YES"
    else
        printf("error: expected name or (dcl)\n");

    while ((type = gettoken()) == "PARENS" || type == "BRACKETS" || type == "(") {
        if (type == "PARENS")
            out = out "function returning "
        else if (type == "BRACKETS")
            out = out "array" token " of "
        else {
            out = out "function ("
            parmdcl()
            out = out ") returning "
        }
    }
}

function conn_blank(  str, element) {
    if (length(str) == 0)
        return str = element
    else
        return str = str " " element
}

function parmdcl() {
    if (DEBUG) print ">>> in parmdcl() <<<"
    do {
        dclspec()
    } while (tokentype == ",")
    if (tokentype != ")")
        printf("error: missing )\n")
}

function dclspec(  temp) {
   if (DEBUG) print ">>> in dclspec() <<<"
   gettoken()
   do { 
        for ( ; tokenspec() == "YES" || tokenqual() == "YES"; gettoken() )
            temp = conn_blank(temp, token)
        prevtoken = "YES"
        dcl()
    } while (length(tokentype) > 0 && tokentype != "," && tokentype != ")")
    out = out temp
    if (tokentype == ",")
        out = out ", "
}

function tokenspec() {
	for (idx in spec_array) {
		if (token == spec_array[idx])
			return "YES"
	}
	return "NO"
}

function tokenqual() {
    if (token == "const" || token == "volatile") 
        return "YES"
    else
        return "NO"
}

#-+- No use, but for future extention -+-
function tokenstorage() {
	if (token == "static" || token == "auto" || \
		token == "register" || token == "extern" || token == "typedef")
		return "YES"
	else
		return "NO"
}

BEGIN {
	spec_array[++j] = "char"
	spec_array[++j] = "int"
	spec_array[++j] = "void"
	spec_array[++j] = "short"
	spec_array[++j] = "long"
	spec_array[++j] = "float"
	spec_array[++j] = "double"
	spec_array[++j] = "signed"
	spec_array[++j] = "unsigned"
	for (i=1; i<ARGC; i++) {
		if (ARGV[i] == "-d") {
			DEBUG = 1
			delete ARGV[i]
		} else if (ARGV[i] != "-") {
			TYPEFILE = ARGV[i]
			while ((getline < TYPEFILE) > 0) {
                		for (k=1; k<=NF; k++)
                    		spec_array[++j] = $k # "struct name"
            		}
			delete ARGV[i]
		}
	}
	if (DEBUG)
        	for (idx in spec_array)
            		print spec_array[idx]
}


$0 !~ /^$/ && $0 !~ /^#/ {
    i = 1; k = 0
    datatype = ""; str = $0
    print ">>> " str
    do {
        out = ""; prevtoken = "NO"; name = ""
        if (k++ == 0) {
            gettoken();
            for ( ; tokenspec() == "YES" || tokenqual() == "YES"; gettoken() )
                datatype = conn_blank(datatype, token)
            prevtoken = "YES"
        }
        dcl()
        printf("%s: %s%s\n", name, out, datatype)
    } while (tokentype == ",")
}



