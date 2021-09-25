this works, but not in GHCi:

ghci> main
<class 'ImportError'>
Unable to import required dependencies:
numpy:

IMPORTANT: PLEASE READ THIS FOR ADVICE ON HOW TO SOLVE THIS ISSUE!

Importing the numpy C-extensions failed. This error can happen for
many reasons, often due to issues with your setup or how NumPy was
installed.

We have compiled some common reasons and troubleshooting tips at:

    https://numpy.org/devdocs/user/troubleshooting-importerror.html

Please note and check the following:

  * The Python version is: Python3.__ from "/nix/store/xf1k5k05vg3zn7dfcpfh1qa7ga48hi3m-python3-__/bin/python3"
  * The NumPy version is: "1.__"

and make sure that they are the versions you expect.
Please carefully study the documentation linked above for further help.

Original error was: /nix/store/ng6b4wfyypdabb3g9zy955b8hykkndkw-python3-___-env/lib/python3.__/site-packages/numpy/core/_multiarray_umath.cpython-___-x86_64-linux-gnu.so: undefined symbol: PyObject_SelfIter

pytz: /nix/store/xf1k5k05vg3zn7dfcpfh1qa7ga48hi3m-python3-___/lib/python3.__/lib-dynload/math.cpython-___-x86_64-linux-gnu.so: undefined symbol: PyFloat_Type
  File "/nix/store/ng6b4wfyypdabb3g9zy955b8hykkndkw-python3-___-env/lib/python3.__/site-packages/pandas/__init__.py", line 16, in <module>
    raise ImportError(
*** Exception: PyCastException "Text"
ghci>
Leaving GHCi.


More info:

https://stackoverflow.com/questions/67891197/ctypes-cpython-39-x86-64-linux-gnu-so-undefined-symbol-pyfloat-type-in-embedd

the python lib needs to be dynamically loaded using RTLD_GLOBAL. How can GHCi be told to do this?
