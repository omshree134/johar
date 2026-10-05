"""
Original flat illustrations for AR items (drawn for Johar, free to use).
Edit the SVG snippets here and re-run:  python3 make_sprites.py
Outputs: ../../assets/ar/items/<name>.png (320x320, transparent)
         ./svg/<name>.svg (sources)
"""
import pathlib, cairosvg

OUT = pathlib.Path(__file__).resolve().parents[2] / "assets/ar/items"
SRC = pathlib.Path(__file__).resolve().parent / "svg"
OUT.mkdir(parents=True, exist_ok=True); SRC.mkdir(exist_ok=True)

INK = "#1E2226"
S = f'stroke="{INK}" stroke-width="7" stroke-linejoin="round" stroke-linecap="round"'
SHADOW = '<ellipse cx="128" cy="236" rx="78" ry="12" fill="#000" opacity="0.18"/>'
RED, YEL, BLUE, GRN = "#C4201F", "#F4B400", "#0B5CAD", "#17784A"
ORANGE, GREY, LIGHT, BROWN, WHITE = "#EF7B1A", "#8A9097", "#D9DEE2", "#A8753F", "#FFFFFF"

def runner(x, y, s=1.0, c=WHITE):
    # simple running-person pictogram
    return (f'<g transform="translate({x},{y}) scale({s})" fill="{c}" stroke="{c}" stroke-width="9" stroke-linecap="round" stroke-linejoin="round">'
            '<circle cx="14" cy="-34" r="8" stroke="none"/>'
            '<path d="M8 -22 L-2 4 M8 -22 L24 -6 L32 -14 M8 -22 L-10 -12 L-18 -20 M-2 4 L14 14 L10 30 M-2 4 L-16 24 L-26 22" fill="none"/></g>')

def person(x, y, s=1.0, c=INK):
    return (f'<g transform="translate({x},{y}) scale({s})"><circle cx="0" cy="-30" r="11" fill="{c}"/>'
            f'<path d="M-16 20 L-16 -8 Q0 -18 16 -8 L16 20 Z" fill="{c}"/></g>')

SPRITES = {
# ---------------- Fire ----------------
"extinguisher": f'''{SHADOW}
<rect x="92" y="70" width="72" height="160" rx="30" fill="{RED}" {S}/>
<rect x="104" y="44" width="48" height="30" rx="8" fill="{GREY}" {S}/>
<path d="M150 50 L196 40" {S} fill="none"/><path d="M104 56 C70 60 66 120 80 170" {S} fill="none" stroke-width="10"/>
<circle cx="128" cy="112" r="16" fill="{WHITE}" {S} stroke-width="5"/><path d="M128 112 L136 104" {S} stroke-width="4"/>
<rect x="104" y="150" width="48" height="36" rx="6" fill="{WHITE}" opacity="0.9"/>''',

"exit_sign": f'''<rect x="18" y="62" width="220" height="132" rx="18" fill="{GRN}" {S}/>
<rect x="40" y="84" width="54" height="92" rx="6" fill="{WHITE}"/><rect x="48" y="92" width="38" height="84" fill="{GRN}"/>
{runner(150,138,1.45)}<path d="M196 128 L222 128 M210 116 L224 128 L210 140" stroke="{WHITE}" stroke-width="9" fill="none" stroke-linecap="round" stroke-linejoin="round"/>''',

"stairs": f'''<rect x="28" y="40" width="200" height="180" rx="22" fill="{GRN}" {S}/>
<path d="M58 190 L98 190 L98 160 L138 160 L138 130 L178 130 L178 100 L206 100" stroke="{WHITE}" stroke-width="12" fill="none" stroke-linejoin="round"/>
{runner(118,108,1.1)}''',

"lift": f'''{SHADOW}<rect x="46" y="30" width="164" height="200" rx="14" fill="{LIGHT}" {S}/>
<rect x="66" y="70" width="60" height="150" fill="{GREY}" {S} stroke-width="5"/><rect x="130" y="70" width="60" height="150" fill="{GREY}" {S} stroke-width="5"/>
<rect x="98" y="38" width="60" height="24" rx="6" fill="{INK}"/><path d="M114 54 L120 44 L126 54 Z M132 44 L138 54 L144 44 Z" fill="{YEL}"/>''',

"boxes": f'''{SHADOW}<rect x="40" y="130" width="92" height="96" rx="6" fill="{BROWN}" {S}/><rect x="126" y="130" width="92" height="96" rx="6" fill="#C08A50" {S}/>
<rect x="80" y="40" width="96" height="94" rx="6" fill="#C08A50" {S}/>
<path d="M86 150 L86 180 M172 150 L172 180 M128 60 L128 90" stroke="{INK}" stroke-width="5" opacity="0.5"/>''',

"socket": f'''<rect x="46" y="40" width="164" height="120" rx="20" fill="{WHITE}" {S}/>
<circle cx="96" cy="100" r="24" fill="{LIGHT}" {S} stroke-width="5"/><circle cx="160" cy="100" r="24" fill="{LIGHT}" {S} stroke-width="5"/>
<rect x="80" y="86" width="32" height="40" rx="6" fill="{INK}"/><rect x="144" y="86" width="32" height="40" rx="6" fill="{INK}"/>
<path d="M96 126 C96 170 60 180 50 230 M160 126 C160 170 200 180 206 230 M128 160 C128 190 128 200 128 232" stroke="{INK}" stroke-width="7" fill="none"/>
<path d="M190 30 L208 12 L204 30 L222 22" stroke="{ORANGE}" stroke-width="6" fill="none" stroke-linejoin="round"/>
<path d="M30 40 L44 26 M30 60 L14 56" stroke="{YEL}" stroke-width="6" stroke-linecap="round"/>''',

"smoking_drums": f'''{SHADOW}<rect x="34" y="70" width="84" height="156" rx="10" fill="{BLUE}" {S}/><rect x="112" y="84" width="84" height="142" rx="10" fill="#2E7BC4" {S}/>
<path d="M34 110 H118 M34 180 H118 M112 124 H196 M112 186 H196" stroke="{INK}" stroke-width="6"/>
<path d="M140 60 L214 36" stroke="{WHITE}" stroke-width="12" stroke-linecap="round"/><path d="M140 60 L214 36" {S} fill="none" stroke-width="3"/>
<circle cx="214" cy="36" r="7" fill="{ORANGE}"/><path d="M222 26 C236 14 222 6 234 -2" stroke="{GREY}" stroke-width="5" fill="none"/>''',

"oil_spill": f'''<path d="M30 200 C20 160 80 150 110 170 C150 140 230 150 226 196 C236 226 150 236 110 222 C70 238 36 230 30 200 Z" fill="{INK}"/>
<ellipse cx="96" cy="190" rx="22" ry="7" fill="#fff" opacity="0.25"/>
<path d="M170 40 L210 110 L150 120 Z" fill="{GREY}" {S}/><path d="M176 112 C176 130 168 140 162 150" stroke="{INK}" stroke-width="8" fill="none"/>
<path d="M60 90 L72 70 M84 96 L100 84 M52 116 L36 108" stroke="{ORANGE}" stroke-width="6" stroke-linecap="round"/>''',

"bin": f'''{SHADOW}<path d="M70 90 L186 90 L172 230 L84 230 Z" fill="{GREY}" {S}/><rect x="60" y="76" width="136" height="20" rx="8" fill="#6C7278" {S}/>
<path d="M104 110 L108 214 M128 110 L128 214 M152 110 L148 214" stroke="{INK}" stroke-width="5" opacity="0.4"/>''',

"fire_alarm": f'''<rect x="54" y="36" width="148" height="184" rx="18" fill="{RED}" {S}/>
<rect x="80" y="64" width="96" height="96" rx="10" fill="{WHITE}" {S} stroke-width="5"/>
<path d="M96 144 L128 84 L160 144" stroke="{INK}" stroke-width="6" fill="none"/><circle cx="128" cy="190" r="10" fill="{WHITE}"/>''',

"power_switch": f'''<rect x="56" y="32" width="144" height="196" rx="16" fill="{LIGHT}" {S}/>
<rect x="104" y="80" width="48" height="100" rx="10" fill="{INK}"/><rect x="92" y="130" width="72" height="30" rx="8" fill="{RED}" {S} stroke-width="5"/>
<text x="128" y="68" font-family="Arial" font-size="26" font-weight="700" text-anchor="middle" fill="{INK}">OFF</text>
<path d="M112 200 L144 200" stroke="{YEL}" stroke-width="10" stroke-linecap="round"/>''',

"assembly_point": f'''<rect x="28" y="40" width="200" height="180" rx="22" fill="{GRN}" {S}/>
<g fill="{WHITE}">{person(96,118,1.0,WHITE)}{person(160,118,1.0,WHITE)}{person(96,188,1.0,WHITE)}{person(160,188,1.0,WHITE)}</g>
<path d="M128 60 L128 92 M128 150 L128 206" stroke="{WHITE}" stroke-width="0"/>''',

"headcount": f'''{SHADOW}<rect x="58" y="36" width="140" height="190" rx="14" fill="{BROWN}" {S}/><rect x="74" y="60" width="108" height="150" rx="6" fill="{WHITE}"/>
<rect x="100" y="28" width="56" height="26" rx="8" fill="{GREY}" {S} stroke-width="5"/>
<path d="M88 92 L98 102 L114 84 M88 132 L98 142 L114 124 M88 172 L98 182 L114 164" stroke="{GRN}" stroke-width="7" fill="none" stroke-linecap="round"/>
<path d="M124 94 H168 M124 134 H168 M124 174 H168" stroke="{INK}" stroke-width="6" stroke-linecap="round"/>''',

# ---------------- Gas / confined space ----------------
"gas_detector": f'''{SHADOW}<rect x="70" y="40" width="116" height="186" rx="26" fill="{YEL}" {S}/>
<rect x="88" y="62" width="80" height="64" rx="8" fill="#113322" {S} stroke-width="4"/>
<text x="128" y="102" font-family="Arial" font-size="24" font-weight="700" text-anchor="middle" fill="#3DDC84">20.9</text>
<circle cx="104" cy="160" r="12" fill="{INK}"/><circle cx="152" cy="160" r="12" fill="{INK}"/><rect x="104" y="192" width="48" height="12" rx="6" fill="{INK}"/>
<circle cx="128" cy="30" r="10" fill="{RED}" {S} stroke-width="4"/>''',

"harness": f'''<path d="M84 40 L110 140 L146 140 L172 40" stroke="{ORANGE}" stroke-width="18" fill="none" stroke-linejoin="round"/>
<path d="M84 40 L110 140 L146 140 L172 40" {S} fill="none" stroke-width="3"/>
<path d="M90 150 C70 200 110 220 128 190 C146 220 186 200 166 150" stroke="{ORANGE}" stroke-width="16" fill="none"/>
<rect x="104" y="128" width="48" height="26" rx="6" fill="{GREY}" {S} stroke-width="5"/>
<path d="M128 40 C140 10 200 16 214 60 C224 96 206 120 220 150" stroke="{BLUE}" stroke-width="8" fill="none"/>
<path d="M212 150 C212 178 236 178 236 160" stroke="{GREY}" stroke-width="9" fill="none"/>''',

"helmet": f'''{SHADOW}<path d="M44 176 C44 96 84 56 128 56 C172 56 212 96 212 176 Z" fill="{YEL}" {S}/>
<rect x="26" y="170" width="204" height="30" rx="14" fill="{YEL}" {S}/><path d="M128 58 L128 170" stroke="{INK}" stroke-width="6" opacity="0.35"/>
<path d="M92 72 C80 100 76 130 76 170 M164 72 C176 100 180 130 180 170" stroke="{INK}" stroke-width="5" opacity="0.25" fill="none"/>''',

"breathing_apparatus": f'''{SHADOW}<rect x="140" y="60" width="64" height="168" rx="28" fill="{GREY}" {S}/><rect x="152" y="40" width="40" height="26" rx="6" fill="{INK}"/>
<ellipse cx="86" cy="118" rx="54" ry="64" fill="{INK}"/><ellipse cx="86" cy="108" rx="38" ry="40" fill="#8FC3E8" {S} stroke-width="5"/>
<circle cx="86" cy="172" r="16" fill="{GREY}" {S} stroke-width="5"/><path d="M100 182 C130 210 150 200 160 180" stroke="{INK}" stroke-width="9" fill="none"/>''',

"cloth_mask": f'''<path d="M52 92 C90 70 166 70 204 92 L196 172 C166 200 90 200 60 172 Z" fill="#9CC7E4" {S}/>
<path d="M62 116 H194 M66 144 H190" stroke="{INK}" stroke-width="5" opacity="0.35"/>
<path d="M52 96 C20 96 20 160 60 166 M204 96 C236 96 236 160 196 166" stroke="{WHITE}" stroke-width="7" fill="none"/>
<path d="M52 96 C20 96 20 160 60 166 M204 96 C236 96 236 160 196 166" {S} fill="none" stroke-width="2"/>''',

"matchbox": f'''{SHADOW}<rect x="50" y="116" width="156" height="104" rx="10" fill="{RED}" {S}/><rect x="64" y="132" width="128" height="72" rx="6" fill="{YEL}"/>
<path d="M100 116 L130 44 M122 116 L160 52" stroke="{BROWN}" stroke-width="8" stroke-linecap="round"/>
<circle cx="130" cy="42" r="10" fill="{RED}" {S} stroke-width="4"/><circle cx="160" cy="50" r="10" fill="{RED}" {S} stroke-width="4"/>''',

"gas_cylinder": f'''{SHADOW}<rect x="80" y="64" width="96" height="166" rx="40" fill="{BLUE}" {S}/><rect x="108" y="36" width="40" height="32" rx="8" fill="{GREY}" {S}/>
<rect x="80" y="120" width="96" height="22" fill="{WHITE}" opacity="0.85"/>
<circle cx="190" cy="44" r="16" fill="#C9D66A" opacity="0.8"/><circle cx="214" cy="26" r="12" fill="#C9D66A" opacity="0.6"/><circle cx="170" cy="30" r="10" fill="#C9D66A" opacity="0.7"/>''',

"windsock": f'''<path d="M60 236 L60 30" stroke="{INK}" stroke-width="10" stroke-linecap="round"/>
<path d="M64 40 L220 62 L220 102 L64 120 Z" fill="{ORANGE}" {S}/>
<path d="M112 46 L112 114 M168 54 L168 108" stroke="{WHITE}" stroke-width="18"/>
<path d="M64 40 L220 62 L220 102 L64 120 Z" {S} fill="none"/>''',

"shed": f'''{SHADOW}<path d="M34 110 L128 44 L222 110 Z" fill="{RED}" {S}/><rect x="52" y="108" width="152" height="120" fill="{LIGHT}" {S}/>
<rect x="104" y="148" width="48" height="80" fill="{BROWN}" {S} stroke-width="5"/><rect x="66" y="130" width="28" height="28" fill="#8FC3E8" {S} stroke-width="4"/>''',

"pit": f'''<ellipse cx="128" cy="170" rx="104" ry="46" fill="{BROWN}" {S}/><ellipse cx="128" cy="170" rx="78" ry="30" fill="{INK}"/>
<path d="M60 60 C80 40 110 50 110 70 M150 60 C170 40 200 50 200 70" stroke="#C9D66A" stroke-width="8" fill="none" opacity="0.8"/>
<path d="M92 120 L92 140 M164 120 L164 140" stroke="#C9D66A" stroke-width="6" stroke-linecap="round"/>''',

"radio": f'''{SHADOW}<rect x="80" y="70" width="96" height="158" rx="20" fill="{INK}"/><path d="M150 70 L150 22" stroke="{INK}" stroke-width="12" stroke-linecap="round"/>
<rect x="96" y="92" width="64" height="40" rx="6" fill="#8FC3E8"/><circle cx="128" cy="176" r="24" fill="{GREY}"/>
<path d="M190 100 C206 116 206 140 190 156 M206 86 C230 112 230 144 206 170" stroke="{BLUE}" stroke-width="7" fill="none" stroke-linecap="round"/>''',

"tripod_winch": f'''<path d="M128 30 L50 230 M128 30 L206 230 M128 30 L128 230" stroke="{YEL}" stroke-width="14" stroke-linecap="round"/>
<path d="M128 30 L50 230 M128 30 L128 230 M128 30 L206 230" {S} fill="none" stroke-width="3"/>
<circle cx="150" cy="120" r="18" fill="{GREY}" {S} stroke-width="5"/><path d="M128 30 L128 190" stroke="{BLUE}" stroke-width="5"/>
<ellipse cx="128" cy="232" rx="70" ry="14" fill="{INK}"/>''',

"phone_call": f'''<rect x="72" y="28" width="112" height="200" rx="22" fill="{INK}"/><rect x="84" y="50" width="88" height="148" rx="8" fill="{GRN}"/>
<path d="M108 100 C108 140 130 162 150 162 L158 150 L144 140 L136 146 C126 140 120 130 118 120 L124 112 L114 98 Z" fill="{WHITE}"/>''',

"alarm_bell": f'''{SHADOW}<path d="M68 180 C68 90 90 60 128 60 C166 60 188 90 188 180 Z" fill="{RED}" {S}/><rect x="52" y="176" width="152" height="24" rx="10" fill="{RED}" {S}/>
<circle cx="128" cy="214" r="14" fill="{INK}"/><path d="M40 90 C30 110 30 140 40 160 M216 90 C226 110 226 140 216 160" stroke="{ORANGE}" stroke-width="8" fill="none" stroke-linecap="round"/>''',

"attendant": f'''{person(128,150,2.4,BLUE)}<path d="M92 90 C92 60 164 60 164 90 Z" fill="{YEL}" {S} stroke-width="5"/>
<rect x="160" y="130" width="34" height="56" rx="8" fill="{INK}"/><path d="M186 130 L186 104" stroke="{INK}" stroke-width="8"/>''',

# ---------------- Machinery ----------------
"exposed_gears": f'''<circle cx="100" cy="120" r="62" fill="{GREY}" {S}/><circle cx="100" cy="120" r="18" fill="{INK}"/>
<g stroke="{INK}" stroke-width="18" stroke-linecap="butt">{"".join(f'<path d="M{100+62*__import__("math").cos(a*__import__("math").pi/4):.1f} {120+62*__import__("math").sin(a*__import__("math").pi/4):.1f} L{100+80*__import__("math").cos(a*__import__("math").pi/4):.1f} {120+80*__import__("math").sin(a*__import__("math").pi/4):.1f}"/>' for a in range(8))}</g>
<circle cx="182" cy="182" r="40" fill="#B0B6BC" {S}/><circle cx="182" cy="182" r="12" fill="{INK}"/>
<path d="M30 30 L226 226" stroke="{RED}" stroke-width="0"/>''',

"loose_scarf": f'''<path d="M60 40 C120 60 150 40 196 56 L186 104 C140 90 110 110 70 92 Z" fill="#D14B8F" {S}/>
<path d="M150 96 C160 150 140 200 170 236 L206 226 C186 190 196 140 184 100 Z" fill="#D14B8F" {S}/>
<path d="M170 236 L166 250 M182 232 L182 248 M196 228 L200 244" stroke="{INK}" stroke-width="5"/>''',

"spanner": f'''<path d="M60 196 L160 96" stroke="{GREY}" stroke-width="30" stroke-linecap="round"/><path d="M60 196 L160 96" {S} fill="none" stroke-width="3"/>
<path d="M150 60 C170 40 212 44 220 70 L192 84 L186 104 L206 116 C190 140 150 140 140 110 Z" fill="{GREY}" {S}/>
<circle cx="58" cy="198" r="26" fill="{GREY}" {S}/><circle cx="58" cy="198" r="10" fill="{WHITE}"/>''',

"padlock": f'''<path d="M84 110 L84 76 C84 30 172 30 172 76 L172 110" stroke="{GREY}" stroke-width="20" fill="none"/>
<rect x="60" y="104" width="136" height="118" rx="20" fill="{RED}" {S}/><circle cx="128" cy="152" r="14" fill="{INK}"/><rect x="122" y="156" width="12" height="36" rx="4" fill="{INK}"/>''',

"danger_tag": f'''<path d="M70 50 L186 50 L206 80 L206 228 L50 228 L50 80 Z" fill="{WHITE}" {S}/>
<rect x="50" y="84" width="156" height="50" fill="{RED}"/><circle cx="128" cy="66" r="10" fill="{WHITE}" {S} stroke-width="4"/>
<text x="128" y="118" font-family="Arial" font-size="30" font-weight="700" text-anchor="middle" fill="{WHITE}">DANGER</text>
<path d="M78 160 H178 M78 188 H160" stroke="{INK}" stroke-width="10" stroke-linecap="round"/>''',

"emergency_stop": f'''{SHADOW}<rect x="44" y="120" width="168" height="108" rx="16" fill="{YEL}" {S}/>
<path d="M76 130 C76 70 180 70 180 130 Z" fill="{RED}" {S}/><rect x="96" y="126" width="64" height="26" fill="#9E1818" {S} stroke-width="5"/>
<text x="128" y="202" font-family="Arial" font-size="26" font-weight="700" text-anchor="middle" fill="{INK}">STOP</text>''',

"goggles": f'''<path d="M34 100 C34 70 222 70 222 100 L222 150 C222 176 160 180 144 156 C136 146 120 146 112 156 C96 180 34 176 34 150 Z" fill="#8FC3E8" {S}/>
<path d="M34 116 L12 110 M222 116 L244 110" stroke="{INK}" stroke-width="10" stroke-linecap="round"/>
<path d="M60 96 L90 96" stroke="{WHITE}" stroke-width="8" stroke-linecap="round"/>''',

"earmuffs": f'''<path d="M58 140 C58 40 198 40 198 140" stroke="{GREY}" stroke-width="16" fill="none"/><path d="M58 140 C58 40 198 40 198 140" {S} fill="none" stroke-width="3"/>
<rect x="30" y="120" width="56" height="94" rx="26" fill="{YEL}" {S}/><rect x="170" y="120" width="56" height="94" rx="26" fill="{YEL}" {S}/>''',

"safety_boots": f'''{SHADOW}<path d="M70 40 L140 40 L140 150 L214 170 C230 176 230 214 214 216 L60 216 C52 216 50 208 52 200 Z" fill="{BROWN}" {S}/>
<path d="M150 154 C186 160 214 170 216 200" fill="none" stroke="{GREY}" stroke-width="10"/><rect x="52" y="206" width="170" height="16" rx="6" fill="{INK}"/>
<path d="M84 70 H126 M84 96 H126 M84 122 H126" stroke="{INK}" stroke-width="5"/>''',

"gloves": f'''<path d="M76 228 L76 120 C76 104 96 104 96 120 L96 70 C96 54 116 54 116 70 L116 60 C116 44 136 44 136 60 L136 70 C136 54 156 54 156 70 L156 120 C166 104 188 108 180 128 L156 196 L156 228 Z" fill="{ORANGE}" {S}/>
<rect x="72" y="196" width="88" height="34" rx="6" fill="{GREY}" {S} stroke-width="5"/>''',

"wrist_watch": f'''<rect x="100" y="20" width="56" height="216" rx="18" fill="{BROWN}" {S}/>
<circle cx="128" cy="128" r="56" fill="{LIGHT}" {S}/><circle cx="128" cy="128" r="40" fill="{WHITE}"/>
<path d="M128 128 L128 100 M128 128 L148 138" stroke="{INK}" stroke-width="7" stroke-linecap="round"/>''',

"conveyor": f'''{SHADOW}<rect x="20" y="120" width="216" height="46" rx="23" fill="{INK}"/><circle cx="44" cy="143" r="16" fill="{GREY}"/><circle cx="212" cy="143" r="16" fill="{GREY}"/><circle cx="128" cy="143" r="16" fill="{GREY}"/>
<rect x="60" y="80" width="54" height="42" rx="6" fill="#C08A50" {S} stroke-width="5"/><rect x="140" y="86" width="44" height="36" rx="6" fill="{BROWN}" {S} stroke-width="5"/>
<path d="M60 170 L60 226 M196 170 L196 226" stroke="{INK}" stroke-width="10"/>''',

"reaching_hand": f'''<rect x="20" y="150" width="216" height="40" rx="20" fill="{INK}"/><circle cx="60" cy="170" r="12" fill="{GREY}"/><circle cx="196" cy="170" r="12" fill="{GREY}"/>
<path d="M70 40 L110 128 C114 140 130 142 138 132 L150 116 C156 108 150 96 140 98 L126 104 L100 40" fill="#C98B5E" {S}/>
<path d="M58 34 L112 34" stroke="{BLUE}" stroke-width="24" stroke-linecap="round"/>''',
}

import re
def dedupe_attrs(svg):
    """Later attributes win (lets a shape override the shared stroke width)."""
    def fix(tag):
        t = tag.group(0)
        attrs = re.findall(r'([\w:-]+)="([^"]*)"', t)
        head = re.match(r'<\s*[\w:-]+', t).group(0)
        tail = '/>' if t.rstrip().endswith('/>') else '>'
        seen = {}
        for k, v in attrs: seen[k] = v
        return head + ''.join(f' {k}="{v}"' for k, v in seen.items()) + tail
    return re.sub(r'<[a-zA-Z][^<>]*?/?>', fix, svg)

for name, body in SPRITES.items():
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -10 256 266" width="320" height="320">{body}</svg>'
    svg = dedupe_attrs(svg)
    (SRC / f"{name}.svg").write_text(svg)
    cairosvg.svg2png(bytestring=svg.encode(), write_to=str(OUT / f"{name}.png"), output_width=320, output_height=320)
print(len(SPRITES), "sprites ->", OUT)
