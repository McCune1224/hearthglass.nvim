#!/usr/bin/env python3
"""Build the hearthglass KDE Plasma 6 global themes.

The layout, component set and visual language follow Clay by Artt
(https://github.com/arttvad9r/clay-kde-theme, LGPL-2.1-or-later), retargeted
from Clay's single ivory/terracotta palette to every hearthglass palette:

    hearthglass, stainedglass, flameglass, cranberryglass, seaglass, smokedglass, frostedglass, cathedralglass, leadedglass

Each palette is built in both faces, so eighteen Global Themes come out of it.

Palettes are exported from lua/hearthglass/themes.lua by kde/export.lua.
Run from the repository root:

    nvim --headless -l kde/export.lua
    python3 kde/build.py
"""

from __future__ import annotations

import html
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
PAYLOAD = ROOT / "payload"
TEMPLATES = ROOT / "templates"
TOOLS = ROOT / "tools"

PALETTES = json.loads((ROOT / "palettes.json").read_text())
THEMES = json.loads((ROOT / "themes.json").read_text())["themes"]
SHARED = json.loads((ROOT / "themes.json").read_text())["shared"]

WEBSITE = "https://github.com/McCune1224/hearthglass.nvim"
AUTHOR = "Hearthglass"
LICENSE = "LGPL-2.1-or-later"
UPSTREAM = "Clay by Artt (https://github.com/arttvad9r/clay-kde-theme)"


# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------

def rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def hx(value) -> str:
    if isinstance(value, str):
        return value.lower()
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(c))) for c in value)


def mix(a: str, b: str, amount: float) -> str:
    """Blend a and b; amount=1 returns a, amount=0 returns b (same as Lua)."""
    ca, cb = rgb(a), rgb(b)
    return hx(tuple(ca[i] * amount + cb[i] * (1 - amount) for i in range(3)))


def combo(value: str) -> str:
    return ",".join(str(c) for c in rgb(value))


def face(palette: dict, dark: bool) -> dict:
    """Semantic roles for one face, derived from a hearthglass palette."""
    p = palette
    base0, base3, base4 = p["base0"], p["base3"], p["base4"]
    base5, base6, base7 = p["base5"], p["base6"], p["base7"]
    accent = p["orange"]            # crimson hero
    terracotta = p["pink"]
    gold, green, blue = p["yellow"], p["green"], p["blue"]
    purple, cyan = p["purple"], p["cyan"]

    if dark:
        # Two stepped surfaces above the editor background, as in Clay:
        # window sits between the view and the raised button/panel paper.
        window = mix(base6, base7, 0.45)
        view = base7
        button = base6
        header = mix(base6, base7, 0.60)
        complementary = mix(base7, "#000000", 0.68)
        alternate = mix(base6, base7, 0.72)
        selection = mix(base5, accent, 0.86)
        tooltip_bg = mix(base6, base0, 0.92)
        tooltip_fg = base0
        tooltip_inactive = mix(base0, tooltip_bg, 0.7)
        tooltip_accent = mix(accent, base0, 0.8)
        tooltip_negative, tooltip_neutral = p["red"], gold
        tooltip_positive, tooltip_visited = green, terracotta
        disabled = base3
        effect_color = base3
    else:
        window = base6
        view = base7
        button = base7
        header = base6
        complementary = mix(base6, base0, 0.96)
        alternate = mix(base7, base0, 0.96)
        selection = mix(base6, accent, 0.92)
        tooltip_bg = mix(base0, "#000000", 0.9)
        tooltip_fg = base7
        tooltip_inactive = mix(base7, tooltip_bg, 0.62)
        tooltip_accent = mix(accent, "#ffffff", 0.45)
        tooltip_negative = mix(p["red"], "#ffffff", 0.45)
        tooltip_neutral = mix(gold, "#ffffff", 0.45)
        tooltip_positive = mix(green, "#ffffff", 0.45)
        tooltip_visited = mix(terracotta, "#ffffff", 0.45)
        disabled = base3
        effect_color = base3

    return {
        "dark": dark,
        "bg": base7,
        "bg2": base6,
        "window": window,
        "view": view,
        "button": button,
        "header": header,
        "complementary": complementary,
        "alternate": alternate,
        "selection": selection,
        "fg": base0,
        "comment": base3,
        "muted": base4,
        "accent": accent,
        "accent_hover": mix(accent, base0, 0.82),
        "terracotta": terracotta,
        "gold": gold,
        "green": green,
        "blue": blue,
        "purple": purple,
        "cyan": cyan,
        "red": p["red"],
        "negative": p["red"],
        "tooltip_bg": tooltip_bg,
        "tooltip_fg": tooltip_fg,
        "tooltip_inactive": tooltip_inactive,
        "tooltip_accent": tooltip_accent,
        "tooltip_negative": tooltip_negative,
        "tooltip_neutral": tooltip_neutral,
        "tooltip_positive": tooltip_positive,
        "tooltip_visited": tooltip_visited,
        "disabled": disabled,
        "effect_color": effect_color,
        "light_red": p["light_red"],
        "light_orange": p["light_orange"],
    }


# ---------------------------------------------------------------------------
# Colour scheme
# ---------------------------------------------------------------------------



def scheme_text(c: dict, scheme_id: str, display_name: str) -> str:
    def block(name, bg, alt, fg, inactive, active, link, negative, neutral, positive, visited):
        return (
            f"[Colors:{name}]\n"
            f"BackgroundAlternate={combo(alt)}\n"
            f"BackgroundNormal={combo(bg)}\n"
            f"DecorationFocus={combo(c['accent'])}\n"
            f"DecorationHover={combo(c['accent_hover'])}\n"
            f"ForegroundActive={combo(active)}\n"
            f"ForegroundInactive={combo(inactive)}\n"
            f"ForegroundLink={combo(link)}\n"
            f"ForegroundNegative={combo(negative)}\n"
            f"ForegroundNeutral={combo(neutral)}\n"
            f"ForegroundNormal={combo(fg)}\n"
            f"ForegroundPositive={combo(positive)}\n"
            f"ForegroundVisited={combo(visited)}\n"
        )

    common = dict(active=c["accent"], link=c["accent"], negative=c["negative"],
                  neutral=c["gold"], positive=c["green"], visited=c["terracotta"])
    parts = [
        "[ColorEffects:Disabled]\n"
        f"Color={combo(c['disabled'])}\nColorAmount=0\nColorEffect=0\n"
        "ContrastAmount=0.65\nContrastEffect=1\nIntensityAmount=0.1\nIntensityEffect=2\n",
        "[ColorEffects:Inactive]\n"
        "ChangeSelectionColor=true\n"
        f"Color={combo(c['effect_color'])}\nColorAmount=0.025\nColorEffect=2\n"
        "ContrastAmount=0.1\nContrastEffect=2\nEnable=false\nIntensityAmount=0\nIntensityEffect=0\n",
    ]

    parts.append(block("Button", c["button"], c["alternate"], c["fg"], c["comment"], **common))
    parts.append(block("Complementary", c["complementary"], c["alternate"], c["fg"],
                       c["comment"], **common))
    parts.append(block("Header", c["header"], c["alternate"], c["fg"], c["comment"], **common))

    header_inactive = (
        f"[Colors:Header][Inactive]\n"
        f"BackgroundAlternate={combo(c['alternate'])}\n"
        f"BackgroundNormal={combo(c['header'])}\n"
        f"DecorationFocus={combo(c['accent'])}\n"
        f"DecorationHover={combo(c['accent_hover'])}\n"
        f"ForegroundActive={combo(c['accent'])}\n"
        f"ForegroundInactive={combo(c['comment'])}\n"
        f"ForegroundLink={combo(c['accent'])}\n"
        f"ForegroundNegative={combo(c['negative'])}\n"
        f"ForegroundNeutral={combo(c['gold'])}\n"
        f"ForegroundNormal={combo(c['comment'])}\n"
        f"ForegroundPositive={combo(c['green'])}\n"
        f"ForegroundVisited={combo(c['terracotta'])}\n"
    )
    parts.append(header_inactive)
    parts.append(block("Selection", c["selection"], c["alternate"], c["fg"],
                       c["comment"], **common))

    tooltip = (
        f"[Colors:Tooltip]\n"
        f"BackgroundAlternate={combo(mix(c['tooltip_bg'], c['tooltip_fg'], 0.94))}\n"
        f"BackgroundNormal={combo(c['tooltip_bg'])}\n"
        f"DecorationFocus={combo(c['accent'])}\n"
        f"DecorationHover={combo(c['accent_hover'])}\n"
        f"ForegroundActive={combo(c['tooltip_accent'])}\n"
        f"ForegroundInactive={combo(c['tooltip_inactive'])}\n"
        f"ForegroundLink={combo(c['tooltip_accent'])}\n"
        f"ForegroundNegative={combo(c['tooltip_negative'])}\n"
        f"ForegroundNeutral={combo(c['tooltip_neutral'])}\n"
        f"ForegroundNormal={combo(c['tooltip_fg'])}\n"
        f"ForegroundPositive={combo(c['tooltip_positive'])}\n"
        f"ForegroundVisited={combo(c['tooltip_visited'])}\n"
    )
    parts.append(tooltip)
    parts.append(block("View", c["view"], c["alternate"], c["fg"], c["comment"], **common))
    parts.append(block("Window", c["window"], c["alternate"], c["fg"], c["comment"], **common))
    parts.append(
        f"[General]\nColorScheme={scheme_id}\nName={display_name}\nshadeSortColumn=true\n\n"
        "[KDE]\ncontrast=4\n\n"
        f"[WM]\nactiveBackground={combo(c['window'])}\nactiveBlend={combo(c['window'])}\n"
        f"activeForeground={combo(c['fg'])}\ninactiveBackground={combo(c['window'])}\n"
        f"inactiveBlend={combo(c['window'])}\ninactiveForeground={combo(c['comment'])}\n"
    )
    return "".join(parts)


# ---------------------------------------------------------------------------
# SVG helpers
# ---------------------------------------------------------------------------

def recolor_svg(text: str, mapping: dict[str, str]) -> str:
    for source, target in sorted(mapping.items(), key=lambda kv: len(kv[0]), reverse=True):
        text = re.sub(re.escape(source), target, text, flags=re.IGNORECASE)
    return text


def write_svgz(path: Path, text: str) -> None:
    import gzip
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(gzip.compress(text.encode(), mtime=0))


def read_svgz(path: Path) -> str:
    import gzip
    return gzip.decompress(path.read_bytes()).decode()


def render_svg(svg: Path, out: Path, width: int, height: int | None = None,
               quality: int | None = None) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    size = f"{width}x{height}!" if height else str(width)
    cmd = ["magick", "-background", "none", str(svg), "-resize", size]
    if quality is not None or out.suffix.lower() in (".jpg", ".jpeg"):
        cmd += ["-quality", str(quality or 88)]
    cmd.append(str(out))
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def run_tool(script: str, env: dict[str, str]) -> None:
    merged = {**os.environ, **env}
    subprocess.run([sys.executable, str(TOOLS / script)], check=True, env=merged)
    print(f"  {script}")


# ---------------------------------------------------------------------------
# Palette mapping for Clay-derived assets
# ---------------------------------------------------------------------------

def clay_mapping(c: dict) -> dict[str, str]:
    """Clay literal -> hearthglass colour, for static Clay SVGs/Kate themes."""
    return {
        "#D97757": c["accent"],
        "#C6613F": c["accent_hover"],
        "#FAF9F5": c["bg"],
        "#F0EEE6": c["bg2"],
        "#141413": c["fg"],
        "#1F1E1D": c["fg"],
        "#5E7045": c["green"],
        "#A06A2C": c["gold"],
        "#B5473A": c["negative"],
        "#D4A27F": c["terracotta"],
        "#EBDBBC": mix(c["bg"], c["terracotta"], 0.8),
        "#87867F": c["comment"],
    }


def icon_palette(palette: dict) -> dict[str, str]:
    """Opaque icon palette: light paper, bright accent, same on both faces."""
    light, dark = palette["light"], palette["dark"]
    paper = light["base7"]
    ink = light["base0"]
    accent = dark["orange"]
    kraft = mix(paper, light["pink"], 0.55)
    return {
        "accent": accent,
        "accent_deep": mix(accent, ink, 0.82),
        "kraft": kraft,
        "manilla": mix(paper, light["pink"], 0.84),
        "ivory": paper,
        "grey_l": mix(paper, ink, 0.88),
        "grey": mix(paper, ink, 0.74),
        "grey_d": mix(paper, ink, 0.52),
        "glyph": mix(accent, ink, 0.82),
        "slate": ink,
        "sky": light["blue"],
        "olive": light["green"],
        "fig": mix(dark["orange"], light["blue"], 0.55),
        "heather": mix(light["orange"], light["blue"], 0.55),
        "kraft_d": mix(kraft, ink, 0.86),
        "paper": paper,
        "paper_edge": mix(paper, ink, 0.88),
        "paper_fold": mix(paper, light["pink"], 0.9),
        "card": paper,
        "card_edge": mix(paper, ink, 0.88),
        "neutral": light["yellow"],
        "negative": light["red"],
        "ink": ink,
    }


# ---------------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------------

def build_scheme(theme: dict, dark: bool, c: dict) -> Path:
    scheme_id = theme["scheme_dark"] if dark else theme["scheme"]
    display = theme["name"] + (" Dark" if dark else "")
    path = PAYLOAD / "color-schemes" / f"{scheme_id}.colors"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(scheme_text(c, scheme_id, display))
    return path


def build_plasma_style(theme: dict, dark: bool, c: dict, scheme_path: Path) -> None:
    style = theme["plasma_dark"] if dark else theme["plasma"]
    dst = PAYLOAD / "plasma" / "desktoptheme" / style
    shutil.copytree(TEMPLATES / "plasma" / "desktoptheme", dst)

    mapping = clay_mapping(c)
    for path in (dst / "widgets").glob("*.svgz"):
        if path.stem in ("button", "lineedit", "tasks"):
            continue
        path.write_bytes(__import__("gzip").compress(
            recolor_svg(read_svgz(path), mapping).encode(), mtime=0))
    background = dst / "dialogs" / "background.svgz"
    background.write_bytes(__import__("gzip").compress(
        recolor_svg(read_svgz(background), mapping).encode(), mtime=0))

    meta = {
        "KPlugin": {
            "Authors": [{"Name": AUTHOR}],
            "Category": "",
            "Description": f"{theme['name']} {('Dark ' if dark else '')}Plasma style, after Clay",
            "EnabledByDefault": False,
            "Id": style,
            "License": LICENSE,
            "Name": theme["name"] + (" Dark" if dark else ""),
            "Version": "1.0",
            "Website": WEBSITE,
        },
        "X-Plasma-API": "5.0",
    }
    (dst / "metadata.json").write_text(json.dumps(meta, indent=2) + "\n")
    (dst / "plasmarc").write_text(
        "[Settings]\nFallbackTheme=default\n\n"
        "[AdaptiveTransparency]\nenabled=false\n\n"
        "[ContrastEffect]\nenabled=false\n"
    )
    shutil.copyfile(scheme_path, dst / "colors")

    run_tool("gen_plasma_widgets.py", {
        "HG_PLASMA_OUT": str(dst / "widgets"),
        "HG_PLASMA_PALETTE": json.dumps(c),
    })


def build_aurorae(theme: dict, dark: bool, c: dict) -> None:
    name = theme["decoration_dark"] if dark else theme["decoration"]
    run_tool("gen_aurorae.py", {
        "HG_AURORAE_OUT": str(PAYLOAD / "aurorae" / "themes"),
        "HG_AURORAE": json.dumps({
            "name": name,
            "display": theme["name"] + (" Dark" if dark else ""),
            "text": combo(c["fg"]),
            "background": combo(c["window"]),
            "accent": c["accent"],
            "on_accent": combo(c["bg"]),
            "line": 0.1 if dark else 0.16,
            "line_inactive": 0.05 if dark else 0.08,
            "website": WEBSITE,
        }),
    })


def mark_svg(c: dict, size: int = 64) -> str:
    """A simplified hearth arch and flame, drawn from the two theme colours."""
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="{size}" height="{size}">
  <path d="M11 55V27a21 21 0 0 1 42 0v28" fill="none" stroke="{c['fg']}" stroke-width="4" stroke-linecap="round"/>
  <path d="M20 55h24" stroke="{c['fg']}" stroke-width="4" stroke-linecap="round"/>
  <path d="M32 51c-7.6-5.4-10.6-11.4-7.8-17.4 1.9-4.1 5.4-6.6 6.6-12.1 4.4 5.3 9.7 8.9 9.7 15.9 0 5.7-3.3 10.6-8.5 13.6z" fill="{c['accent']}"/>
</svg>
'''


def field_svg(c: dict, width: int = 3840, height: int = 2160) -> str:
    """Clay's wallpaper composition: gradient ground, two clay slabs, a mark."""
    a = mix(c["bg"], c["bg2"], 0.55)
    b = c["bg"]
    slab = c["terracotta"] if c["dark"] else mix(c["bg2"], c["terracotta"], 0.72)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{a}"/>
      <stop offset="1" stop-color="{b}"/>
    </linearGradient>
  </defs>
  <rect width="{width}" height="{height}" fill="url(#bg)"/>
  <rect x="{width * 0.65:g}" y="{-height * 0.12:g}" width="{width * 0.43:g}" height="{height * 0.42:g}" rx="{height * 0.15:g}"
        fill="{c['accent']}" opacity="{0.78 if c['dark'] else 0.88}" transform="rotate(-7 {width * 0.65:g} {-height * 0.12:g})"/>
  <rect x="{-width * 0.12:g}" y="{height * 0.69:g}" width="{width * 0.49:g}" height="{height * 0.38:g}" rx="{height * 0.17:g}"
        fill="{slab}" transform="rotate(5 {-width * 0.12:g} {height * 0.69:g})"/>
  <g transform="translate({width * 0.78:g} {height * 0.47:g}) scale({height / 2160 * 8:g})" opacity="{0.10 if c['dark'] else 0.08}"
     fill="none" stroke="{c['fg']}" stroke-width="4" stroke-linecap="round">
    <path d="M11 55V27a21 21 0 0 1 42 0v28"/>
    <path d="M20 55h24"/>
    <path d="M32 51c-7.6-5.4-10.6-11.4-7.8-17.4 1.9-4.1 5.4-6.6 6.6-12.1 4.4 5.3 9.7 8.9 9.7 15.9 0 5.7-3.3 10.6-8.5 13.6z" fill="{c['fg']}" stroke="none"/>
  </g>
</svg>
'''


def build_wallpaper(theme: dict, dark: bool, c: dict) -> None:
    name = theme["wallpaper_dark"] if dark else theme["wallpaper"]
    dst = PAYLOAD / "wallpapers" / name
    (dst / "contents" / "images").mkdir(parents=True)
    field = dst / "contents" / "field.svg"
    field.write_text(field_svg(c))
    render_svg(field, dst / "contents" / "images" / "3840x2160.png", 3840, 2160)
    render_svg(field, dst / "contents" / "screenshot.png", 400, 225)
    (dst / "metadata.json").write_text(json.dumps({
        "KPlugin": {
            "Authors": [{"Name": AUTHOR}],
            "Id": name,
            "License": "CC0-1.0",
            "Name": f"{theme['name']} Field" + (" Dark" if dark else ""),
            "Version": "1.0",
            "Website": WEBSITE,
        }
    }, indent=2) + "\n")


def build_lnf(theme: dict, dark: bool, c: dict, scheme_path: Path) -> None:
    lnf = theme["lnf_dark"] if dark else theme["lnf"]
    dst = PAYLOAD / "plasma" / "look-and-feel" / lnf
    contents = dst / "contents"
    contents.mkdir(parents=True)

    shutil.copytree(TEMPLATES / "plasma" / "look-and-feel" / "logout", contents / "logout")
    shutil.copytree(TEMPLATES / "plasma" / "look-and-feel" / "plasmoidsetupscripts",
                    contents / "plasmoidsetupscripts")
    kickoff = contents / "plasmoidsetupscripts" / "org.kde.plasma.kickoff.js"
    kickoff.write_text(kickoff.read_text().replace("clay-launcher", "hearthglass-launcher"))

    splash = contents / "splash"
    (splash / "images").mkdir(parents=True)
    qml = (TEMPLATES / "plasma" / "look-and-feel" / "splash" / "Splash.qml").read_text()
    qml = qml.replace('color: "#F0EEE6"', f'color: "{c["bg"]}"')
    qml = qml.replace('color: "#D1CFC5"', f'color: "{mix(c["bg"], c["fg"], 0.8)}"')
    qml = qml.replace('color: "#D97757"', f'color: "{c["accent"]}"')
    qml = qml.replace("images/clay-mark.svg", "images/hearthglass-mark.svg")
    (splash / "Splash.qml").write_text(qml)
    (splash / "images" / "hearthglass-mark.svg").write_text(mark_svg(c))

    field = dst / "contents" / "splash" / "images" / "field.svg"
    field.write_text(field_svg(c, 2560, 1440))
    render_svg(field, splash / "images" / "background.png", 2560, 1440)

    scheme_name = theme["scheme_dark"] if dark else theme["scheme"]
    decoration = theme["decoration_dark"] if dark else theme["decoration"]
    style = theme["plasma_dark"] if dark else theme["plasma"]
    wallpaper = theme["wallpaper_dark"] if dark else theme["wallpaper"]
    kate = theme["kate_dark"] if dark else theme["kate"]

    (contents / "defaults").write_text(f"""[Wallpaper]
Image={wallpaper}

[kdeglobals][General]
ColorScheme={scheme_name}

[kdeglobals][Icons]
Theme={theme['icons']}

[kdeglobals][KDE]
widgetStyle=Breeze

[kwinrc][TabBox]
LayoutName={SHARED['tabbox']}

[kwinrc][org.kde.kdecoration2]
library=org.kde.kwin.aurorae
theme=__aurorae__svg__{decoration}

[plasmarc][Theme]
name={style}
""")
    shutil.copyfile(scheme_path, contents / "colors")

    previews = contents / "previews"
    previews.mkdir()
    preview_svg = previews / "preview.svg"
    preview_svg.write_text(preview_art(theme, c, dark))
    render_svg(preview_svg, previews / "preview.png", 600, 337)
    render_svg(preview_svg, previews / "splash.png", 600, 337)
    render_svg(preview_svg, previews / "lockscreen.png", 600, 337)
    render_svg(preview_svg, previews / "fullscreenpreview.jpg", 1920, 1080, quality=88)
    preview_svg.unlink()

    extras = dst / "extras"
    extras.mkdir()
    (extras / "hearthglass-launcher.svg").write_text(mark_svg(c))

    display = theme["name"] + (" Dark" if dark else "")
    (dst / "metadata.json").write_text(json.dumps({
        "KPackageStructure": "Plasma/LookAndFeel",
        "KPlugin": {
            "Authors": [{"Name": AUTHOR}],
            "Category": "",
            "Description": f"{theme['name']} — {theme['tagline']}. A Clay-shaped Plasma theme.",
            "Id": lnf,
            "License": LICENSE,
            "Name": display,
            "Version": "1.0",
            "Website": WEBSITE,
        },
        "X-Plasma-APIVersion": "2",
    }, indent=2) + "\n")


def preview_art(theme: dict, c: dict, dark: bool) -> str:
    """A small, honest preview: the field, the mark, the theme name."""
    display = html.escape(theme["name"] + (" Dark" if dark else ""))
    tagline = html.escape(theme["tagline"])
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 337">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{mix(c['bg'], c['bg2'], 0.55)}"/>
      <stop offset="1" stop-color="{c['bg']}"/>
    </linearGradient>
  </defs>
  <rect width="600" height="337" fill="url(#bg)"/>
  <rect x="398" y="-38" width="270" height="150" rx="54" fill="{c['accent']}" opacity="{0.78 if dark else 0.88}" transform="rotate(-7 398 -38)"/>
  <rect x="-70" y="228" width="300" height="130" rx="56" fill="{mix(c['bg2'], c['terracotta'], 0.72)}" transform="rotate(5 -70 228)"/>
  <rect x="150" y="62" width="300" height="196" rx="18" fill="{c['window']}" opacity="0.94"/>
  <rect x="150" y="62" width="300" height="30" rx="18" fill="{c['header']}"/>
  <circle cx="168" cy="77" r="4" fill="{c['accent']}"/>
  <text x="182" y="82" font-family="Inter, Cantarell, sans-serif" font-size="11" fill="{c['fg']}">{display}</text>
  <g transform="translate(272 112) scale(0.9)">
    <path d="M11 55V27a21 21 0 0 1 42 0v28" fill="none" stroke="{c['fg']}" stroke-width="4" stroke-linecap="round"/>
    <path d="M20 55h24" stroke="{c['fg']}" stroke-width="4" stroke-linecap="round"/>
    <path d="M32 51c-7.6-5.4-10.6-11.4-7.8-17.4 1.9-4.1 5.4-6.6 6.6-12.1 4.4 5.3 9.7 8.9 9.7 15.9 0 5.7-3.3 10.6-8.5 13.6z" fill="{c['accent']}"/>
  </g>
  <text x="300" y="202" text-anchor="middle" font-family="Inter, Cantarell, sans-serif" font-size="15" fill="{c['fg']}">{display}</text>
  <text x="300" y="220" text-anchor="middle" font-family="Inter, Cantarell, sans-serif" font-size="9" fill="{c['comment']}">{tagline}</text>
  <rect x="252" y="236" width="96" height="4" rx="2" fill="{mix(c['bg'], c['fg'], 0.8)}"/>
  <rect x="252" y="236" width="34" height="4" rx="2" fill="{c['accent']}"/>
</svg>
'''


def build_kate(theme: dict, dark: bool, c: dict) -> None:
    name = theme["kate_dark"] if dark else theme["kate"]
    styles = [
        ("Normal", c["fg"], {}),
        ("Keyword", c["accent"], {"bold": True}),
        ("ControlFlow", c["accent"], {"bold": True}),
        ("Function", c["blue"], {}),
        ("Variable", c["cyan"], {}),
        ("Operator", c["comment"], {}),
        ("BuiltIn", c["purple"], {}),
        ("Extension", c["blue"], {"bold": True}),
        ("Preprocessor", c["gold"], {}),
        ("Attribute", c["gold"], {}),
        ("Char", c["green"], {}),
        ("SpecialChar", c["purple"], {}),
        ("String", c["green"], {}),
        ("VerbatimString", c["green"], {}),
        ("SpecialString", c["cyan"], {}),
        ("Import", c["gold"], {}),
        ("DataType", c["blue"], {}),
        ("DecVal", c["purple"], {}),
        ("BaseN", c["purple"], {}),
        ("Float", c["purple"], {}),
        ("Constant", c["purple"], {"bold": True}),
        ("Comment", c["comment"], {"italic": True}),
        ("Documentation", c["comment"], {}),
        ("Annotation", c["gold"], {}),
        ("CommentVar", c["purple"], {}),
        ("RegionMarker", c["blue"], {"background-color": c["bg"]}),
        ("Information", c["gold"], {}),
        ("Warning", c["terracotta"], {}),
        ("Alert", c["red"], {"background-color": c["light_red"], "bold": True}),
        ("Error", c["red"], {"underline": True}),
        ("Others", c["cyan"], {}),
    ]
    theme_json = {
        "metadata": {
            "name": name,
            "revision": 1,
            "license": LICENSE,
            "copyright": [f"{AUTHOR}, after Clay by Artt"],
        },
        "text-styles": {
            key: {"text-color": color, **extra} for key, color, extra in styles
        },
    }
    path = PAYLOAD / "org.kde.syntax-highlighting" / "themes" / f"{theme['slug']}-{'dark' if dark else 'light'}.theme"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(theme_json, indent=2) + "\n")


def launcher_svg(pal: dict) -> str:
    """The Kickoff launcher: an accent tile with the hearth arch cut out."""
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <rect x="7" y="7" width="50" height="50" rx="15" fill="{pal['accent']}"/>
  <path d="M20 45V32a12 12 0 0 1 24 0v13" fill="none" stroke="{pal['paper']}" stroke-width="3.4" stroke-linecap="round"/>
  <path d="M25 45h14" stroke="{pal['paper']}" stroke-width="3.4" stroke-linecap="round"/>
  <path d="M32 43c-4.6-3.2-6.4-6.8-4.7-10.4 1.1-2.4 3.2-3.9 4-7.2 2.6 3.2 5.8 5.3 5.8 9.5 0 3.4-2 6.3-5.1 8.1z" fill="{pal['paper']}"/>
</svg>
'''


def build_icons(theme: dict) -> None:
    palette = PALETTES[theme["key"]]
    pal = icon_palette(palette)
    dst = PAYLOAD / "icons" / theme["icons"]
    run_tool("gen_icons.py", {
        "HG_ICONS_ROOT": str(dst),
        "HG_ICONS_PALETTE": json.dumps(pal),
    })

    # Hand-made pieces Clay ships outside gen_icons.py: the session actions
    # and the Kickoff launcher. Recolour their scheme defaults for this theme.
    mapping = {"#141413": pal["ink"], "#D97757": pal["accent"]}
    handmade = TEMPLATES / "icons-handmade"
    for src in handmade.rglob("*.svg"):
        rel = src.relative_to(handmade)
        out = dst / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(recolor_svg(src.read_text(), mapping))
    launcher = launcher_svg(pal)
    for size in (16, 22, 24, 32, 48, 64, "scalable"):
        d = dst / "apps" / str(size)
        d.mkdir(parents=True, exist_ok=True)
        (d / "hearthglass-launcher.svg").write_text(launcher)
        for alias_name in ("start-here-kde", "start-here"):
            link = d / f"{alias_name}.svg"
            if link.exists() or link.is_symlink():
                link.unlink()
            link.symlink_to("hearthglass-launcher.svg")

    index = (TEMPLATES / "icons-index.theme").read_text()
    index = index.replace("Name=Clay Icons", f"Name={theme['name']} Icons")
    index = index.replace("Comment=Minimal warm icon overlay for Clay",
                          f"Comment=Warm icon overlay for {theme['name']}")
    (dst / "index.theme").write_text(index)


def build_tabbox() -> None:
    dst = PAYLOAD / "kwin" / "tabbox" / SHARED["tabbox"]
    shutil.copytree(TEMPLATES / "kwin" / "tabbox" / "clay_grid", dst)
    meta_path = dst / "metadata.json"
    meta = json.loads(meta_path.read_text())
    plugin = meta["KPlugin"]
    plugin["Id"] = SHARED["tabbox"]
    plugin["Name"] = "Hearthglass Grid"
    plugin["Description"] = "Compact warm window switcher for the hearthglass themes"
    plugin["Website"] = WEBSITE
    meta_path.write_text(json.dumps(meta, indent=2) + "\n")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    if PAYLOAD.exists():
        shutil.rmtree(PAYLOAD)
    PAYLOAD.mkdir()

    rows = []
    for theme in THEMES:
        palette = PALETTES[theme["key"]]
        print(f"== {theme['name']}")
        build_icons(theme)
        for dark in (False, True):
            label = "dark" if dark else "light"
            print(f"  {label}")
            c = face(palette["dark" if dark else "light"], dark)
            scheme = build_scheme(theme, dark, c)
            build_plasma_style(theme, dark, c, scheme)
            build_aurorae(theme, dark, c)
            build_wallpaper(theme, dark, c)
            build_lnf(theme, dark, c, scheme)
            build_kate(theme, dark, c)
            rows.append("\t".join([
                theme["key"], label,
                theme["lnf_dark"] if dark else theme["lnf"],
                theme["scheme_dark"] if dark else theme["scheme"],
                theme["plasma_dark"] if dark else theme["plasma"],
                theme["decoration_dark"] if dark else theme["decoration"],
                theme["icons"],
                theme["wallpaper_dark"] if dark else theme["wallpaper"],
                theme["kate_dark"] if dark else theme["kate"],
                theme["name"] + (" Dark" if dark else ""),
            ]))

    print("== shared")
    build_tabbox()

    header = ["key", "face", "lnf", "scheme", "plasma", "decoration", "icons",
              "wallpaper", "kate", "name"]
    (ROOT / "themes.tsv").write_text("\t".join(header) + "\n" + "\n".join(rows) + "\n")
    print(f"\nwrote {len(rows)} global themes to {PAYLOAD}")


if __name__ == "__main__":
    main()
