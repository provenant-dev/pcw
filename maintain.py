import stat
import traceback

from util import *


def fix_prompt(script):
    log.write("Fixing ")
    prompt_pat = re.compile(r'\s*PS1\s*=')
    lines = script.split('\n')
    new_lines = []
    for line in lines:
        if prompt_pat.match(line):
            line = line.replace('\\u@\\h', "${OWNER}\\047s wallet")
        new_lines.append(line)
    return '\n'.join(new_lines)


def refresh_repo(url):
    fetched_anything = True
    repo_name = url[url.rfind('/') + 1:-4]
    if os.path.isdir(repo_name):
        cout(f"Checking for {repo_name} updates.\n")
        git_log = os.path.expanduser(f"~/.git-pull-{repo_name}.log")
        with TempWorkingDir(repo_name):
            os.system(f"git pull >{git_log} 2>&1")
            with open(git_log, "rt") as f:
                result = f.read().strip()
        os.remove(git_log)
        fetched_anything = bool(result != "Already up to date.")
        log.write(result)
    else:
        cout(f"Installing {repo_name}.\n")
        run(f"git clone {url}")
    return fetched_anything


def personalize():
    bashrc = ".bashrc"
    semaphore = bashrc + '-changed'
    backup_file(bashrc)
    with open(bashrc, 'rt') as f:
        script = f.read()
    owner = get_shell_variable("OWNER", script)
    if not owner:
        owner = ask("What is your first and last name?")
        script = f'OWNER="{owner}"\n' + fix_prompt(script)
        with open(bashrc, 'wt') as f:
            f.write(script)
        run(f"touch {semaphore}")
    return owner


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
    log.close()
    temp_log_fname = "~/.log"
    os.system(f"mv {LOG_FILE} {temp_log_fname}")
    log = open(temp_log_fname, "wt")
    run(f"rm {DATA_FOLDER}/*")
    log.close()
    os.system(f"mv {temp_log_fname} {LOG_FILE}")
    globals()["log"] = open(LOG_FILE, "at")
    run("rm -rf ~/keripy ~/vlei-qvi ~/.keri")
    run("mv ~/.bashrc.bak ~/.bashrc")


def add_scripts_to_path():
    cout("Configuring commands.\n")
    if not os.path.exists(BIN_PATH):
        os.makedirs(BIN_PATH)
    # Remove old, broken links.
    for script in os.listdir(BIN_PATH):
        dest_path = os.path.join(BIN_PATH, script)
        if os.path.islink(dest_path) and not os.path.exists(dest_path):
            log.write("Removing broken symlink %s." % dest_path)
            os.unlink(dest_path)
    # Add new symbolic links.
    scripts_path = os.path.expanduser("~/vlei-qvi/scripts")
    for script in os.listdir(scripts_path):
        src_path = os.path.join(scripts_path, script)
        if os.path.isfile(src_path):
            if bool(os.stat(src_path).st_mode & stat.S_IXUSR):
                basename = os.path.splitext(basename)[0]
                dest_path = os.path.join(BIN_PATH, basename)
                if not os.path.exists(dest_path):
                    log.write("Symlinking %s to %s." % (dest_path, src_path))
                    os.symlink(src_path, dest_path)


def do_maintenance():
    os.chdir(os.path.expanduser("~/"))
    log.write("\n\n" + "-" * 50 + "\nScript launched " + time.asctime())
    cout(term.normal + "\n--- Doing wallet maintenance.\n")
    try:
        try:  # Inside this block, use dim color. Revert to normal text when block ends.
            cout(term.dim_yellow)
            if os.path.exists(RERUNNER):
                cout("Detected rerun flag; removing.\n")
                bak = RERUNNER + '.bak'
                if os.file.exists(bak):
                    os.remove(bak)
                os.rename(RERUNNER, bak)
                os.remove(bak)
            if len(sys.argv) == 2 and sys.argv[1] == '--reset':
                if ask(RESET_PROMPT).lower() != "yes":
                    cout("Abandoning request to reset.\n")
                else:
                    cout("Resetting state. Log out and log back in to begin again.\n")
                    reset()
            else:
                if refresh_repo("https://github.com/provenant-dev/pcw.git"):
                    cout("Wallet software updated. Requesting re-launch.\n")
                    run(f"touch {RERUNNER}")
                    # Give file buffers time to flush.
                    time.sleep(1)
                else:
                    owner = personalize()
                    patch_os()
                    refresh_repo("https://github.com/provenant-dev/keripy.git")
                    guarantee_venv()

                    source_to_patch = 'vlei-qvi/source.sh'
                    # Undo any active patch that we might have against source.sh.
                    # so git won't complain about merge conflicts or unstashed files.
                    restore_from_backup(source_to_patch)
                    refresh_repo("https://github.com/provenant-dev/vlei-qvi.git")
                    # (Re-)apply the patch.
                    backup_file(source_to_patch)
                    patch_source(owner, source_to_patch)
                    add_scripts_to_path()
        finally:
            sys.stdout.write(term.normal)
        cout("--- Maintenance tasks succeeded.\n")
    except KeyboardInterrupt:
        cout(term.red + "--- Exited script early. Run maintain --reset to clean up." + term.normal + "\n")
        sys.exit(1)
    except:
        cout(term.red + "--- Error.\n")
        cout(traceback.format_exc())
        cout("---" + term.normal + "\n")


if __name__ == '__main__':
   do_maintenance()
