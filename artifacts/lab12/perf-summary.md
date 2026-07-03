| Dimension | Lab 6 Docker | Lab 12 WASM/Spin |
|---|---:|---:|
| Artifact size | 13,538,083 bytes | 363,281 bytes |
| Cold start p50 | 2700.065 ms | 345.051 ms |
| Warm latency p50 | 9.108 ms | 10.233 ms |
| Warm latency p95 | 12.851 ms | 16.530 ms |

Bonus standalone WASI CLI:

| Dimension | Standalone wasmtime CLI |
|---|---:|
| Artifact size | 196,686 bytes |
| Per-invocation p50 | 12.855 ms |
| Per-invocation p95 | 22.028 ms |
