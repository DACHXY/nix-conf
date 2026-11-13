# Author identities that apply only when a repo has a matching remote URL.
#
# Consumed by:
#   - modules/users/danny/git.nix      -> git `includeIf hasconfig:remote.*.url`
#   - modules/jujutsu.nix              -> `jj` wrapper setting JJ_USER / JJ_EMAIL
#     (jj has no remote-URL condition; it only supports path-based `--when`)
#
# Key is a substring of the remote URL (usually the host).
{
  "gitlab.it.cs.nycu.edu.tw" = {
    name = "Chen-Wei Chang";
    email = "cchenwei@cs.nctu.edu.tw";
  };
}
