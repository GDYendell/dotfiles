# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/). Each application is a self-contained stow package.

## Structure

```
dotfiles/
  <package>/
    .config/        # mirrors ~/.config/
    .local/         # mirrors ~/.local/
    .install/
      <package>.sh  # post-stow setup script
```

Each package directory mirrors the home directory. Stowing a package creates symlinks from `~` into the package. For example, `dotfiles/foo/.config/foo/config.toml` becomes `~/.config/foo/config.toml`.

## Stowing

From `~/dotfiles`:

```bash
stow <package>       # stow a package
stow --restow <package>  # restow after adding or removing files
stow --delete <package>  # remove symlinks
```

## Install scripts

Some applications require steps beyond symlinking files — enabling services, running post-install commands, etc. These go in `.install/<package>.sh` inside the package, which stow links to `~/.install/<package>.sh`.

Install scripts must be idempotent. After stowing a package, run its install script:

```bash
~/.install/<package>.sh
```

There is no top-level install orchestration. Run whichever scripts are relevant for the machine being set up.

## Relationship to Omarchy

These dotfiles are designed to layer on top of [Omarchy](https://github.com/basecamp/omarchy) defaults, but also work on non-Omarchy machines. When adopting an application that Omarchy configures, use the Omarchy config as the reference and pull in what makes sense. Omarchy-specific behaviour (themed styles, Omarchy-specific scripts) should be left to Omarchy and not duplicated here.
