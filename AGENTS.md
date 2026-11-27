# Rules for editing this repo (humans and AI agents)

## Bitwarden secrets in templates — the contract

Goal: `chezmoi apply` must succeed on EVERY machine, including ones with no `bw`, no network or a locked vault.
Missing secrets degrade to empty/commented values; they never fail the apply.

1. **Never call `bw`, `bitwarden`, `bitwardenFields` or `bitwardenAttachment` directly in a template.**
   Those fail hard when bw is absent or locked. Use the shared helpers in `.chezmoitemplates/`:
   - `{{ includeTemplate "bw-ready" . }}` → `1` only when bw is installed AND unlocked.
   - `{{ includeTemplate "bw-item" "chezmoi/<name>" | fromJson }}` → the item as a dict, or `{}` (with a warning) when unavailable.
2. **Always read from the result defensively:** `dig "fields" (list) $item`, `dig "login" "password" "" $item`,
   `dig "sshKey" "privateKey" "" $item`. Never `$item.login.password` (errors on `{}`).
3. **Vault item names:** `chezmoi/<purpose>` (e.g. `chezmoi/zsh-secrets`, `chezmoi/ssh/<file>.key`).
   - Must be **unique, and no name may be a substring of another** (`bw get` matches substrings; the helper matches exactly but keep it unambiguous anyway).
   - Put many related env vars in ONE secure note with a hidden custom field per variable; one SSH key per `sshKey` item.
4. **Prefer `create_` (write once, never overwrite) for hand-editable files** like `~/.zsh_secrets`, with a commented
   `# export NAME=` line for every variable so a machine without bw can fill them in by hand.
   Use plain templates only for files that must always mirror the vault.
5. **Whole files that are only useful with their secret** (ssh keys, token files): add them to the `bw-ready` block of
   `.chezmoiignore` so they are skipped (not written empty) when bw is unavailable. Use `private_` prefixes (0600/0700).
6. **Quote values for the target format:** shell → `printf "'%s'" (replace "'" "'\\''" $v)`; TOML/JSON/YAML → `toToml`/`toJson`/`quote`.
7. **No secret value, IP, email or personal name in this repo** (leak gate `tools/check-public.sh`). Item names are fine;
   hostnames of your vault are not (use placeholders in docs).
8. **Test all four states before committing** (`chezmoi execute-template < file.tmpl`):
   - unlocked: values appear;  - `env -u BW_SESSION`: fallback, rc 0;  - `BW_SESSION=bogus`: fallback, rc 0;
   - `PATH=/usr/bin:/bin`: (bw missing) fallback, rc 0.
   Then `tools/check-public.sh --tree`.
9. **Adding a secret:** create the item/field in the vault (`bw sync` afterwards), add its name to the `list` in the template
   (and a `# export NAME=` fallback is generated automatically), run the four-state test, document nothing sensitive.
10. Never commit rendered output, never print secret values in logs, and rotate anything that was ever committed in plain text.
