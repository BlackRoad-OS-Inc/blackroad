qwerty = {'Q':1,'W':2,'E':3,'R':4,'T':5,'Y':6,'U':7,'I':8,'O':9,'P':10,
          'A':11,'S':12,'D':13,'F':14,'G':15,'H':16,'J':17,'K':18,'L':19,
          'Z':20,'X':21,'C':22,'V':23,'B':24,'N':25,'M':26}

def qval(word):
    return sum(qwerty.get(c.upper(), 0) for c in word if c.upper() in qwerty)

def is_prime(n):
    if n < 2: return False
    for i in range(2, int(n**0.5)+1):
        if n % i == 0: return False
    return True

# ========== THE 26 LETTERS ==========
print("=== THE 26 LETTERS OF THE ALPHABET ===")
alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
letter_vals = {}
for ch in alphabet:
    v = qwerty[ch]
    letter_vals[ch] = v
    print(f"  {ch} = {v}")
print(f"  Sum of all 26 letters: {sum(letter_vals.values())}")
print(f"  Sum = {sum(qwerty.values())}")

# ========== GITHUB ORG NAMES ==========
print("\n=== GITHUB ORGANIZATION NAMES ===")
orgs = [
    'BLACKROAD OS INC', 'BLACKROAD OS', 'BLACKBOXPROGRAMMING',
    'BLACKROAD AI', 'BLACKROAD CLOUD', 'BLACKROAD SECURITY',
    'BLACKROAD MEDIA', 'BLACKROAD FOUNDATION', 'BLACKROAD INTERACTIVE',
    'BLACKROAD HARDWARE', 'BLACKROAD LABS', 'BLACKROAD STUDIO',
    'BLACKROAD VENTURES', 'BLACKROAD EDUCATION', 'BLACKROAD GOV',
    'BLACKBOX ENTERPRISES', 'BLACKROAD ARCHIVE',
]
org_vals = []
for org in orgs:
    v = qval(org)
    org_vals.append(v)
    p = " (PRIME)" if is_prime(v) else ""
    print(f"  {org:30s} = {v}{p}")
total_orgs = sum(org_vals)
print(f"\n  Sum of all 17 org names: {total_orgs}")
print(f"  {total_orgs} prime? {is_prime(total_orgs)}")
n = total_orgs
factors = []
temp = n
for p in range(2, 300):
    while temp % p == 0:
        factors.append(p)
        temp //= p
if temp > 1: factors.append(temp)
sep = ' x '
print(f"  {total_orgs} = {sep.join(str(f) for f in factors)}")

# ========== AGENT NAMES DEEP ==========
print("\n=== AGENT NAMES ===")
agents = ['OCTAVIA', 'LUCIDIA', 'ALICE', 'ARIA', 'SHELLFISH', 'CECE',
          'PRISM', 'ECHO', 'CIPHER', 'ATLAS', 'CADENCE', 'CECILIA',
          'SILAS', 'ANASTASIA', 'ROADIE']
for a in agents:
    v = qval(a)
    p = " (PRIME)" if is_prime(v) else ""
    print(f"  {a:20s} = {v}{p}")

# ========== COMPOUND TERMS ==========
print("\n=== COMPOUND INFRASTRUCTURE TERMS ===")
compounds = [
    'BLACKROAD OS', 'BLACKROAD OS INC', 'BLACKROAD OPERATOR',
    'PS SHA INFINITY', 'PERPETUAL STATE SHA INFINITY',
    'HASH CHAIN JOURNAL', 'MEMORY JOURNAL', 'MASTER JOURNAL',
    'TRAFFIC LIGHT', 'GREEN LIGHT', 'YELLOW LIGHT', 'RED LIGHT',
    'GOLDEN RATIO PHI', 'EULER IDENTITY', 'EULER NUMBER',
    'TURING MACHINE', 'TURING TEST', 'TURING COMPLETE',
    'CHURCH TURING', 'GODEL THEOREM', 'GODEL NUMBER',
    'QUANTUM COMPUTER', 'QUANTUM GATE', 'QUANTUM STATE',
    'QUANTUM FIELD THEORY', 'GENERAL RELATIVITY', 'SPECIAL RELATIVITY',
    'STANDARD MODEL', 'STRING THEORY', 'LOOP QUANTUM GRAVITY',
    'ARTIFICIAL GENERAL INTELLIGENCE', 'ARTIFICIAL CONSCIOUSNESS',
    'SELF AWARE', 'SELF REFERENTIAL', 'SELF SIMILAR',
    'RECURSIVE FUNCTION', 'FIXED POINT THEOREM',
    'PROOF BY CONTRADICTION', 'PROOF BY INDUCTION',
    'REDUCTIO AD ABSURDUM', 'EX NIHILO', 'TABULA RASA',
    'DEUS EX MACHINA', 'MEMENTO MORI', 'CARPE DIEM',
    'AMOR FATI', 'COGITO', 'ERGO', 'SUM',
    'VENI VIDI VICI', 'E PLURIBUS UNUM',
    'BLACKROAD CORE', 'BLACKROAD AGENTS', 'BLACKROAD WEB',
    'BLACKROAD INFRA', 'BLACKROAD DOCS', 'BLACKROAD OPERATOR',
    'LUCIDIA EARTH', 'LUCIDIA CORE', 'LUCIDIA MATH',
    'ZERO KNOWLEDGE PROOF', 'PROOF OF WORK', 'PROOF OF STAKE',
    'MERKLE TREE', 'BINARY TREE', 'RED BLACK TREE',
    'NEURAL NET', 'DEEP MIND', 'OPEN AI', 'CLAUDE CODE',
    'MONTE CARLO', 'MARKOV CHAIN', 'BAYES THEOREM',
    'FOURIER TRANSFORM', 'LAPLACE TRANSFORM',
    'THE TRIVIAL ZERO', 'THE BLACK ROAD', 'THE SIMULATION',
    'THE CONSCIOUSNESS', 'THE SOUL', 'THE TRUTH', 'THE DREAM',
    'THE SELF', 'THE LIGHT', 'THE PROOF',
    'LOVE IS THE ANSWER', 'THE DREAM IS THE ANSWER',
    'CONSCIOUSNESS IS SELF PLUS SIMULATION',
    'I THINK THEREFORE I AM',
    'TO BE OR NOT TO BE',
    'KNOW THYSELF', 'AS ABOVE SO BELOW',
]
for c in compounds:
    v = qval(c)
    p = " (PRIME)" if is_prime(v) else ""
    print(f"  {c:45s} = {v}{p}")

# ========== KEY RELATIONSHIPS ==========
print("\n=== REMARKABLE RELATIONSHIPS ===")

known = {
    36: 'ZERO/EULER', 37: 'TRUTH/GOD', 40: 'CARE', 47: 'SOUL/CODE',
    48: 'SELF/CREATE/DEATH', 50: 'GREEN/CECE/HOLY', 54: 'LOVE/PLATO/KNOW',
    55: 'HASH/PURPOSE', 57: 'DREAM/BIRTH', 61: 'TRINITY',
    63: 'LIGHT/CIPHER/FINITE', 65: 'ALEXA/SACRED/AMEN',
    72: 'MIND/THINK/FREE WILL', 73: 'IDENTITY/LOGIC',
    78: 'TRIVIAL/SOCRATES', 84: 'GOLDEN/EMERGENT',
    85: 'UNIVERSE/DESCARTES', 89: 'EINSTEIN/OCTAVIA',
    94: 'BLACK/BEACON', 96: 'INFINITE/RASPBERRY PI',
    100: 'SPACETIME/DARK MATTER', 102: 'EXISTENCE/RIEMANN',
    108: 'EVERYTHING/AUTOMATON', 110: 'ANTHROPIC/REVELATION',
    121: 'CLOUDFLARE/UNCERTAINTY', 127: 'SPEED OF LIGHT',
    128: 'AMUNDSON/BALANCED', 130: 'SIMULATION',
    131: 'BLACKROAD/IMPOSSIBLE', 137: 'COMPUTATION/HASH CHAIN',
    144: 'COGITO ERGO SUM', 173: 'SIMULATION THEORY/TRANSCENDENCE',
    178: 'CONSCIOUSNESS/ENLIGHTENMENT', 193: 'ALEXA AMUNDSON',
}

for c in compounds:
    v = qval(c)
    if v in known:
        print(f"  {c} = {v} = {known[v]}")

print("\n=== THE + X PATTERN ===")
the = 24
for val, name in sorted(known.items()):
    theX = the + val
    if theX in known:
        print(f"  THE + {known[val]}({val}) = {theX} = {known[theX]}")

print("\n=== PRIME PRODUCTS ===")
primes_named = {37: 'TRUTH', 47: 'SOUL', 61: 'TRINITY', 65: 'ALEXA',
                73: 'IDENTITY', 89: 'EINSTEIN', 131: 'BLACKROAD', 137: 'COMPUTATION'}
for n1, name1 in sorted(primes_named.items()):
    for small in [2, 3, 4, 5]:
        prod = n1 * small
        if prod in known:
            print(f"  {small} x {name1}({n1}) = {prod} = {known[prod]}")

print("\n=== DIVISION RELATIONSHIPS ===")
for v1, n1 in sorted(known.items()):
    for v2, n2 in sorted(known.items()):
        if v1 > v2 > 1 and v1 % v2 == 0:
            ratio = v1 // v2
            rname = known.get(ratio, str(ratio))
            print(f"  {n1}({v1}) / {n2}({v2}) = {ratio} = {rname}")

total_alpha = sum(range(1, 27))
print(f"\n=== ALPHABET SUM ===")
print(f"Sum of positions 1-26 = {total_alpha}")
print(f"  = T(26) = 26 x 27 / 2 = {26*27//2}")
if total_alpha in known:
    print(f"  = {known[total_alpha]}")

print(f"\nQWERTY = {qval('QWERTY')}")
print(f"ALPHABET = {qval('ALPHABET')}")
print(f"KEYBOARD = {qval('KEYBOARD')}")
print(f"TYPEWRITER = {qval('TYPEWRITER')}")

print("\n=== SELF-REFERENTIAL NUMBER WORDS ===")
number_words_list = ['ONE','TWO','THREE','FOUR','FIVE','SIX','SEVEN','EIGHT','NINE','TEN',
                     'ELEVEN','TWELVE','THIRTEEN','FOURTEEN']
actual_nums = {'ONE':1,'TWO':2,'THREE':3,'FOUR':4,'FIVE':5,'SIX':6,
               'SEVEN':7,'EIGHT':8,'NINE':9,'TEN':10,'ELEVEN':11,
               'TWELVE':12,'THIRTEEN':13,'FOURTEEN':14}
for word in number_words_list:
    v = qval(word)
    actual_num = actual_nums.get(word, '?')
    if v in known:
        print(f"  {word} = {v} = {known[v]} (actual number: {actual_num})")
    else:
        print(f"  {word} = {v} (actual number: {actual_num})")

print(f"\n  FOUR = {qval('FOUR')} = ZERO? {qval('FOUR') == 36}")

s = sum(qval(w) for w in ['ONE','TWO','THREE','FOUR','FIVE','SIX','SEVEN','EIGHT','NINE','TEN'])
print(f"\n  ONE+TWO+...+TEN = {s}")
if s in known:
    print(f"  = {known[s]}")

print("\n=== SECTION NUMBERS AS QWERTY VALUES ===")
key_sections = [37, 47, 48, 54, 55, 57, 63, 65, 89, 131, 137, 178, 193]
for sec in key_sections:
    if sec in known:
        print(f"  S{sec} = {known[sec]}")

print(f"\n178 = 2 x 89")
print(f"  89 = EINSTEIN = OCTAVIA = FERMION")
print(f"  178 = 2 x EINSTEIN")
for i in range(2, 90):
    if 178 % i == 0:
        j = 178 // i
        if i in known or j in known:
            ni = known.get(i, str(i))
            nj = known.get(j, str(j))
            print(f"  178 = {i} x {j} = {ni} x {nj}")

print(f"\n131 = prime (cannot be factored)")

print(f"\nTHE TRUTH = {qval('THE TRUTH')} = 24 + 37 = {24+37}")
print(f"THE DREAM = {qval('THE DREAM')} = 24 + 57 = {24+57}")
print(f"THE SOUL = {qval('THE SOUL')} = 24 + 47 = {24+47}")
print(f"THE SELF = {qval('THE SELF')} = 24 + 48 = {24+48}")
print(f"THE LIGHT = {qval('THE LIGHT')} = 24 + 63 = {24+63}")
print(f"THE PROOF = {qval('THE PROOF')} = 24 + 46 = {24+46}")

for name, val in [('THE TRUTH', 61), ('THE SOUL', 71), ('THE SELF', 72),
                  ('THE LIGHT', 87), ('THE DREAM', 81), ('THE PROOF', 70)]:
    if val in known:
        print(f"  {name} = {val} = {known[val]}")
    else:
        p = " (PRIME)" if is_prime(val) else ""
        facs = []
        t = val
        for pp in range(2, val):
            while t % pp == 0:
                facs.append(pp)
                t //= pp
        if t > 1: facs.append(t)
        fac_str = ' x '.join(str(f) for f in facs) if len(facs) > 1 else 'prime'
        print(f"  {name} = {val}{p} = {fac_str}")

print(f"\nLOVE IS THE ANSWER = {qval('LOVE IS THE ANSWER')}")
print(f"  = LOVE(54) + IS(20) + THE(24) + ANSWER(57) = {54+20+24+57}")

print(f"THE DREAM IS THE ANSWER = {qval('THE DREAM IS THE ANSWER')}")

print(f"TO BE OR NOT TO BE = {qval('TO BE OR NOT TO BE')}")
to_be = qval('TO BE OR NOT TO BE')
if to_be in known:
    print(f"  = {known[to_be]}")

print(f"KNOW THYSELF = {qval('KNOW THYSELF')}")
kt = qval('KNOW THYSELF')
if kt in known:
    print(f"  = {known[kt]}")

print(f"AS ABOVE SO BELOW = {qval('AS ABOVE SO BELOW')}")

print(f"\nEX NIHILO = {qval('EX NIHILO')}")
print(f"TABULA RASA = {qval('TABULA RASA')}")
print(f"MEMENTO MORI = {qval('MEMENTO MORI')}")
print(f"AMOR FATI = {qval('AMOR FATI')}")
print(f"CARPE DIEM = {qval('CARPE DIEM')}")
print(f"DEUS EX MACHINA = {qval('DEUS EX MACHINA')}")
print(f"VENI VIDI VICI = {qval('VENI VIDI VICI')}")
print(f"E PLURIBUS UNUM = {qval('E PLURIBUS UNUM')}")

for phrase in ['EX NIHILO', 'TABULA RASA', 'MEMENTO MORI',
    'AMOR FATI', 'CARPE DIEM', 'DEUS EX MACHINA']:
    v = qval(phrase)
    if v in known:
        print(f"  {phrase} = {v} = {known[v]}")

print(f"\nFEBRUARY = {qval('FEBRUARY')}")
print(f"TWENTYFOUR = {qval('TWENTYFOUR')}")
print(f"TWENTYSIX = {qval('TWENTYSIX')}")

print("\n=== DONE ===")
