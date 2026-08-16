#!/usr/bin/env python
# ============================================================================
# hearthglass.py — generator + switcher for kitty terminal themes derived from
# the same Ember palette used by the hearthglass.nvim colorscheme.
#
# Run it directly with python3 (NOT as a `kitten` subcommand; kitty only ships
# its builtin kittens). It delegates the actual theme changes to the `kitten`
# CLI tool, which is what you configure kitty through.
#
# It mirrors lua/hearthglass/colors.lua: the dark and light variants share the
# same accents/ramp, and the same two options are honored:
#   --low-blue-light   (light only) lift the parchment toward white
#   --colorblind MODE  deutan|protan|tritan|true  (same red/green remap)
#
# Commands:
#   python3 hearthglass.py night          apply the dark theme live
#   python3 hearthglass.py day            apply the light theme live
#   python3 hearthglass.py toggle         switch between day and night
#   python3 hearthglass.py build [DIR]    write hearthglass.conf / -light.conf
#   python3 hearthglass.py install        copy confs into ~/.config/kitty/themes
#   python3 hearthglass.py help           show this message
#
# Two ways to switch themes through the kitten CLI:
#   * interactive/persistent:  kitten themes   (pick hearthglass / -light)
#   * live (no config edit):   kitten @ set-colors <conf-file>
# The `night`/`day`/`toggle` commands call the latter. `kitten @ set-colors`
# needs kitty remote control enabled (`allow_remote_control yes` and
# `listen_on` in kitty.conf); without it, the conf is written and you are told
# the command to run.
# ============================================================================

import os
import sys
import subprocess

# --- palette (mirrors lua/hearthglass/colors.lua) ---------------------------

ACCENTS = {
    "dark": {
        "orange": "#e0893d",
        "yellow": "#e0bd58",
        "cyan": "#6f9a8c",
        "green": "#98a45c",
        "blue": "#7d94ab",
        "purple": "#a58e9c",
        "pink": "#c98f74",
        "red": "#dd5c4a",
    },
    "light": {
        "orange": "#93491c",
        "yellow": "#8a6a1a",
        "cyan": "#386858",
        "green": "#4a6830",
        "blue": "#3a6080",
        "purple": "#706070",
        "pink": "#905050",
        "red": "#b84c30",
    },
}

PALETTES = {
    "dark": {
        "base0": "#e6d3a3",
        "base1": "#c7b48c",
        "base2": "#a99874",
        "base3": "#94836a",
        "base4": "#6a5c46",
        "base5": "#54452f",
        "base6": "#3a322a",
        "base7": "#1b1612",
    },
    "light": {
        "base0": "#282418",
        "base1": "#484030",
        "base2": "#585040",
        "base3": "#605848",
        "base4": "#787060",
        "base5": "#989080",
        "base6": "#ddd0b8",
        "base7": "#e6dac4",
    },
}

DARK_TINTS = {
    "light_orange": "#523823",
    "light_yellow": "#524625",
    "light_cyan": "#36473f",
    "light_green": "#414826",
    "light_blue": "#384a5a",
    "light_purple": "#4b3d4a",
    "light_pink": "#523a2e",
    "light_red": "#573128",
}


def blend(c1, c2, amount):
    def ch(hexstr, start):
        return int(hexstr[start:start + 2], 16)

    def mix(a, b):
        return int(round(a * amount + b * (1 - amount)))

    return "#%02x%02x%02x" % (
        mix(ch(c1, 1), ch(c2, 1)),
        mix(ch(c1, 3), ch(c2, 3)),
        mix(ch(c1, 5), ch(c2, 5)),
    )


def get_colors(kind, low_blue_light=False, colorblind=False):
    palette = dict(PALETTES[kind])
    accents = dict(ACCENTS[kind])
    tints = dict(DARK_TINTS)

    if colorblind is True:
        colorblind = "deutan"
    elif colorblind == "protan":
        colorblind = "deutan"

    if colorblind in ("deutan", "tritan"):
        if colorblind == "deutan":
            if kind == "dark":
                accents["red"] = "#d96a6f"
                accents["green"] = "#5f9c8b"
                accents["cyan"] = "#5f8098"
                tints["light_green"] = "#33453c"
                tints["light_red"] = "#4a3038"
            else:
                accents["red"] = "#a84a5a"
                accents["green"] = "#3f6e60"
                accents["cyan"] = "#4a6a80"
        else:  # tritan
            if kind == "dark":
                accents["blue"] = "#8579ae"
                accents["cyan"] = "#5f8098"
                tints["light_blue"] = "#3a3448"
            else:
                accents["blue"] = "#5c5690"
                accents["cyan"] = "#4a6a80"

    palette.update(accents)
    palette["iris"] = accents["purple"]
    palette["muted"] = palette["base3"]

    if low_blue_light and kind == "light":
        palette["base7"] = blend("#ffffff", palette["base7"], 0.35)

    tint_names = {
        "light_orange": "orange",
        "light_yellow": "yellow",
        "light_cyan": "cyan",
        "light_green": "green",
        "light_blue": "blue",
        "light_purple": "purple",
        "light_pink": "pink",
        "light_red": "red",
    }
    for light_name, accent_name in tint_names.items():
        if kind == "dark":
            palette[light_name] = tints[light_name]
        else:
            palette[light_name] = blend(
                accents[accent_name], palette["base7"], 0.18
            )

    # bright (color9..15) accents: lighter, more vivid versions of the accents
    bright = lambda c: blend(c, "#ffffff", 0.22)
    for name in ("red", "green", "yellow", "blue", "purple", "cyan"):
        palette["bright_" + name] = bright(accents[name])
    # color15 is the light end of the theme: brightened foreground (dark) or
    # brightened background (light).
    light_end = palette["base0"] if kind == "dark" else palette["base7"]
    palette["bright_base0"] = blend(light_end, "#ffffff", 0.3 if kind == "light" else 0.2)

    return palette


def emit_kitty(kind, low_blue_light=False, colorblind=False):
    c = get_colors(kind, low_blue_light, colorblind)
    title = "hearthglass" if kind == "dark" else "hearthglass-light"
    lines = [
        "# %s — kitty theme derived from hearthglass.nvim (Ember palette)" % title,
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


def _write_conf(kind, opts):
    conf = emit_kitty(kind, opts["low_blue_light"], opts["colorblind"])
    os.makedirs(CACHE_DIR, exist_ok=True)
    path = os.path.join(CACHE_DIR, "hearthglass-%s.conf" % kind)
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


def cmd_night(args):
    opts = _parse_opts(args)
    path, _ = _write_conf("dark", opts)
    if _set_colors(path):
        sys.stderr.write("hearthglass: applied dark terminal theme\n")
    else:
        _fallback(path, "night")


def cmd_day(args):
    opts = _parse_opts(args)
    path, _ = _write_conf("light", opts)
    if _set_colors(path):
        sys.stderr.write("hearthglass: applied light terminal theme\n")
    else:
        _fallback(path, "day")


def cmd_toggle(args):
    opts = _parse_opts(args)
    cur = _current_background().lower()
    target = "light" if cur == PALETTES["dark"]["base7"].lower() else "dark"
    path, _ = _write_conf(target, opts)
    if _set_colors(path):
        label = "light" if target == "light" else "dark"
        sys.stderr.write("hearthglass: toggled to %s terminal theme\n" % label)
    else:
        _fallback(path, "toggle")


def cmd_build(args):
    outdir = args[0] if args else os.path.dirname(os.path.abspath(__file__))
    opts = _parse_opts(args[1:])
    for kind in ("dark", "light"):
        conf = emit_kitty(kind, opts["low_blue_light"], opts["colorblind"])
        name = "hearthglass.conf" if kind == "dark" else "hearthglass-light.conf"
        path = os.path.join(outdir, name)
        with open(path, "w") as f:
            f.write(conf)
        sys.stderr.write("wrote %s\n" % path)


def cmd_install(args):
    opts = _parse_opts(args)
    themes_dir = os.path.expanduser("~/.config/kitty/themes")
    os.makedirs(themes_dir, exist_ok=True)
    for kind in ("dark", "light"):
        conf = emit_kitty(kind, opts["low_blue_light"], opts["colorblind"])
        name = "hearthglass.conf" if kind == "dark" else "hearthglass-light.conf"
        with open(os.path.join(themes_dir, name), "w") as f:
            f.write(conf)
    sys.stderr.write(
        "installed themes into %s\n"
        "use `kitten themes` and pick hearthglass / hearthglass-light\n" % themes_dir
    )


def _fallback(path, action):
    sys.stderr.write(
        "hearthglass: kitty remote control unavailable; wrote %s\n"
        "apply it with: kitten @ set-colors %s\n" % (path, path)
    )


def _parse_opts(args):
    opts = {"low_blue_light": False, "colorblind": False}
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--low-blue-light":
            opts["low_blue_light"] = True
        elif a == "--colorblind":
            opts["colorblind"] = args[i + 1] if i + 1 < len(args) else True
            i += 1
        i += 1
    return opts


HELP = """hearthglass — kitty terminal themes for hearthglass.nvim

Run directly with python3 (not as a `kitten` subcommand; kitty only ships its
builtin kittens). Theme changes are applied through the `kitten` CLI tool.

Usage:
  python3 hearthglass.py night    [--low-blue-light] [--colorblind MODE]
  python3 hearthglass.py day      [--low-blue-light] [--colorblind MODE]
  python3 hearthglass.py toggle   [--low-blue-light] [--colorblind MODE]
  python3 hearthglass.py build    [DIR]
  python3 hearthglass.py install
  python3 hearthglass.py help

Options:
  --low-blue-light   light variant only: lift parchment toward white
  --colorblind MODE  deutan | protan | tritan | true

`install` copies hearthglass.conf / hearthglass-light.conf into
~/.config/kitty/themes, so you can switch with the kitten CLI:
  kitten themes                # pick hearthglass / hearthglass-light
  kitten themes hearthglass    # switch to dark non-interactively
  kitten themes hearthglass-light

`night`/`day`/`toggle` apply live via `kitten @ set-colors`, which needs kitty
remote control enabled in kitty.conf:
  allow_remote_control yes
  listen_on unix:/tmp/kitty
Otherwise the conf is written and you are told the command to run."""


COMMANDS = {"night", "day", "toggle", "build", "install", "help"}


def _strip_banner(args):
    # kitty invokes a custom kitten with the full argv:
    #   main(['kitten', 'hearthglass', 'night', ...])
    # while direct runs pass the command first:
    #   python3 hearthglass.py night   ->  main(['night', ...])
    # Strip the leading 'kitten' / kitten-name tokens so both resolve to the
    # command name.
    while args and args[0] not in COMMANDS:
        if args[0] in ("--low-blue-light", "--colorblind"):
            break
        args = args[1:]
    return args


def main(args):
    args = _strip_banner(list(args))
    if not args:
        sys.stderr.write(HELP + "\n")
        return
    cmd = args[0]
    rest = args[1:]
    handlers = {
        "night": cmd_night,
        "day": cmd_day,
        "toggle": cmd_toggle,
        "build": cmd_build,
        "install": cmd_install,
        "help": lambda a: sys.stderr.write(HELP + "\n"),
    }
    handler = handlers.get(cmd)
    if handler is None:
        sys.stderr.write("unknown command: %s\n\n%s\n" % (cmd, HELP))
        return
    handler(rest)


if __name__ == "__main__":
    main(sys.argv[1:])
