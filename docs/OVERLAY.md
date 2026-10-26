# Overlay

**Superseded by [docs/LAYERS.md](LAYERS.md)** — the two-repo overlay
described here grew into the general layer contract: the engine (this
repo) applies N private layers through `script/setup --layer <url>`,
`--root`-parameterized bootstrap/install, `script/layers` (the machine's
registry), `script/audit` (pairwise disjointness) and `script/doctor`
(per-layer checks + `<topic>/check.sh` hooks). The "why an overlay"
split-criteria table below still holds; the mechanics are all engine-side
now — a layer carries **no scripts at all**.

| Goes public if… | Goes in a layer if… |
|---|---|
| a stranger could reuse it as-is | it is tied to you, an account, or one environment |
| it holds no secrets | it holds credentials, hosts, or personal device settings |
| it works anywhere | it only works on one machine or inside one editor profile |

One rule: **if you would hesitate to publish it, it belongs in a layer.**

The rest of this document described the pre-contract mechanics (copying
`script/bootstrap` verbatim into the overlay, the manual apply order, the
hand-rolled `comm -12` audit). It is retired; `git log -- docs/OVERLAY.md`
keeps the history for the porting audit.
