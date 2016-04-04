#!/usr/bin/env gawk -f
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


#=============================================================================
#
#  Implemented as an FSM reference to "Expert C Programming" book,
#  expand to handle declarations with function argument types.
#
#  Must use the Indirect Function Calls of gawk-specific extension.
#
#=============================================================================


function classify_string() {
    if (this["string"] == "const") {
        this["string"] = "read-only"
        return "QUALIFIER"
    }
    if (this["string"] == "volatile") 
        return "QUALIFIER"
    if (this["string"] == "void")
        return "TYPE"
    if (this["string"] == "char")
        return "TYPE"
    if (this["string"] == "signed")
        return "TYPE"
    if (this["string"] == "unsigned")
        return "TYPE"
    if (this["string"] == "short")
        return "TYPE"
    if (this["string"] == "int")
        return "TYPE"
    if (this["string"] == "long")
        return "TYPE"
    if (this["string"] == "float")
        return "TYPE"
    if (this["string"] == "double")
        return "TYPE"
    if (this["string"] == "struct")
        return "TYPE"
    if (this["string"] == "union")
        return "TYPE"
    if (this["string"] == "enum")
        return "TYPE"
    for (idx in spec_array)
        if(this["string"] ==spec_array[idx])
            return "TYPE"

    return "IDENTIFIER"

}

#-+- str is global variable (euqal to $0) -+-
function gettoken(  ch) {
    if (prevtoken == "YES") {
        prevtoken = "NO"
        return
    }
    while ((this["string"] = substr(str,i++,1)) == " ")
        ;
    if (this["string"] ~ /[0-9a-zA-Z_\-]/) {
        while ((ch = substr(str,i++,1)) ~ /[0-9a-zA-Z_\-]/)
            this["string"] = this["string"] ch
        i--
        this["type"] = classify_string()
        if (DEBUG) printf("\ntoken = %s; tokentype = %s\n", this["string"], this["type"]);
        return
    }
    if (this["string"] == "(") {
        if (substr(str, i++, 1) == ")") {
            this["string"] = "()"
            this["type"] = "PARENS"
            if (DEBUG) printf("\ntoken = %s; tokentype = %s\n", this["string"], this["type"]);
            return
        } else
            i--;
    }
    this["type"] = this["string"]
    if (DEBUG) printf("\ntoken = %s; tokentype = %s\n", this["string"], this["type"]);
    return
}

#-+- function can change the value of val["top"] -+-
function push(  stack, val) {
    val["top"]++ # begin from 1
    stack[val["top"], "string"] = this["string"]
    stack[val["top"], "type"] = this["type"]
}

function initialize(stack, val) {
    dclex(stack, val)
    gettoken()
    nextstate = "get_array"
}

function dclex(stack, val) {
    gettoken()
    for (; this["type"] == "*" || this["type"] == "TYPE" || \
            this["type"] == "QUALIFIER"; gettoken())
        push(stack, val)
    dclname(stack, val)
}

function dclname(stack, val) {
    if (this["type"] == "(") {
        push(stack, val)
        dclex(stack, val)
    } else if (this["type"] == "IDENTIFIER") {
        if (length(name) == 0) name = this["string"]
        printf("%s: ", this["string"])
    }
    else if (length(name) != 0)
        prevtoken = "YES"
    else
        printf(">>> error: missing name\n")
}

function get_array(stack, val) {
    nextstate = "get_params"
    while (this["string"] == "[") {
        printf("array ")
        gettoken() # a number or ']'
        if (this["string"] ~ /^[0-9]+$/) {
            printf("0..%d ", this["string"]-1)
            gettoken() # read the ']'
        }
        gettoken() # read the next past the ']'
        printf("of ")
        nextstate = "get_lparen"
    }
}

function get_params(stack, val) {
    nextstate = "get_lparen"
    if (this["type"] == "PARENS") {
        gettoken()
        printf("function returning ")
    } else if (this["type"] == "(") {
        printf("function (")
        parmdcl()
        nextstate = "get_lparen"
        printf(") returning ")
        gettoken()
    }
}

function get_lparen(stack, val) {
    nextstate = "get_ptr_part"
    if (val["top"] >= 1) {
        if (stack[val["top"], "type"] == "(") {
            val["top"]--
            gettoken() # read past ')'
            nextstate = "get_array"
        }
    }
}

function get_ptr_part(stack, val) {
    nextstate = "get_type"
    if(stack[val["top"], "type"] == "*") {
        printf("pointer to ")
        val["top"]--
        nextstate = "get_lparen"
    } else if (stack[val["top"], "type"] == "QUALIFIER") {
        printf("%s ", stack[val["top"]--, "string"])
        nextstate = "get_lparen"
    }
}


function get_type(stack, val) {
    nextstate = "NULL"
    for (k = 1; k <= val["top"]; k++)
        printf("%s%s", stack[k, "string"],
               k == val["top"] ? "" : " ")
}

function dcl(  stack, val) {
    nextstate = "initialize"
    while (nextstate != "NULL") {
        if (DEBUG) printf("\n>>> call %s() <<<\n", nextstate);
        @nextstate(stack, val)
    }
}

function parmdcl() {
    do {
        dcl()
        if (this["type"] == ",")
            printf(", ")
    } while (this["type"] == ",")
    if (this["type"] != ")")
        printf(">>> error: missing )\n")
}

BEGIN {
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
}

{
    i = 1; prevtoken = "NO"; name = ""
    str = $0
    print ">>> " str
    dcl()
    printf("\n");
}
