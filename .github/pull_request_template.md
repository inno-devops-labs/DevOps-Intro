git switch main
mkdir -p .github
cat > .github/pull_request_template.md << 'EOF'
## Goal
<!-- What does this PR accomplish? 1 sentence. -->

## Changes
- 

## Testing
<!-- How did you verify it? -->

## Checklist
- [ ] Title is a clear sentence (≤ 70 chars)
- [ ] Commits are signed (`git log --show-signature`)
- [ ] `submissions/labN.md` updated
EOF
git add .github/pull_request_template.md
git commit -S -s -m "docs: add PR template"
git push origin main