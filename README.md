# LMS_INTRA

This repository (LMS_INTRA) uses two git submodules to include related projects:

- `GLOBAL-AUTH` — https://github.com/um6p-vanguard/GLOBAL-AUTH
- `LMS_FRONT`  — https://github.com/mbifenzi/LMS_FRONT

Both submodules are added at the repository root (folders `GLOBAL-AUTH/` and `LMS_FRONT/`).

## Quickstart

Clone this repository and fetch the submodules in one step:

```bash
git clone --recurse-submodules <this-repo-url>
```

If you already cloned without submodules, initialize and fetch them with:

```bash
git submodule update --init --recursive
```

To fetch the latest commits for each submodule and update the working tree:

```bash
git submodule update --remote --merge --recursive
```

## Working with submodules

- To enter a submodule directory and inspect or change its code:

```bash
cd GLOBAL-AUTH
# or
cd LMS_FRONT
```

- If you make changes inside a submodule and want those changes to be tracked:

  1. Commit and push changes from within the submodule repository (it has its own .git):

  ```bash
  # inside submodule folder
  git add .
  git commit -m "Describe change"
  git push origin <branch>
  ```

  2. Then, in the top-level repository, record the new submodule commit and push:

  ```bash
  cd ..               # back to top-level LMS_INTRA
  git add GLOBAL-AUTH LMS_FRONT
  git commit -m "Update submodule(s) to latest commit"
  git push origin <branch>
  ```

## Changing which branch a submodule tracks

By default submodules point to a specific commit. To have a submodule follow a branch:

```bash
cd GLOBAL-AUTH
git checkout <branch>
git pull
cd ..
git add GLOBAL-AUTH
git commit -m "Point GLOBAL-AUTH submodule to <branch>"
git push
```

You can also configure tracking in `.gitmodules` and then run:

```bash
git submodule sync --recursive
git submodule update --init --remote --recursive
```

## Common commands

- Show submodule status:

```bash
git submodule status --recursive
```

- Re-sync `.git/config` with `.gitmodules` after manual edits:

```bash
git submodule sync --recursive
```

- Remove a submodule cleanly (example for `GLOBAL-AUTH`):

```bash
git submodule deinit -f GLOBAL-AUTH
git rm -f GLOBAL-AUTH
rm -rf .git/modules/GLOBAL-AUTH
git commit -m "Remove GLOBAL-AUTH submodule"
```

## Notes

- Submodules are separate Git repositories. The top-level repo stores only a pointer (a gitlink) to the commit of each submodule. When you update a submodule's commit you must commit that pointer in the top-level repo.
- If you want the submodule contents to be copied into this repo instead of being a submodule, say so and I can replace them with directory copies.

If you want, I can also push the new commit (which adds the submodules) to your remote — tell me if you'd like me to do that now.
