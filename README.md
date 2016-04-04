cdecl.awk - C declaration parser by Awk
=========================================
The branch fsm implemented the parser as an FSM reference to
<i>Expert C Programming</i>,
expand with function argument types and adjust the order of type
declarations.

Usage
======
```bash
# Normal usage
$ echo 'void (*signal(int sig, void (*func)(int)))(int)' | \
    awk -f ./cdecl.awk -

# Add the special type in the type.txt (or any other file name)
$ cat ./type.txt
sighandler_t
pthread_t
pthread_attr_t
pthread_cond_t
pthread_mutex_t
struct timespec

$ echo 'int pthread_create(pthread_t *thread, \
    const pthread_attr_t *attr, \
    void *(*start_routine) (void *), void *arg)' | \
    awk -f ./cdecl.awk ./type.txt -

# Debug
$ echo 'char * const (*(* const bar)[5])(int x), * const str' | \
    awk -f ./cdecl.awk -- -d -
```

License
=======
The project is licensed under MIT. See [LICENSE](/LICENSE) file for the full license. 

THANKS
======
Thanks to git@github.com:m-pilia/cdecl and http://cdecl.org for
providing their programs to help verify.

