a) Why pin ubuntu version instead of ubuntu-latest?

Because ubuntu-latest is a moving target. GitHub changes it without warning (e.g. 22.04 → 24.04). That can break builds unexpectedly due to:

* different Go preinstalled versions
* different system libraries
* different shell/tools behavior

Pinning ensures reproducibility and stable CI behavior.



b) Why split vet, test, lint into separate jobs?

Splitting gives:

* parallel execution (faster CI)
* clearer failure reporting
* isolation (lint failure doesn’t hide test failure)
* better caching and scalability

If combined:

* everything runs sequentially
* one failure may stop later checks
* slower feedback loop
* harder to diagnose issues


c) Why SHA pinning matters? What attack does it prevent?

SHA pinning prevents supply chain attacks via GitHub Actions tampering.

If you use a tag like @v4, that tag can be moved or compromised. A malicious update could inject code into your CI pipeline.

SHA pinning ensures:

* exact immutable action version is used
* prevents “tag hijacking”

Example incident:

* 2022-03 GitHub Actions supply chain risk awareness (reviewdog / tj-actions ecosystem warnings and compromise discussions widely highlighted in March 2022 security advisories)

Core idea: attackers can modify tags or upstream actions → CI becomes entry point.


d) What is permissions: and principle behind it?

permissions: defines what the workflow is allowed to do.

Example:

permissions:
 contents: read
