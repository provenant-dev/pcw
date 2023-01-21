import os
import re
import sys


def _system_output(cmd):
    tmp = ".tmp-output"
    exit_code = os.system(cmd + f" >{tmp} 2>&1")
    if os.path.isfile(tmp):
        with open(tmp, "rt") as f:
            output = f.read()
        os.remove(tmp)
    else:
        output = ""
    if exit_code != 0:
        print(f"Ran {cmd} and expected success. Got this instead:\n" + output)
        sys.exit(1)
    return output


_aliases = None
alias_item_pat = re.compile(r"^(.*?)[(](.*?)[)]", re.MULTILINE)


def _get_alias_dict():
    global _aliases
    if _aliases is None:
        aliases = _system_output("list-aliases")
        _aliases = {}
        for match in alias_item_pat.finditer(aliases):
            _aliases[match.group(1)] = match.group(2)
    return _aliases


def details(alias):
    return _system_output(f'pkli status --alias "{alias}"')


multikey_pat = re.compile(r"Public Keys:[ \t\r\n]+1[.]([^\r\n]+)[ \t\r\n]+2[.]")


def details_are_multisig(details):
    return 1 if bool(multikey_pat.search(details)) else 0


def is_multisig(alias):
    return details_are_multisig(details(alias))


if __name__ == '__main__':
    func = globals()[sys.argv[1]]
    answer = func(sys.argv[2])
    if isinstance(answer, str):
        print(answer)
    else:
        sys.exit(answer)
