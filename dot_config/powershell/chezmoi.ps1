# ============================================================
# CHEZMOI ALIASES — Windows / PowerShell port of ~/.zsh/common.zsh
# ============================================================
#
# PowerShell Set-Alias can't bind arguments (e.g. `cza` -> `chezmoi add`),
# so each alias is a function that splats $args to chezmoi. Behaviourally
# identical to the zsh `alias cza="chezmoi add"` form. Dot-source from the
# PowerShell profile.

function cz  { chezmoi @args }
function cza { chezmoi add @args }
function czd { chezmoi diff @args }
function cze { chezmoi edit @args }
function czs { chezmoi status @args }
function czu { chezmoi update @args }   # pull + apply
function czp { chezmoi git push @args }
function czr { chezmoi re-add @args }

# Open the chezmoi source dir (chezmoi cd spawns a new shell there)
function eb  { chezmoi cd @args }
