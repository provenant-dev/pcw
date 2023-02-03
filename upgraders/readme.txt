Python files in this folder that have purely numeric names are called "upgraders".
These are small, standalone scripts that tweak something about a wallet to make
it compatible with the latest generation of code. For example, 3.py was created
when we started using netstat on the cmdline; that tool isn't installed by default,
so 3.py fixes the problem. You can think of upgraders as being a very, very simple
alternative to configuration management technology like puppet or ansible or chef.

Each script should be idempotent (if it runs more than once, it should be harmless).
It should also write to stdout/stderr and return 0 on success or non-zero on error.
It should not take any args. It cannot have any runtime dependencies except ones
satisfied by either the base mage of the wallet, or an upgrader that precedes it
numerically.

Upgraders are invoked by maintain.py (look for run_upgrade_scripts() near the
bottom). When an upgrader succeeds, it writes a .done file next to its .py file.
This tells maintain.py that it doesn't need to be run ever again. If an upgrader
fails, it writes a .err file instead; this can help with troubleshooting. Every
time the maintenance script runs, it checks to see if there are pending upgraders.
If so, it runs them in ascending numerical order. If one fails, the maintainer
script stops; later upgraders are not called. If they all succeed, then the next
maintenance pass won't have anything to do.