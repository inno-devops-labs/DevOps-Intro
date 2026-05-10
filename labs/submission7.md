### Task 1

#### 1.1: Setup Desired State Configuration

```bash
$ echo "version: 1.0" > desired-state.txt
$ echo "app: myapp" >> desired-state.txt
$ echo "replicas: 3" >> desired-state.txt

$ cp desired-state.txt current-state.txt
$ echo "Initial state synchronized"
Initial state synchronized
```

Initial `desired-state.txt`:

```bash
version: 1.0
app: myapp
replicas: 3
```

Initial `current-state.txt`:

```bash
version: 1.0
app: myapp
replicas: 3
```

#### 1.2: Create Reconciliation Loop

Created `reconcile.sh` and made it executable:

```bash
$ chmod +x reconcile.sh
```

#### 1.3: Test Manual Drift Detection

I changed the current state manually:

```bash
$ echo "version: 2.0" > current-state.txt
$ echo "app: myapp" >> current-state.txt
$ echo "replicas: 5" >> current-state.txt
```

Then ran reconciliation:

```bash
$ ./reconcile.sh
Sun May 10 12:55:01 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun May 10 12:55:01 MSK 2026 - ✅ Reconciliation complete
```

After reconciliation:

```bash
$ diff desired-state.txt current-state.txt
```

```bash
$ cat current-state.txt
version: 1.0
app: myapp
replicas: 3
```

#### 1.4: Automated Continuous Reconciliation

Initially `watch` was not installed, so I installed it with Homebrew and then started the loop:

```bash
$ watch -n 5 ./reconcile.sh
```

Output from continuous reconciliation loop after triggering drift:

```bash
Every 5.0s: ./reconcile.sh                                                            TomatoComputer.local: Sun May 10 12:57:52 2026

Sun May 10 12:57:52 MSK 2026 - ⚠️  DRIFT DETECTED!
Reconciling current state with desired state...
Sun May 10 12:57:52 MSK 2026 - ✅ Reconciliation complete
```

This shows that the loop detected drift and automatically restored the desired state.

### Observations and Analysis

The GitOps reconciliation loop continuously compares the current state with the desired state stored in Git. If drift appears, the loop detects it and replaces the current state with the desired one. This prevents configuration drift because any manual or unintended change is overwritten during the next reconciliation cycle.

Declarative configuration is better than imperative commands in production because it defines the final expected state instead of a sequence of manual actions. This makes changes easier to review, version, repeat, and recover.

