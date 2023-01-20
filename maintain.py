import os.path
import re
import traceback

from util import *


def fix_prompt(script):
    log.write("Fixing ")
    prompt_pat = re.compile(r'\s*PS1\s*=')
    lines = script.split('\n')
    new_lines = []
    for line in lines:
        if prompt_pat.match(line):
            prefix = line[:line.find('=') + 1]
            # Is this a color prompt?
            # Typical colored prompt on ubuntu:
            #     PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
            if "033" in line:
                plain = "\\[\\033[00m\\]"
                bar = plain + " | "

                def c(n):
                    return "\\[\\033[01;" + str(n) + "m\\]"
                blue = c(34)
                green = c(32)
                red = c(31)
                at = f"{plain} @ {green}"
                line = prefix + f"'{blue}PCW{bar}{green}$OWNER{at}$ORG{bar}{red}$CTX{plain}:{blue}\w{plain}\$ '"
            else:
                line = line.replace('\\u@\\h', "PCW | $OWNER @ $ORG | $CTX")
        new_lines.append(line)
    return '\n'.join(new_lines)


def run_git_cmd(cmd):
    fname = ".git.log"
    if os.path.isfile(fname):
        os.remove(fname)
    exit_code = os.system(cmd + f" >{fname} 2>&1")
    if os.path.isfile(fname):
        with open(fname, 'rt') as f:
            output = f.read().strip() + '/n'
        os.remove(fname)
    else:
        output = ""
    return exit_code, output


last_commit_pat = re.compile(r"^commit\s+([a-zA-Z0-9]+)", re.MULTILINE)
active_branch_pat = re.compile(r"^[*]\s*([^\n]+)", re.MULTILINE)


def describe_code():
    exit_code, last_commit_txt = run_git_cmd("git log -1")
    m = last_commit_pat.search(last_commit_txt)
    if m:
        last_commit_txt = m.group(1)[:7]
    exit_code, branch = run_git_cmd("git branch")
    m = active_branch_pat.search(branch)
    if m:
        branch = m.group(1)
    return f"branch = {branch}, last commit = {last_commit_txt}\n"


def refresh_repo(url, folder=None):
    fetched_anything = True
    repo_name = folder if folder else url[url.rfind('/') + 1:-4]
    if os.path.isdir(repo_name):
        cout(f"Checking for {repo_name} updates.\n")
        git_log = os.path.expanduser(f"~/.git-pull-{repo_name}.log")
        if os.path.isfile(git_log):
            os.remove(git_log)
        with TempWorkingDir(repo_name):
            exit_code = os.system(f"git pull >{git_log} 2>&1")
            with open(git_log, "rt") as f:
                result = f.read().strip()
            fetched_anything = bool(result != "Already up to date.")
            if exit_code == 0:
                if fetched_anything:
                    cout("Pulled new code; " + describe_code())
                else:
                    cout("Already up-to-date; " + describe_code())
            else:
                cout(term.red(result + '\n'))
        log.write(result + '\n')
    else:
        cout(f"Installing {repo_name}.\n")
        run(f"git clone {url} {repo_name}")
    return fetched_anything


def personalize():
    bashrc = ".bashrc"
    semaphore = bashrc + '-changed'
    backup_file(bashrc)
    with open(bashrc, 'rt') as f:
        script = f.read()
    s = script

    def get_var(name, prompt, sh):
        val = get_shell_variable(name, sh)
        if not val:
            val = ask(prompt).strip()
            sh = name + '="' + val + '"\n\n' + sh
        return val, sh

    owner, s = get_var("OWNER", "What is your first and last name?", s)
    org, s = get_var("ORG", "What org do you represent (one word)?", s)
    ctx, s = get_var("CTX", "Is this wallet for use in dev, stage, or production contexts?", s)
    ctx = ctx.lower()[0]
    ctx = 'dev' if ctx == 'd' else 'stage' if ctx == 's' else 'prod'
    if s != script:
        s = fix_prompt(s)
        with open(bashrc, 'wt') as f:
            f.write(s)
        run(f"touch {semaphore}")
    if not is_protected():
        protect()
    return owner, org, ctx


def patch_os(cache_secs=86400):
    if time_since(PATCH_CHECK_FILE) > cache_secs:
        cout("Making sure your wallet OS is fully patched.\n")
        if os.path.isfile(PATCH_CHECK_FILE):
            os.remove(PATCH_CHECK_FILE)
        with open(PATCH_CHECK_FILE, "wt"):
            pass
        run("sudo DEBIAN_FRONTEND=noninteractive apt-get update -y")
        run("sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y")
        run("sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y")


def guarantee_venv():
    if not os.path.isdir("keripy/venv"):
        cout("Creating venv for keripy.\n")
        os.chdir("keripy")
        try:
            run("python3 -m venv venv")
        finally:
            os.chdir(os.path.expanduser("~/"))


def patch_source(owner, source_to_patch):
    my_folder = os.path.abspath(os.path.dirname(__file__))
    with open(os.path.join(my_folder, 'source.sh'), "rt") as f:
        source_script = f.read()
    with open(source_to_patch, 'wt') as f:
        f.write(source_script.replace('QAR_ALIAS=""', f'QAR_ALIAS="{owner}"'))


def reset():
    run("rm -rf ~/keripy ~/vlei-qvi ~/xar ~/.keri ~/.passcode-hash")
    if os.path.exists(os.path.expanduser("~/.bashrc.bak")):
        run("mv ~/.bashrc.bak ~/.bashrc")


def make_script(src_path, dest_path, cwd):
    src_path = os.path.abspath(src_path)
    with open(dest_path, 'wt') as f:
        f.write(f'#!/bin/bash\ncd {cwd}\n{src_path} "$@"\n')
    os.chmod(dest_path, SCRIPT_PERMISSIONS)


def add_scripts_to_path(folder, cwd):
    cout("Configuring commands.\n")
    if not os.path.exists(BIN_PATH):
        os.makedirs(BIN_PATH)
    for script in os.listdir(folder):
        src_path = os.path.join(folder, script)
        if os.path.isfile(src_path):
            if bool(os.stat(src_path).st_mode & stat.S_IXUSR):
                basename = os.path.splitext(script)[0]
                dest_path = os.path.join(BIN_PATH, basename)
                log.write("Making command %s to run %s.\n" % (dest_path, src_path))
                make_script(src_path, dest_path, cwd)


def break_rerun_cycle():
    # Simply deleting the rerunner should work. However,
    # testing showed that sometimes the file wasn't quite
    # deletable -- so switch to a slower but more reliable
    # method where we first rename, then delete.
    bak = RERUNNER + '.bak'
    if os.path.exists(bak):
        os.remove(bak)
    #print(f"Renaming {RERUNNER} to {bak}")
    os.rename(RERUNNER, bak)
    #print(f"Removing {bak}")
    os.remove(bak)


def do_maintenance():
    os.chdir(os.path.expanduser("~/"))
    log.write("\n\n" + "-" * 50 + "\nScript launched " + time.asctime())
    sys.stdout.write(term.normal)
    cout("\n--- Doing wallet maintenance.")
    try:
        with TempColor(MAINTENANCE_COLOR):
            cout("\n")
            if os.path.exists(RERUNNER):
                cout("Detected rerun flag; removing.\n")
                break_rerun_cycle()
            if len(sys.argv) == 2 and sys.argv[1] == '--reset':
                cout("Wallet reset requested.\n" + term.normal)
                if ask(RESET_PROMPT).lower() != "yes":
                    cout("Abandoning request to reset.\n")
                else:
                    cout("\nResetting state.\n")
                    reset()
                    cout(term.normal + term.red("You must log out and log back in again to start over.\n"))
            else:
                if refresh_repo("https://github.com/provenant-dev/pcw.git"):
                    cout("Wallet software updated. Requesting re-launch.\n")
                    run(f"touch {RERUNNER}")
                    # Give file buffers time to flush.
                    time.sleep(1)
                else:
                    owner, org, ctx = personalize()
                    patch_os()
                    refresh_repo("https://github.com/provenant-dev/keripy.git")
                    guarantee_venv()

                    stash = os.path.isdir('xar')
                    if stash:
                        os.system("cd xar && git stash save >~/stash.log 2>&1")
                    refresh_repo("https://github.com/provenant-dev/vlei-qvi.git", "xar")
                    if stash:
                        os.system("cd xar && git stash pop >>~/stash.log 2>&1")
                    else:
                        config_files = {
                            'qar-config.json': 'scripts/keri/cf/',
                            'qar-local-incept.json': 'scripts'
                        }
                        prefix = 'prod' if ctx == 'prod' else 'stage'
                        for fname, folder in config_files.items():
                            src = os.path.join(MY_FOLDER, prefix + '-' + fname)
                            dest = os.path.join('xar', folder, fname)
                            shutil.copyfile(src, dest)
                        patch_source(owner, 'xar/source.sh')
                    add_scripts_to_path(os.path.expanduser("~/xar/scripts"), os.path.expanduser("~/xar"))
                    add_scripts_to_path(os.path.expanduser("~/pcw/bin"), os.path.expanduser("~/"))
        cout("--- Maintenance tasks succeeded.\n")
    except KeyboardInterrupt:
        cout(term.red("--- Exited script early. Run maintain --reset to clean up.\n"))
        sys.exit(1)
    except:
        cout(term.red("--- Error.\n" + traceback.format_exc() + "---\n"))


if __name__ == '__main__':
   do_maintenance()
