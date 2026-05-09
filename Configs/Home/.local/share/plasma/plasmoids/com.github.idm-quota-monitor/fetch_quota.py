#!/usr/bin/env python3
"""
Fetches IDM quota for both ADSL and LTE in one login session.
Credentials are read from ~/.config/IDMQuota/config.conf

Modes:
  fetch_quota.py                             fetch quota
  fetch_quota.py --write-config B64U B64P   save credentials (base64-encoded args)
"""

import re, json, os, sys, base64, hashlib
from datetime import datetime

try:
    import requests
except ImportError:
    _err = {"adsl": {"error": "Missing dependency: pip install requests"},
            "lte":  {"error": "Missing dependency: pip install requests"},
            "adsl_history": [], "lte_history": []}
    print(json.dumps(_err)); sys.exit(1)

try:
    from cryptography.fernet import Fernet
except ImportError:
    _err = {"adsl": {"error": "Missing dependency: pip install cryptography"},
            "lte":  {"error": "Missing dependency: pip install cryptography"},
            "adsl_history": [], "lte_history": []}
    print(json.dumps(_err)); sys.exit(1)


def _fernet():
    """Derive a Fernet key from this machine's unique ID."""
    with open("/etc/machine-id") as f:
        mid = f.read().strip()
    key = base64.urlsafe_b64encode(hashlib.sha256(mid.encode()).digest())
    return Fernet(key)


def _encrypt(plaintext: str) -> str:
    return _fernet().encrypt(plaintext.encode()).decode()


def _decrypt(token: str) -> str:
    return _fernet().decrypt(token.encode()).decode()

SCRIPT_DIR  = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.expanduser("~/.config/IDMQuota/config.conf")
LOGIN_URL   = "https://myaccount.idm.net.lb/_layouts/15/IDMPortal/ManageUsers/Login.aspx"

BASE_URL     = "https://myaccount.idm.net.lb"
ACCOUNTS_URL = BASE_URL + "/_layouts/15/IDMPortal/ManageServices/MyAccounts.aspx"
HISTORY_MAX  = 96

# Service type strings the portal uses → our internal key
_TYPE_MAP = {
    "adsl": "adsl", "vdsl": "adsl", "fiber": "adsl",
    "3g": "lte", "4g": "lte", "lte": "lte",
}

HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
}


def read_config():
    config = {}
    try:
        with open(CONFIG_PATH) as f:
            for line in f:
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    k, v = line.split("=", 1)
                    config[k.strip()] = v.strip()
    except FileNotFoundError:
        pass
    # Decrypt values if they look like Fernet tokens (start with 'gAAA')
    for key in ("username", "password"):
        if key in config and config[key].startswith("gAAA"):
            try:
                config[key] = _decrypt(config[key])
            except Exception:
                pass
    return config


def write_config(username, password):
    os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
    with open(CONFIG_PATH, "w") as f:
        f.write(f"username={_encrypt(username)}\npassword={_encrypt(password)}\n")


def extract_hidden_fields(html):
    fields = {}
    for m in re.finditer(r'<input[^>]+type=["\']hidden["\'][^>]*>', html, re.IGNORECASE):
        tag = m.group(0)
        name  = re.search(r'name=["\']([^"\']*)["\']', tag)
        value = re.search(r'value=["\']([^"\']*)["\']', tag)
        if name:
            fields[name.group(1)] = value.group(1) if value else ""
    return fields


def load_history(conn):
    path = os.path.join(SCRIPT_DIR, f"history_{conn}.json")
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return []


def save_history(conn, history):
    path = os.path.join(SCRIPT_DIR, f"history_{conn}.json")
    with open(path, "w") as f:
        json.dump(history[-HISTORY_MAX:], f)


def parse_expiry(date_str):
    """Return (days_remaining, time_str_or_None). Negative days = already expired."""
    s = date_str.strip().replace('\xa0', ' ')
    # Try datetime formats first (date + time)
    for fmt in ("%m/%d/%Y %H:%M", "%d/%m/%Y %H:%M", "%Y-%m-%d %H:%M", "%d-%m-%Y %H:%M",
                "%m/%d/%Y %H:%M:%S", "%d/%m/%Y %H:%M:%S", "%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S"):
        try:
            exp = datetime.strptime(s, fmt)
            days = (exp.date() - datetime.now().date()).days
            return days, exp.strftime("%H:%M")
        except ValueError:
            continue
    # Date-only formats
    for fmt in ("%d/%m/%Y", "%Y-%m-%d", "%m/%d/%Y", "%d-%m-%Y"):
        try:
            exp = datetime.strptime(s, fmt)
            days = (exp.date() - datetime.now().date()).days
            return days, None
        except ValueError:
            continue
    return None, None


def discover_services(session):
    """Return list of {conn_key, ctrl_id} by scraping the MyAccounts grid."""
    r = session.get(ACCOUNTS_URL, timeout=20)
    r.raise_for_status()
    services = []
    rows = re.findall(
        r'ResidentialServicesGridView_(ctl\d+)_ResidentialAccountName'
        r'.*?_\1_Type[^>]*>([^<]+)<',
        r.text, re.DOTALL)
    for ctrl_id, svc_type in rows:
        key = _TYPE_MAP.get(svc_type.strip().lower())
        if key:
            services.append({"key": key, "ctrl": ctrl_id, "page": r})
    return services


def scrape(session, ctrl_id, accounts_page_response):
    """Trigger the Manage postback for ctrl_id, then scrape the resulting page."""
    payload = extract_hidden_fields(accounts_page_response.text)
    payload["__EVENTTARGET"] = (
        f"ctl00$PlaceHolderMain$ResidentialServicesGridView"
        f"${ctrl_id}$ManageResidentialButton")
    payload["__EVENTARGUMENT"] = ""
    r = session.post(ACCOUNTS_URL, data=payload, timeout=20,
                     headers={"Referer": ACCOUNTS_URL}, allow_redirects=True)
    r.raise_for_status()
    pct = re.search(r'ctl00_PlaceHolderMain_TraficUsed[^>]*data-percent="([^"]+)"', r.text)
    rem = re.search(r'id="ctl00_PlaceHolderMain_RemainingLabel"[^>]*>([^<]+)<', r.text)
    # Pattern 1: "Expiry Date</td><td...>DATE TIME</td>" (LTE table layout)
    exp = re.search(
        r'Expiry\s+Date\s*</td>\s*<td[^>]*>\s*'
        r'(\d{1,4}[\/\-]\d{1,2}[\/\-]\d{2,4}[\s\xa0]+\d{2}:\d{2}(?::\d{2})?)',
        r.text, re.IGNORECASE)
    # Pattern 2: label element with ID (ADSL layout)
    if not exp:
        exp = re.search(
            r'id="ctl00_PlaceHolderMain_ExpiryDateLabel"[^>]*>([^<]+)<',
            r.text)
    # Pattern 3: data attributes near expiry keyword
    if not exp:
        exp = re.search(
            r'(?:ExpiryDate|EndDate|expiry|expire)[^>]*?'
            r'(?:data-\w+|value|title|datetime)=["\']'
            r'(\d{1,4}[\/\-]\d{1,2}[\/\-]\d{2,4}(?:[T \t]\d{2}:\d{2}(?::\d{2})?)?)["\']',
            r.text, re.IGNORECASE)
    # Pattern 4: wide sweep fallback
    if not exp:
        exp = re.search(
            r'(?:expir\w*|end\s*date)[^<]{0,80}?'
            r'(\d{1,4}[\/\-]\d{1,2}[\/\-]\d{2,4}(?:[T \t\xa0]\d{2}:\d{2}(?::\d{2})?)?)',
            r.text, re.IGNORECASE)
    if not pct and not rem:
        raise ValueError("Could not find quota elements")
    exp_str          = exp.group(1).strip() if exp else None
    days_left, exp_time = parse_expiry(exp_str) if exp_str else (None, None)
    # Debug: log raw expiry string to stderr so we can see what the portal returns
    if exp_str:
        import sys; print(f"[expiry raw] {exp_str!r}", file=sys.stderr)
    return {
        "percent":    round(float(pct.group(1)), 2) if pct else None,
        "remaining":  rem.group(1).strip() if rem else None,
        "days_left":  days_left,
        "expiry":     exp_str,
        "expiry_time": exp_time,
        "updated":    datetime.now().strftime("%H:%M"),
        "error":      None,
    }


def run():
    config   = read_config()
    username = config.get("username", "")
    password = config.get("password", "")

    if not username or not password:
        raise RuntimeError("No credentials — edit ~/.config/IDMQuota/config.conf or use widget Settings")

    session = requests.Session()
    session.headers.update(HEADERS)

    r = session.get(LOGIN_URL, timeout=20)
    r.raise_for_status()

    payload = extract_hidden_fields(r.text)
    payload["__EVENTTARGET"]   = "ctl00$PlaceHolderMain$signInControl$SignInButton"
    payload["__EVENTARGUMENT"] = ""
    payload["ctl00$PlaceHolderMain$signInControl$UserName"] = username
    payload["ctl00$PlaceHolderMain$signInControl$password"] = password

    r = session.post(LOGIN_URL, data=payload, timeout=20, headers={"Referer": LOGIN_URL})
    r.raise_for_status()

    if "signInControl_UserName" in r.text:
        raise RuntimeError("Login failed — check username and password")

    services = discover_services(session)
    if not services:
        raise RuntimeError("No services found — check your account has ADSL or LTE")

    result = {}
    for svc in services:
        conn = svc["key"]
        try:
            data = scrape(session, svc["ctrl"], svc["page"])
        except Exception as e:
            data = {"percent": None, "remaining": None, "days_left": None,
                    "expiry": None, "expiry_time": None,
                    "updated": datetime.now().strftime("%H:%M"), "error": str(e)}

        history = load_history(conn)
        if data["percent"] is not None:
            history.append({"t": data["updated"], "pct": data["percent"]})
            save_history(conn, history)

        result[conn] = data
        result[f"{conn}_history"] = history[-HISTORY_MAX:]

    print(json.dumps(result))


if __name__ == "__main__":
    if "--write-config" in sys.argv:
        idx = sys.argv.index("--write-config")
        try:
            username = bytes.fromhex(sys.argv[idx + 1]).decode("utf-8")
            password = bytes.fromhex(sys.argv[idx + 2]).decode("utf-8")
            write_config(username, password)
            print(json.dumps({"ok": True}))
        except Exception as e:
            print(json.dumps({"ok": False, "error": str(e)}))
            sys.exit(1)
        sys.exit(0)

    try:
        run()
    except Exception as e:
        err = {"adsl": {"error": str(e)}, "lte": {"error": str(e)},
               "adsl_history": [], "lte_history": []}
        print(json.dumps(err))
        sys.exit(1)
