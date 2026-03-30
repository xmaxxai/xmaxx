# Git-Crypt Workflow

## Purpose

GitHub does not natively manage `git-crypt`. The repository has to be configured so matching files are encrypted before they are written to Git objects.

This repo is wired to encrypt these two paths:

- `xmaxx-infra-workers/terraform.tfvars`
- `xmaxx-infra/kubeconfig.yaml`

Everything else that matches the broader secret patterns in `.gitignore` remains blocked from Git.

## One-Time Bootstrap

1. Install the required tools:

   ```bash
   brew install git-crypt gnupg
   ```

2. Check whether you already have a GPG key:

   ```bash
   gpg --list-secret-keys --keyid-format LONG
   ```

   If you do not, create one:

   ```bash
   gpg --full-generate-key
   ```

3. Initialize `git-crypt` in the repository and grant access to your key:

   ```bash
   git-crypt init
   git-crypt add-gpg-user <your-email>
   ```

4. Add the encrypted files and the `git-crypt` metadata to Git:

   ```bash
   git add .gitattributes .gitignore .git-crypt \
     xmaxx-infra-workers/terraform.tfvars \
     xmaxx-infra/kubeconfig.yaml
   ```

5. Commit and push the change:

   ```bash
   git commit -m "Configure git-crypt for infra secrets"
   git push
   ```

## Collaborator Access

Each collaborator who needs decrypt access must have a GPG key, and an authorized user must add that key to the repo:

```bash
git-crypt add-gpg-user <collaborator-email>
git add .git-crypt
git commit -m "Grant git-crypt access to <collaborator>"
git push
```

After cloning, authorized collaborators unlock the repo with:

```bash
git-crypt unlock
```

## Operational Notes

- `git-crypt` protects future commits. It does not rewrite Git history.
- If a secret was ever committed in plain text, rotate it. If you also need history cleaned, do that as a separate operation.
- Do not add new secret paths to Git without first adding them to `.gitattributes`.
