import hashlib
import os
import sys


def workspace(root):
    cache = os.environ.get("XDG_CACHE_HOME")
    if not cache or not os.path.isabs(cache):
        cache = os.path.join(os.path.expanduser("~"), ".cache")
    key = hashlib.sha256(os.fsencode(os.path.realpath(root))).hexdigest()
    return os.path.join(cache, "limanix", "jdtls", key)


def main():
    executable, *arguments = sys.argv[1:]
    root = os.environ.pop("LMX_JDTLS_ROOT", None)
    if not any(argument == "-data" or argument.startswith("-data=") for argument in arguments):
        directory = workspace(root or os.getcwd())
        os.makedirs(directory, mode=0o700, exist_ok=True)
        arguments += ["-data", directory]
    os.execv(executable, [executable, *arguments])


if __name__ == "__main__":
    main()
