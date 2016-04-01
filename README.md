cdecl.awk - C declaration parser by Awk
=========================================

This simple program expand the C declaration parser at the end of Chapter 5 in K&R's 
<i>The C Programming Language</i>, and reference
<i>The C Answer Book</i>,
Second Edition, by Colvis L. Tondo and Scott E. Gimpel.

A description of the grammar is the following:
````{.bnf}
        dcl:        optional *'s direct-dcl
                    optional qualifiers's direct-dcl

        direct-dcl: name
                    (dcl)
                    direct-dcl(optional parm-dcl)
                    direct-dcl[optional size]

        parm-dcl:   parm-dcl, dcl-spec dcl

        dcl-spec:   type-spec dcl-spec
                    type-qual dcl-spec
     
````

## Usage ##
```bash
\# Normal usage
$ echo 'void (*signal(int sig, void (*func)(int)))(int)' | \
    awk -f ./cdecl.awk -

\# Add the special type in the type.txt (or any other file name)
$ cat ./type.txt
sighandler_t
pthread_t
pthread_attr_t
pthread_cond_t
pthread_mutex_t
struct timespec

$ echo 'int pthread_create(pthread_t *thread, const pthread_attr_t *attr, void *(*start_routine) (void *), void *arg)' | \
    awk -f ./cdecl.awk ./type.txt -

\# Debug
$ echo 'char * const (*(* const bar)[5])(int x), * const str' | \
    awk -f ./cdecl.awk -- -d -
```

License
=======
The project is licensed under MIT. See [LICENSE](/LICENSE) file for the full license. 
