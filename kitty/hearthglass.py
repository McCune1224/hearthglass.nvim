#!/usr/bin/env python
# ============================================================================
# hearthglass.py — generator + switcher for kitty terminal themes derived from
# the hearthglass.nvim palette family.
#
# Run it directly with python3 (NOT as a `kitten` subcommand; kitty only ships
# its builtin kittens). It delegates the actual theme changes to the `kitten`
# CLI tool, which is what you configure kitty through.
#
# The palette data lives in exactly one place: lua/hearthglass/themes.lua.
# kitty/palettes.json is a build artifact exported from that file by
# kitty/export.lua (which runs hearthglass.colors, the same ramp derivation
# Neovim uses). This script only reads the exported slots — it carries no
# palette of its own, so it cannot drift. Both options are honored:
#   --low-blue-light   (light only) lift the parchment toward white
#   --colorblind MODE  deutan|protan|tritan|true  (same red/green remap)
#
# Commands:
#   python3 hearthglass.py list                  list theme keys
#   python3 hearthglass.py night  [--theme KEY]  apply a dark theme live
#   python3 hearthglass.py day    [--theme KEY]  apply a light theme live
#   python3 hearthglass.py toggle [--theme KEY]  switch the theme's faces
#   python3 hearthglass.py build  [DIR]          write every conf
#   python3 hearthglass.py install               copy confs into ~/.config/kitty/themes
#   python3 hearthglass.py help                  show this message
#
# Two ways to switch themes through the kitten CLI:
#   * interactive/persistent:  kitten themes   (pick the generated names)
#   * live (no config edit):   kitten @ set-colors <conf-file>
# The `night`/`day`/`toggle` commands call the latter. `kitten @ set-colors`
# needs kitty remote control enabled (`allow_remote_control yes` and
# `listen_on` in kitty.conf); without it, the conf is written and you are told
# the command to run.
# ============================================================================

import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
PALETTE_FILE = os.path.join(HERE, "palettes.json")
EXPORT_SCRIPT = os.path.join(HERE, "export.lua")

ORDER = []
THEMES = {}


def load_palettes():
    """Read the palette snapshot exported from lua/hearthglass/themes.lua."""
    global ORDER, THEMES
    if not os.path.exists(PALETTE_FILE):
        raise SystemExit(
            "missing %s\nrun: nvim --headless -l kitty/export.lua" % PALETTE_FILE
        )
    with open(PALETTE_FILE) as handle:
        data = json.load(handle)
    ORDER = data["order"]
    THEMES = data["themes"]


def refresh_palettes():
    """Regenerate the snapshot from themes.lua before a build, if Neovim exists."""
    nvim = shutil.which("nvim")
    if not nvim:
        sys.stderr.write("hearthglass: nvim not found; using existing palettes.json\n")
        return
    result = subprocess.run(
        [nvim, "--headless", "-l", EXPORT_SCRIPT],
        cwd=ROOT,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        sys.stderr.write(
            "hearthglass: palette export failed, using existing palettes.json\n"
            + (result.stderr or "")
        )
        return
    load_palettes()


def normalize_colorblind(value):
    if value is True:
        return "deutan"
    if value in (False, None, ""):
        return "plain"
    if value == "protan":
        return "deutan"
    if value in ("deutan", "tritan"):
        return value
    raise SystemExit("unknown colorblind mode: %s (try deutan, protan or tritan)" % value)


def get_colors(theme, kind, low_blue_light=False, colorblind=False):
    spec = THEMES.get(theme)
    if spec is None:
        raise SystemExit("unknown theme: %s (try `list`)" % theme)
    mode = normalize_colorblind(colorblind)
    variant = mode
    if low_blue_light and kind == "light":
        variant += "_low"
    return spec["faces"][kind][variant]


def conf_name(theme, kind):
    if theme == "hearthglass":
        return "hearthglass.conf" if kind == "dark" else "hearthglass-light.conf"
    return "%s.conf" % theme if kind == "dark" else "%s-light.conf" % theme


def emit_kitty(theme, kind, low_blue_light=False, colorblind=False):
    c = get_colors(theme, kind, low_blue_light, colorblind)
    title = THEMES[theme]["name"] + (" Light" if kind == "light" else "")
    face = "light" if kind == "light" else "dark"
    upstream = ("https://raw.githubusercontent.com/McCune1224/"
                "hearthglass.nvim/main/kitty/" + conf_name(theme, kind))
    lines = [
        "# vim:ft=kitty",
        "## name: %s" % title,
        "## author: hearthglass.nvim",
        "## license: MIT",
        "## upstream: %s" % upstream,
        "## blurb: %s face of the %s theme from hearthglass.nvim."
        % (face.capitalize(), THEMES[theme]["name"]),
        "",
        "# %s — kitty theme derived from hearthglass.nvim" % title,
        "background %s" % c["base7"],
        "foreground %s" % c["base0"],
        "cursor %s" % c["orange"],
        "cursor_text_color %s" % c["base7"],
        "selection_background %s" % c["base5"],
        "selection_foreground %s" % c["base0"],
        "url_color %s" % c["blue"],
        "wayland_titlebar_color background",
        "macos_titlebar_color background",
        "",
        "# 16 ANSI colors",
        "color0 %s" % (c["base7"] if kind == "dark" else c["base0"]),
        "color1 %s" % c["red"],
        "color2 %s" % c["green"],
        "color3 %s" % c["yellow"],
        "color4 %s" % c["blue"],
        "color5 %s" % c["purple"],
        "color6 %s" % c["cyan"],
        "color7 %s" % (c["base0"] if kind == "dark" else c["base7"]),
        "color8 %s" % c["base4"],
        "color9 %s" % c["bright_red"],
        "color10 %s" % c["bright_green"],
        "color11 %s" % c["bright_yellow"],
        "color12 %s" % c["bright_blue"],
        "color13 %s" % c["bright_purple"],
        "color14 %s" % c["bright_cyan"],
        "color15 %s" % c["bright_base0"],
    ]
    return "\n".join(lines) + "\n"


# --- kitten commands ---------------------------------------------------------

CACHE_DIR = os.path.join(
    os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "kitty"
)


def _write_conf(theme, kind, opts):
    conf = emit_kitty(theme, kind, opts["low_blue_light"], opts["colorblind"])
    os.makedirs(CACHE_DIR, exist_ok=True)
    path = os.path.join(CACHE_DIR, conf_name(theme, kind))
    with open(path, "w") as f:
        f.write(conf)
    return path, conf


def _current_background():
    try:
        out = subprocess.run(
            ["kitten", "@", "get-colors", "background"],
            capture_output=True, text=True, timeout=10,
        )
        return out.stdout.strip()
    except Exception:
        return ""


def _set_colors(path):
    try:
        subprocess.run(["kitten", "@", "set-colors", path], check=True)
        return True
    except Exception:
        return False


def _apply(theme, kind, opts, action):
    path, _ = _write_conf(theme, kind, opts)
    if _set_colors(path):
        sys.stderr.write(
            "hearthglass: applied %s (%s) terminal theme\n"
            % (THEMES[theme]["name"], "light" if kind == "light" else "dark")
        )
    else:
        _fallback(path, action)


def cmd_night(args):
    opts = _parse_opts(args)
    _apply(opts["theme"], "dark", opts, "night")


def cmd_day(args):
    opts = _parse_opts(args)
    _apply(opts["theme"], "light", opts, "day")


def cmd_toggle(args):
    opts = _parse_opts(args)
    theme = opts["theme"]
    cur = _current_background().lower()
    dark_bg = THEMES[theme]["faces"]["dark"]["plain"]["base7"]
    target = "light" if cur == dark_bg.lower() else "dark"
    _apply(theme, target, opts, "toggle")


def cmd_build(args):
    outdir = args[0] if args and not args[0].startswith("-") else HERE
    rest = args[1:] if args and not args[0].startswith("-") else args
    opts = _parse_opts(rest)
    refresh_palettes()
    os.makedirs(outdir, exist_ok=True)
    themes = [opts["theme"]] if opts["theme_explicit"] else ORDER
    for theme in themes:
        for kind in ("dark", "light"):
            conf = emit_kitty(theme, kind, opts["low_blue_light"], opts["colorblind"])
            path = os.path.join(outdir, conf_name(theme, kind))
            with open(path, "w") as f:
                f.write(conf)
            sys.stderr.write("wrote %s\n" % path)


def cmd_install(args):
    opts = _parse_opts(args)
    refresh_palettes()
    themes = [opts["theme"]] if opts["theme_explicit"] else ORDER
    config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    themes_dir = os.path.join(config_home, "kitty", "themes")
    os.makedirs(themes_dir, exist_ok=True)
    for theme in themes:
        for kind in ("dark", "light"):
            conf = emit_kitty(theme, kind, opts["low_blue_light"], opts["colorblind"])
            with open(os.path.join(themes_dir, conf_name(theme, kind)), "w") as f:
                f.write(conf)
    sys.stderr.write(
        "installed %d theme(s) into %s\n"
        "use `kitten themes` and pick a Hearthglass entry\n"
        % (len(themes), themes_dir)
    )


def cmd_list(args):
    for key in ORDER:
        legacy = " (original)" if THEMES[key].get("legacy") else ""
        sys.stdout.write("%-22s %s%s\n" % (key, THEMES[key]["name"], legacy))


def _fallback(path, action):
    sys.stderr.write(
        "hearthglass: kitty remote control unavailable; wrote %s\n"
        "apply it with: kitten @ set-colors %s\n" % (path, path)
    )


def _parse_opts(args):
    opts = {
        "low_blue_light": False,
        "colorblind": False,
        "theme": "hearthglass",
        "theme_explicit": False,
    }
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--low-blue-light":
            opts["low_blue_light"] = True
        elif a == "--colorblind":
            opts["colorblind"] = True
            if i + 1 < len(args) and not args[i + 1].startswith("-"):
                opts["colorblind"] = args[i + 1]
                i += 1
        elif a == "--theme":
            if i + 1 >= len(args):
                raise SystemExit("--theme needs a key (try `list`)")
            opts["theme"] = args[i + 1]
            opts["theme_explicit"] = True
            i += 1
        i += 1
    if opts["theme"] not in THEMES:
        raise SystemExit("unknown theme: %s (try `list`)" % opts["theme"])
    return opts


def help_text():
    themes = ", ".join(ORDER)
    return """hearthglass — kitty terminal themes for hearthglass.nvim

Run directly with python3 (not as a `kitten` subcommand; kitty only ships its
builtin kittens). Theme changes are applied through the `kitten` CLI tool.

Usage:
  python3 hearthglass.py list
  python3 hearthglass.py night    [--theme KEY] [--low-blue-light] [--colorblind MODE]
  python3 hearthglass.py day      [--theme KEY] [--low-blue-light] [--colorblind MODE]
  python3 hearthglass.py toggle   [--theme KEY] [--low-blue-light] [--colorblind MODE]
  python3 hearthglass.py build    [DIR] [--theme KEY]
  python3 hearthglass.py install  [--theme KEY]
  python3 hearthglass.py help

Themes:
  %s

Options:
  --theme KEY        theme key (default: hearthglass)
  --low-blue-light   light variant only: lift parchment toward white
  --colorblind MODE  deutan | protan | tritan | true

`install` copies every theme's conf into ~/.config/kitty/themes, so you can
switch with the kitten CLI:
  kitten themes                 # interactive picker
  kitten themes seaglass        # dark
  kitten themes seaglass-light

`night`/`day`/`toggle` apply live via `kitten @ set-colors`, which needs kitty
remote control enabled in kitty.conf:
  allow_remote_control yes
  listen_on unix:/tmp/kitty
Otherwise the conf is written and you are told the command to run.""" % themes


COMMANDS = {"list", "night", "day", "toggle", "build", "install", "help"}


def _strip_banner(args):
    # kitty invokes a custom kitten with the full argv:
    #   main(['kitten', 'hearthglass', 'night', ...])
    # while direct runs pass the command first:
    #   python3 hearthglass.py night   ->  main(['night', ...])
    # Strip the leading 'kitten' / kitten-name tokens so both resolve to the
    # command name. Options are expected after the command.
    while args and args[0] not in COMMANDS:
        if args[0] in ("--low-blue-light", "--colorblind", "--theme"):
            break
        args = args[1:]
    return args


def main(args):
    load_palettes()
    args = _strip_banner(list(args))
    if not args:
        sys.stderr.write(help_text() + "\n")
        return
    cmd = args[0]
    rest = args[1:]
    handlers = {
        "list": cmd_list,
        "night": cmd_night,
        "day": cmd_day,
        "toggle": cmd_toggle,
        "build": cmd_build,
        "install": cmd_install,
        "help": lambda a: sys.stderr.write(help_text() + "\n"),
    }
    handler = handlers.get(cmd)
    if handler is None:
        sys.stderr.write("unknown command: %s\n\n%s\n" % (cmd, help_text()))
        return
    handler(rest)


if __name__ == "__main__":
    main(sys.argv[1:])
