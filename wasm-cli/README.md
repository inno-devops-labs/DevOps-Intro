# Moscow Time WASI CLI

Standalone WASI version of the Lab 12 Moscow-time endpoint.

Build:

```bash
tinygo build -o main.wasm -target=wasi -no-debug ./main.go
```

Run:

```bash
wasmtime run --env REQUEST_METHOD=GET --env PATH_INFO=/time main.wasm
```
