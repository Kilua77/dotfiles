# layers-fixture

A minimal conforming layer — one topic, one R1 symlink, one installer, one
check — used by CI and local testing to exercise the layer engine without
touching any private repository. It is never linked by the engine's own
bootstrap: `script/` is not a topic.

`layers add` requires a git repository, and this fixture lives inside the
engine repo, so tests first materialize it as one:

```sh
tmp="$(mktemp -d)"
cp -R ~/.dotfiles/script/tests/layers-fixture "$tmp/fixture"
git -C "$tmp/fixture" init -q && git -C "$tmp/fixture" add -A
git -C "$tmp/fixture" -c user.email=ci@invalid -c user.name=ci commit -qm fixture
~/.dotfiles/script/layers add "$tmp/fixture"
```

CI runs the same shape in `.github/workflows/lint.yml` (job `layers-smoke`)
with `HOME` pointed at a scratch directory.
