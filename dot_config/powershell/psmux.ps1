# ============================================================
# PSMUX WRAPPER — Windows / PowerShell port of ~/.zsh/common.zsh `t()`
# ============================================================
#
# `p` mirrors the zsh `t` (tmux) function:
#   - No arguments  → interactive session picker
#       • no sessions   → offer to create one (named, or "default")
#       • one session   → attach directly
#       • many sessions → numbered menu, pick by index OR type a name
#   - With arguments → pass everything straight to `psmux` (e.g. `p new -s work`)
#
# psmux (v3.x) is the tmux-style multiplexer for Windows; see `psmux --help`.
# Dot-source from the PowerShell profile alongside the other managed snippets:
#
#   . "$HOME\.config\powershell\psmux.ps1"
#
# The whole module is a no-op if psmux isn't on PATH, so profile startup stays
# safe on machines that don't have it installed.

# Bail out silently if psmux isn't installed — keeps startup portable.
if (-not (Test-Cmd psmux)) { return }

# ---------------------------------------------------------------------------
# Extract session names from `psmux ls`.
# psmux has no tmux `-F` format flag, so names are parsed from the human-readable
# list. We handle the common line shapes ("name", "name: ...", "name: ... (..)")
# by taking the leading token and trimming a trailing ':'. Isolated here so the
# only thing that changes if the upstream format shifts is this one function.
function Get-PsmuxSessions {
    $raw = & psmux ls 2>$null
    # No server / no sessions: psmux prints nothing useful and/or exits non-zero
    # (matching tmux's `list-sessions` behaviour). Treat both as "no sessions".
    if ($LASTEXITCODE -ne 0 -or -not $raw) { return @() }

    $names = foreach ($line in $raw -split "`r?`n") {
        $line = $line.Trim()
        if (-not $line) { continue }
        # Leading token is the session name; strip an optional trailing colon.
        ($line -split '\s+')[0].TrimEnd(':')
    }
    return $names | Where-Object { $_ }
}

# ---------------------------------------------------------------------------
# `p` — psmux session picker / passthrough. Ported from zsh `t()`; the name `t` now
# belongs to herdr (see herdr.ps1), so the picker lives under `p`.
function p {
    # With arguments: hand them straight to psmux (e.g. `p new -s work`).
    if ($args.Count -gt 0) {
        & psmux @args
        return
    }

    # @() forces an array even with a single session, so .Count is 1 and
    # indexing returns the whole name (not its first character).
    $sessions = @(Get-PsmuxSessions)

    # No active sessions — offer to create one (defaulting to "default").
    if ($sessions.Count -eq 0) {
        Write-Host "No active psmux sessions found."
        $resp = Read-Host "Create a new session? [Y/n]"
        if ($resp -match '^[Nn]$') { return }
        $name = Read-Host "Session name (leave blank for 'default')"
        if ([string]::IsNullOrWhiteSpace($name)) {
            & psmux new-session
        } else {
            & psmux new-session -s $name
        }
        return
    }

    # Exactly one session — attach to it directly, no menu needed.
    if ($sessions.Count -eq 1) {
        Write-Host "Attaching to session: $($sessions[0])"
        & psmux attach-session -t $sessions[0]
        return
    }

    # Multiple sessions — show a numbered list, accept index OR name.
    Write-Host "Active psmux sessions:"
    for ($i = 0; $i -lt $sessions.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), $sessions[$i])
    }

    # NOTE: $choice, not $input — `$input` is a PowerShell automatic variable
    # and assigning to it is unreliable.
    $choice = Read-Host "Select session [1-$($sessions.Count)] or enter name"
    if ([string]::IsNullOrWhiteSpace($choice)) { return }

    $target = $null
    $n = 0
    if ([int]::TryParse($choice, [ref]$n) -and $n -ge 1 -and $n -le $sessions.Count) {
        $target = $sessions[$n - 1]          # numeric → pick by index
    } else {
        $target = $choice                    # non-numeric → treat as a name
    }

    if (& psmux has-session -t $target 2>$null) {
        & psmux attach-session -t $target
    } else {
        Write-Host "Error: Session '$target' not found."
    }
}
