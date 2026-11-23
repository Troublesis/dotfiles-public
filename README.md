# dotfiles-public

Shell, terminal and tool configuration managed with [chezmoi](https://www.chezmoi.io):
**zsh · bash · PowerShell · cmd · tmux · starship · yazi · herdr · ghostty · kitty · alacritty ·
helix · nvim · btop · fish**, plus idempotent installers for macOS, Linux, a NAS and Windows.

This repo contains **no secrets and no personal data** — that is enforced, not just promised
(see [Leak gate](#leak-gate)). Anything private (SSH keys, tokens, hostnames, work identity) lives
in a separate private *overlay* repo that is applied on top of this one.

## Use it

```sh
chezmoi init --apply Troublesis/dotfiles-public
```

`chezmoi init` asks a few questions once and remembers the answers in
`~/.config/chezmoi/chezmoi.toml`:

| Question | Meaning |
|---|---|
| Host class | `default`, `macbook`, `mac-studio`, `nas`, `code-server` (Windows is automatic) |
| Is this the home machine? | switches a few home-network-only defaults |
| Low-spec machine? | trims the zsh prompt/plugins |
| age recipient | public key of your private overlay; blank = no encryption |
| GitHub noreply email | commit identity used inside this checkout (see below) |

## Already using a private dotfiles repo? (instructions for humans and AI agents)

This repo is the **primary** chezmoi source (`~/.local/share/chezmoi`). A private repo, if you
have one, is a second source — the *overlay* — at `~/.local/share/dotfiles-private`. Work out
which state a machine is in, then follow the matching row:

```sh
git -C ~/.local/share/chezmoi remote get-url origin      # which repo is the source?
ls -d ~/.local/share/dotfiles-private/.git               # is an overlay present?
```

| State | Action |
|---|---|
| source origin is **your private repo** (old layout) | **Migrate** (below) |
| source origin is this repo, overlay present | nothing — `chezmoi update` pulls both |
| source origin is this repo, no overlay, you have a private repo | clone it to `~/.local/share/dotfiles-private`, then `chezmoi init && chezmoi apply` |
| no `~/.local/share/chezmoi` | fresh machine: `chezmoi init --apply Troublesis/dotfiles-public`, add the overlay afterwards if you have one |

The private repo documents its own URL, branch and exact commands in **its** README — read
that first if you can. The generic procedure is:

1. **Back up and check clean.** `cp ~/.config/chezmoi/chezmoi.toml{,.pre-split}`; the old
   clone must have no uncommitted/unpushed work (`git -C ~/.local/share/chezmoi status`).
2. **Old clone becomes the overlay** (moved, nothing deleted):
   `mv ~/.local/share/chezmoi ~/.local/share/dotfiles-private`, then switch it to the branch
   that holds the slimmed overlay (the private README names it; `git fetch origin && git switch <branch>`).
3. **Clone this repo as the source:**
   `git clone https://github.com/Troublesis/dotfiles-public.git ~/.local/share/chezmoi`
4. **Regenerate the config.** The new template adds two prompts. Keep the existing age
   recipient (read it from the old config: `chezmoi dump-config --format json | jq -r '(.age.recipients // [.age.recipient])[0]'`)
   and pass both answers non-interactively; the existing `hostclass`/`is_home`/… answers are kept:
   ```sh
   chezmoi init \
     --promptString "age recipient public key for the private overlay (leave blank for none)=<age-public-key>" \
     --promptString "GitHub noreply email for commits in this repo (leave blank to skip)=<id>+<user>@users.noreply.github.com"
   ```
5. **Review, then apply:** `chezmoi diff --exclude=scripts` (expect ~nothing: same files, now
   owned by two sources), then `chezmoi apply`. The overlay is applied by the last hook.
6. **Verify:** `chezmoi status` is empty, `chezmoi update` pulls both repos, a new `zsh -l` starts clean.

Rollback: `rm -rf ~/.local/share/chezmoi` (only the fresh public clone),
`mv ~/.local/share/dotfiles-private ~/.local/share/chezmoi`, switch it back to its old branch,
restore `chezmoi.toml.pre-split`.

Rules for agents: never edit deployed files in `~/`; edit the source clone. Public-able config
goes in **this** repo; secrets and personal data go in the overlay. Don't run both a home and a
work overlay on one machine. `autoCommit`/`autoPush` are off — commit with the normal reviewed
workflow, never bypass the gate (`SKIP_GATE=1`) to push.

## Layout

| Path | What |
|---|---|
| `dot_config/<tool>/` | per-tool config (`starship`, `yazi`, `herdr`, `nvim`, …) |
| `private_dot_tmux.conf.tmpl`, `dot_tmux/` | tmux config + OS/host-class fragments |
| `dot_zsh/`, `executable_dot_zshrc`, `dot_bashrc` | shell setup and generic aliases |
| `run_once_*`, `run_onchange_*` | package/tool installers per OS |
| `.chezmoiscripts/` | git-hook setup and the optional private-overlay hook |
| `tools/check-public.sh` | the leak gate |

## Optional private overlay

If a git clone exists at `~/.local/share/dotfiles-private`, `run_after_90-private-overlay`
pulls it and applies it as a **second chezmoi source** (with its own state file). On a
public-only machine that hook is a no-op. The overlay can ship `~/.zsh/personal.zsh`,
`~/.bashrc.personal` and `~/.config/powershell/personal.ps1`, which the public shell files
source when present.

## Leak gate

`tools/check-public.sh` runs as a `pre-commit` and `pre-push` hook and in CI:

- **Generic layer (always):** forbidden file names (`*.age`, keys, `.env`), IPv4 literals,
  home-directory paths, email addresses, private-key headers, and `gitleaks`.
- **Personal layer (local only):** regexes from `~/.config/dotfiles/denylist`, shipped by the
  private overlay. It is never stored here — a denylist in a public repo would leak its own words.
- **Identity:** every commit must use a GitHub `…@users.noreply.github.com` address.

Mark a deliberate exception on a line with `gate:allow`.

## Safety defaults

`autoCommit` and `autoPush` are **off** in the generated chezmoi config, so `chezmoi add`
never publishes anything on its own.

## License

MIT — see [LICENSE](LICENSE).
