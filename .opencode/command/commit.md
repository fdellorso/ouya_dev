---
description: Stage and commit current changes following project conventions
---

1. Run `git status` and `git diff --staged` to see what's pending
2. If generated artifacts are staged (zImage, zImage-_, build.log, _.o, linux-build/), unstage them and verify .gitignore covers them
3. Group logically — if changes span unrelated areas (e.g. a fragment edit + a README update), suggest splitting into separate commits rather than committing everything at once
4. Write a commit message prefixed with the area (`kernel:`, `fragment:`, `dts:`, `makefile:`, `docs:`, `scripts:`) per AGENTS.md conventions
5. Show the proposed commit message and ask for confirmation before running `git commit`
6. Do not push automatically — ask first
