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
