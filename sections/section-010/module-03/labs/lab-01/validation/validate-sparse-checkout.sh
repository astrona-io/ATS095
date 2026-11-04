#!/usr/bin/env bash
# Confirms the sparse checkout of fleet includes apps and is still a list, not removed
set -uo pipefail
fail() { echo "FAIL: $*"; exit 1; }

LIST="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.spec.sparseCheckout[*]}' 2>/dev/null)"
OBSERVED="$(kubectl -n flux-system get gitrepository fleet -o jsonpath='{.status.observedSparseCheckout[*]}' 2>/dev/null)"
[ -n "$LIST" ] || fail "spec.sparseCheckout was removed; keep a list of directories that includes apps."
case " $LIST " in
  *" apps "*) ;;
  *) fail "spec.sparseCheckout must include apps (found: $LIST)." ;;
esac
case " $OBSERVED " in
  *" apps "*) ;;
  *) fail "the current artifact was not built with apps (observed: ${OBSERVED:-none})." ;;
esac
echo "PASS: sparseCheckout is '$LIST'."
