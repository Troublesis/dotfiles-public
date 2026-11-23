# ============================================================
# PSREADLINE — prediction + completion behaviour (interactive hosts only)
# ============================================================
# Moved here from the unmanaged OneDrive host profile so chezmoi tracks it.
# Skipped when output is redirected (PredictionSource throws without VT support).
if ([Console]::IsOutputRedirected -or -not $host.UI.SupportsVirtualTerminal) { return }

try {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
    Set-PSReadLineOption -BellStyle None                       # no beep on errors
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -Colors @{ InlinePrediction = '#f2ddcc' }
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete   # menu-style tab completion
} catch {
    # Older PSReadLine (Windows PowerShell 5.1) lacks prediction; ignore.
}
