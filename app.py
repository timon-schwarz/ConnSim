from flask import Flask, request, render_template
from colorama import init, Fore, Style
import subprocess
import os


# Initialize flask
app = Flask(__name__)

# Initialize colorama
init(autoreset=True)

# ANSI color codes for formatting with colorama
WHITE = Fore.WHITE           # White for command execution details
RED = Fore.RED               # Red for application errors
YELLOW = Fore.YELLOW         # Yellow for stderr outputs
GREEN = Fore.GREEN           # Green for application messages
RESET = Style.RESET_ALL      # Reset all styles

# Initialize dictionaries for interface mappings
INT_TO_NAME = {}
NAME_TO_INT = {}

# Fetch environment variables and populate dictionary with ids
for key, value in os.environ.items():
    if key.startswith('INTERFACE_'):
        parts = key.split('_')
        if len(parts) != 2:
            continue
        INT_TO_NAME[parts[1]] = value
        NAME_TO_INT[value] = parts[1]

# Helper function to execute tc commands securely
def run_tc_command(command):
    try:
        print('')  # Empty line before every command
        print(f"Executing command: {WHITE}{' '.join(command)}{RESET}")
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        stdout = result.stdout.decode('utf-8')
        stderr = result.stderr.decode('utf-8')
        print(f"stdout: {WHITE}{stdout}{RESET}")
        if stderr:
            print(f"{YELLOW}stderr: {stderr}{RESET}")
        return stdout, stderr
    except subprocess.CalledProcessError as e:
        print(f"Command {WHITE}'{' '.join(e.cmd)}'{RESET} returned non-zero exit status {e.returncode}.{RESET}")
        print(f"stdout: {YELLOW}{e.stdout.decode('utf-8')}{RESET}")
        print(f"stderr: {YELLOW}{e.stderr.decode('utf-8')}{RESET}")
        return e.stdout.decode('utf-8'), e.stderr.decode('utf-8')
    except PermissionError as e:
        print(f"{RED}Permission error: {e}{RESET}")
        return "", str(e)
    except Exception as e:
        print(f"{RED}Unexpected error: {e}{RESET}")
        return "", str(e)

# Function to validate interface
def is_valid_interface(interface):
    return interface in INT_TO_NAME.keys()

# Function to validate interface custom names
def is_valid_interface_name(name):
    return name in NAME_TO_INT.keys()

# Function to validate numeric inputs
def is_valid_number(value):
    try:
        float(value)
        return True
    except ValueError:
        return False

# Home route to display current settings
@app.route('/')
def index():
    settings = {}
    errors = {}
    for identifier, custom_name in INT_TO_NAME.items():
        cmd = ["tc", "qdisc", "show", "dev", identifier]
        stdout, stderr = run_tc_command(cmd)
        settings[custom_name] = stdout
        errors[custom_name] = stderr
    return render_template('index.html', settings=settings, errors=errors, interfaces=INT_TO_NAME)

# Route to update settings
@app.route('/update', methods=['POST'])
def update():
    custom_name = request.form['interface']
    if not is_valid_interface_name(custom_name):
        print (f"{RED}Invalid custom interface name {custom_name}{RESET}")
        return f"{RED}Invalid custom interface name{RESET}", 400

    identifier = NAME_TO_INT.get(custom_name)
    if not is_valid_interface(identifier):
        print (f"{RED}Invalid interface {identifier}{RESET}")
        return f"{RED}Invalid interface{RESET}", 400

    delay = request.form.get('delay')
    jitter = request.form.get('jitter')
    loss = request.form.get('loss')
    corrupt = request.form.get('corrupt')
    duplicate = request.form.get('duplicate')
    reorder = request.form.get('reorder')
    rate = request.form.get('rate')

    # Validate inputs
    if delay and not is_valid_number(delay):
        return f"{RED}Invalid delay{RESET}", 400
    if jitter and not is_valid_number(jitter):
        return f"{RED}Invalid jitter{RESET}", 400
    if loss and not is_valid_number(loss):
        return f"{RED}Invalid loss{RESET}", 400
    if corrupt and not is_valid_number(corrupt):
        return f"{RED}Invalid corrupt{RESET}", 400
    if duplicate and not is_valid_number(duplicate):
        return f"{RED}Invalid duplicate{RESET}", 400
    if reorder and not is_valid_number(reorder):
        return f"{RED}Invalid reorder{RESET}", 400
    if rate and not is_valid_number(rate):
        return f"{RED}Invalid rate{RESET}", 400

    # Clear existing settings
    del_command = ["tc", "qdisc", "del", "dev", identifier, "root"]
    run_tc_command(del_command)

    # Apply new settings if any
    if any([delay, jitter, loss, corrupt, duplicate, reorder, rate]):
        command = ["tc", "qdisc", "add", "dev", identifier, "root", "netem"]
        if delay:
            command += ["delay", f"{delay}ms"]
        if jitter:
            command += [f"{jitter}ms"]
        if loss:
            command += ["loss", "random", f"{loss}%"]
        if corrupt:
            command += ["corrupt", f"{corrupt}%"]
        if duplicate:
            command += ["duplicate", f"{duplicate}%"]
        if reorder:
            command += ["reorder", f"{reorder}%"]
        if rate:
            command += ["rate", f"{rate}mbit"]

        stdout, stderr = run_tc_command(command)

    return index()

if __name__ == '__main__':
    app.run(host='172.30.218.11', port=8080)
