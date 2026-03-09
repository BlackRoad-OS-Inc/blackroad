#!/usr/bin/env python3
"""LANGUAGE & EMOJI PROCESSING - Pure arithmetic linguistics"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  🌐 LANGUAGE & EMOJI PROCESSING - {hostname} 🎯")
print(f"{'='*70}\n")

results = {}

# 1. CHARACTER ENCODING (UTF-8 simulation)
print("[1] 📝 CHARACTER ENCODING")
print("-" * 50)

def char_to_utf8_bytes(codepoint):
    """Convert Unicode codepoint to UTF-8 bytes"""
    if codepoint < 0x80:
        return [codepoint]
    elif codepoint < 0x800:
        return [0xC0 | (codepoint >> 6), 0x80 | (codepoint & 0x3F)]
    elif codepoint < 0x10000:
        return [0xE0 | (codepoint >> 12), 0x80 | ((codepoint >> 6) & 0x3F), 0x80 | (codepoint & 0x3F)]
    else:
        return [0xF0 | (codepoint >> 18), 0x80 | ((codepoint >> 12) & 0x3F), 
                0x80 | ((codepoint >> 6) & 0x3F), 0x80 | (codepoint & 0x3F)]

# Test various characters including emojis
test_chars = [
    (65, 'A'),           # ASCII
    (233, 'é'),          # Latin Extended
    (20013, '中'),       # CJK
    (128512, '😀'),      # Emoji
    (128640, '🚀'),      # Rocket
    (9829, '♥'),         # Heart
    (127775, '🌟'),      # Star
]

t0 = time.time()
for _ in range(100000):
    for cp, _ in test_chars:
        utf8 = char_to_utf8_bytes(cp)
elapsed = time.time() - t0
print(f"    100K × 7 chars encoded: {elapsed*1000:.2f}ms ({700000/elapsed/1e6:.2f}M encodings/sec)")
results['utf8'] = 700000/elapsed

# 2. EMOJI PATTERN ANALYSIS
print("\n[2] 😀 EMOJI PATTERN ANALYSIS")
print("-" * 50)

# Emoji codepoint ranges
EMOJI_RANGES = [
    (0x1F600, 0x1F64F, "Emoticons 😀-🙏"),
    (0x1F300, 0x1F5FF, "Symbols 🌀-🗿"),
    (0x1F680, 0x1F6FF, "Transport 🚀-🛿"),
    (0x1F1E0, 0x1F1FF, "Flags 🇦-🇿"),
    (0x2600, 0x26FF, "Misc ☀-⛿"),
    (0x2700, 0x27BF, "Dingbats ✀-➿"),
    (0x1F900, 0x1F9FF, "Supplemental 🤀-🧿"),
    (0x1FA00, 0x1FA6F, "Chess/Cards 🨀-🩯"),
]

def is_emoji(codepoint):
    for start, end, _ in EMOJI_RANGES:
        if start <= codepoint <= end:
            return True
    return False

def categorize_emoji(codepoint):
    for i, (start, end, name) in enumerate(EMOJI_RANGES):
        if start <= codepoint <= end:
            return i
    return -1

t0 = time.time()
emoji_counts = [0] * len(EMOJI_RANGES)
for _ in range(1000):
    for cp in range(0x1F600, 0x1F700):
        if is_emoji(cp):
            cat = categorize_emoji(cp)
            if cat >= 0:
                emoji_counts[cat] += 1
elapsed = time.time() - t0
print(f"    Analyzed 256K codepoints: {elapsed*1000:.2f}ms")
print(f"    Emoticons: {emoji_counts[0]//1000}, Symbols: {emoji_counts[1]//1000}, Transport: {emoji_counts[2]//1000}")
results['emoji_analysis'] = 256000/elapsed

# 3. TEXT TOKENIZATION
print("\n[3] 📚 TEXT TOKENIZATION")
print("-" * 50)

def tokenize(text):
    """Simple whitespace + punctuation tokenizer"""
    tokens = []
    current = []
    for char in text:
        if char.isalnum() or ord(char) > 127:  # Keep unicode
            current.append(char)
        else:
            if current:
                tokens.append(''.join(current))
                current = []
            if not char.isspace():
                tokens.append(char)
    if current:
        tokens.append(''.join(current))
    return tokens

test_text = "Hello, World! 🚀 This is a test. 你好世界! Testing 123... émojis: 😀🎉🌟"

t0 = time.time()
for _ in range(50000):
    tokens = tokenize(test_text)
elapsed = time.time() - t0
print(f"    50K tokenizations: {elapsed*1000:.2f}ms ({50000/elapsed:.0f} tokenizations/sec)")
print(f"    Tokens: {tokens[:10]}...")
results['tokenize'] = 50000/elapsed

# 4. N-GRAM GENERATION
print("\n[4] 📊 N-GRAM GENERATION")
print("-" * 50)

def ngrams(tokens, n):
    return [tuple(tokens[i:i+n]) for i in range(len(tokens) - n + 1)]

def char_ngrams(text, n):
    return [text[i:i+n] for i in range(len(text) - n + 1)]

sample_tokens = ["the", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog"]

t0 = time.time()
for _ in range(100000):
    bi = ngrams(sample_tokens, 2)
    tri = ngrams(sample_tokens, 3)
    char_bi = char_ngrams("hello world", 2)
elapsed = time.time() - t0
print(f"    100K × 3 ngram ops: {elapsed*1000:.2f}ms ({300000/elapsed:.0f} ngrams/sec)")
results['ngrams'] = 300000/elapsed

# 5. LEVENSHTEIN DISTANCE
print("\n[5] 📏 EDIT DISTANCE (Levenshtein)")
print("-" * 50)

def levenshtein(s1, s2):
    m, n = len(s1), len(s2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(m + 1):
        dp[i][0] = i
    for j in range(n + 1):
        dp[0][j] = j
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            cost = 0 if s1[i-1] == s2[j-1] else 1
            dp[i][j] = min(dp[i-1][j] + 1, dp[i][j-1] + 1, dp[i-1][j-1] + cost)
    return dp[m][n]

pairs = [
    ("kitten", "sitting"),
    ("hello", "hallo"),
    ("rocket", "🚀"),
    ("emoji", "😀"),
    ("algorithm", "altruistic"),
]

t0 = time.time()
for _ in range(10000):
    for s1, s2 in pairs:
        d = levenshtein(s1, s2)
elapsed = time.time() - t0
print(f"    10K × 5 edit distances: {elapsed*1000:.2f}ms ({50000/elapsed:.0f} distances/sec)")
print(f"    kitten→sitting: {levenshtein('kitten', 'sitting')}")
results['levenshtein'] = 50000/elapsed

# 6. PATTERN MATCHING (Simple regex-like)
print("\n[6] 🔍 PATTERN MATCHING")
print("-" * 50)

def simple_match(pattern, text):
    """Simple pattern matching: * = any chars, ? = any single char"""
    def match(p, t):
        if not p: return not t
        if p[0] == '*':
            return match(p[1:], t) or (t and match(p, t[1:]))
        if p[0] == '?' or (t and p[0] == t[0]):
            return t and match(p[1:], t[1:])
        return False
    return match(pattern, text)

patterns = [
    ("hello*", "hello world"),
    ("*world", "hello world"),
    ("h?llo", "hello"),
    ("🚀*", "🚀 to the moon"),
    ("*😀*", "I am 😀 happy"),
]

t0 = time.time()
matches = 0
for _ in range(10000):
    for p, t in patterns:
        if simple_match(p, t):
            matches += 1
elapsed = time.time() - t0
print(f"    10K × 5 pattern matches: {elapsed*1000:.2f}ms ({50000/elapsed:.0f} matches/sec)")
print(f"    Total matches: {matches}")
results['pattern'] = 50000/elapsed

# 7. SENTIMENT LEXICON
print("\n[7] 💭 SENTIMENT ANALYSIS")
print("-" * 50)

# Simple sentiment lexicon with emojis
POSITIVE = {"good", "great", "excellent", "happy", "love", "amazing", "wonderful", "😀", "😊", "🎉", "❤️", "👍", "🌟", "🚀"}
NEGATIVE = {"bad", "terrible", "awful", "sad", "hate", "horrible", "😢", "😠", "👎", "💔", "😡"}

def sentiment_score(text):
    words = text.lower().split()
    pos = sum(1 for w in words if w in POSITIVE)
    neg = sum(1 for w in words if w in NEGATIVE)
    return pos - neg

texts = [
    "This is great! 😀 Love it! 🎉",
    "Terrible experience, hate it 😢",
    "Good but also bad, 👍👎",
    "Amazing rocket launch 🚀🌟",
    "Neutral statement here",
]

t0 = time.time()
for _ in range(100000):
    for text in texts:
        score = sentiment_score(text)
elapsed = time.time() - t0
print(f"    100K × 5 sentiment scores: {elapsed*1000:.2f}ms ({500000/elapsed:.0f} scores/sec)")
for text in texts[:3]:
    print(f"    '{text[:30]}...': {sentiment_score(text):+d}")
results['sentiment'] = 500000/elapsed

# 8. WORD FREQUENCY
print("\n[8] 📈 WORD FREQUENCY ANALYSIS")
print("-" * 50)

def word_freq(text):
    words = text.lower().split()
    freq = {}
    for w in words:
        freq[w] = freq.get(w, 0) + 1
    return freq

sample_text = "the quick brown fox jumps over the lazy dog the fox is quick and the dog is lazy"

t0 = time.time()
for _ in range(100000):
    freq = word_freq(sample_text)
elapsed = time.time() - t0
print(f"    100K word frequency analyses: {elapsed*1000:.2f}ms ({100000/elapsed:.0f}/sec)")
top_words = sorted(freq.items(), key=lambda x: -x[1])[:5]
print(f"    Top words: {top_words}")
results['wordfreq'] = 100000/elapsed

# 9. EMOJI SENTIMENT MAPPING
print("\n[9] 🎭 EMOJI SENTIMENT MAPPING")
print("-" * 50)

EMOJI_SENTIMENT = {
    0x1F600: 0.9,   # 😀
    0x1F601: 0.9,   # 😁
    0x1F602: 0.8,   # 😂
    0x1F603: 0.8,   # 😃
    0x1F604: 0.9,   # 😄
    0x1F605: 0.6,   # 😅
    0x1F606: 0.7,   # 😆
    0x1F609: 0.7,   # 😉
    0x1F60A: 0.9,   # 😊
    0x1F60D: 0.95,  # 😍
    0x1F614: -0.3,  # 😔
    0x1F622: -0.7,  # 😢
    0x1F62D: -0.8,  # 😭
    0x1F620: -0.9,  # 😠
    0x1F621: -0.95, # 😡
    0x1F680: 0.8,   # 🚀
    0x2764: 0.95,   # ❤️
    0x1F44D: 0.7,   # 👍
    0x1F44E: -0.7,  # 👎
}

def emoji_sentiment(text):
    total = 0
    count = 0
    for char in text:
        cp = ord(char)
        if cp in EMOJI_SENTIMENT:
            total += EMOJI_SENTIMENT[cp]
            count += 1
    return total / count if count > 0 else 0

t0 = time.time()
for _ in range(100000):
    s1 = emoji_sentiment("😀😊🎉🚀")
    s2 = emoji_sentiment("😢😠😡")
    s3 = emoji_sentiment("😀😢")
elapsed = time.time() - t0
print(f"    100K × 3 emoji sentiment: {elapsed*1000:.2f}ms ({300000/elapsed:.0f}/sec)")
print(f"    😀😊🎉🚀 = {emoji_sentiment('😀😊🎉🚀'):.2f}")
print(f"    😢😠😡 = {emoji_sentiment('😢😠😡'):.2f}")
results['emoji_sentiment'] = 300000/elapsed

# 10. TEXT COMPRESSION (Simple RLE)
print("\n[10] 🗜️ TEXT COMPRESSION (RLE)")
print("-" * 50)

def rle_encode(text):
    if not text:
        return []
    result = []
    count = 1
    prev = text[0]
    for char in text[1:]:
        if char == prev:
            count += 1
        else:
            result.append((prev, count))
            prev = char
            count = 1
    result.append((prev, count))
    return result

def rle_decode(encoded):
    return ''.join(char * count for char, count in encoded)

test_strings = [
    "aaabbbcccdddd",
    "🚀🚀🚀🌟🌟",
    "hello world",
    "aaaaaaaaaaaaaaaaaaaa",
]

t0 = time.time()
for _ in range(50000):
    for s in test_strings:
        encoded = rle_encode(s)
        decoded = rle_decode(encoded)
elapsed = time.time() - t0
print(f"    50K × 4 RLE encode+decode: {elapsed*1000:.2f}ms ({200000/elapsed:.0f} ops/sec)")
print(f"    'aaabbbccc' → {rle_encode('aaabbbccc')}")
results['rle'] = 200000/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  🏆 LANGUAGE & EMOJI SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  UTF-8 Encoding:      {results['utf8']/1e6:.2f}M encodings/sec
  Emoji Analysis:      {results['emoji_analysis']/1e3:.1f}K analyses/sec
  Tokenization:        {results['tokenize']/1e3:.1f}K tokenizations/sec
  N-grams:             {results['ngrams']/1e3:.1f}K ngrams/sec
  Edit Distance:       {results['levenshtein']/1e3:.1f}K distances/sec
  Pattern Matching:    {results['pattern']/1e3:.1f}K matches/sec
  Sentiment:           {results['sentiment']/1e3:.1f}K scores/sec
  Word Frequency:      {results['wordfreq']/1e3:.1f}K analyses/sec
  Emoji Sentiment:     {results['emoji_sentiment']/1e3:.1f}K scores/sec
  RLE Compression:     {results['rle']/1e3:.1f}K ops/sec
  
  🌟 TOTAL LANGUAGE SCORE: {total/1e6:.2f}M points 🌟
""")
