# Flags #
_Folder for abstract (dev-related) "flags" related to installation status, etc._

## Contents ##
Everything in this folder should be a `*.yaml` file (except this markdown document).

* `installed.yaml` - Put here when installation is run via `install.m`
  + This is checked by `install.m` and if it exists, then packages are not re-installed needlessly.