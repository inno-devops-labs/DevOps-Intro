import sys

def uleb(b, i):
    r = s = 0
    while True:
        x = b[i]; i += 1
        r |= (x & 0x7f) << s
        if not x & 0x80: return r, i
        s += 7

data = open(sys.argv[1], 'rb').read()
assert data[:4] == b'\x00asm', "not a wasm file"
i = 8
kinds = {0: 'func', 1: 'table', 2: 'mem', 3: 'global'}
while i < len(data):
    sid = data[i]; i += 1
    size, i = uleb(data, i)
    end = i + size
    if sid == 7:  # export section
        n, i = uleb(data, i)
        print(f"{sys.argv[1]}: {n} exports")
        for _ in range(n):
            ln, i = uleb(data, i)
            name = data[i:i+ln].decode(); i += ln
            k = data[i]; i += 1
            _, i = uleb(data, i)
            print(f"   [{kinds.get(k,k)}] {name}")
    i = end
