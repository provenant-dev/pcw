import re
import sys
from util import sys_call_with_output_or_die


_aliases = None
alias_item_pat = re.compile(r"^(.*?)[(](.*?)[)]", re.MULTILINE)


def _get_alias_dict():
    global _aliases
    if _aliases is None:
        aliases = sys_call_with_output_or_die("list-aliases")
        _aliases = {}
        for match in alias_item_pat.finditer(aliases):
            _aliases[match.group(1).strip()] = match.group(2).strip()
    return _aliases


def details(alias):
    return sys_call_with_output_or_die(f'pkli status --alias "{alias}"')


multikey_pat = re.compile(r"Public Keys:[ \t\r\n]+1[.]([^\r\n]+)[ \t\r\n]+2[.]")


def details_are_multisig(details):
    return 1 if bool(multikey_pat.search(details)) else 0


def is_multisig(alias):
    return details_are_multisig(details(alias))


def subset(typ):
    filtered = []
    typ = typ.lower()[0]
    aliases = _get_alias_dict()
    if typ == 'a': # "all"
        filter = lambda x: True
    elif typ == 'm': # "multisig"
        filter = lambda x: is_multisig(x)
    else:
        filter = lambda x: not is_multisig(x)
    for alias, aid in aliases.items():
        if filter(alias):
            filtered.append(alias.strip())
    print(', '.join(sorted(filtered)))


if __name__ == '__main__':
    func = globals()[sys.argv[1]]
    answer = func(sys.argv[2] if len(sys.argv) > 2 else None)
    if isinstance(answer, str):
        print(answer)
    else:
        sys.exit(answer)
