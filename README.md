# LMS_INTRA

Minimal instructions: how to clone (with submodules) and how to update if you've already cloned.

## Clone (recommended)

Clone this repository and fetch its submodules in one step:

```bash
git clone --recurse-submodules <this-repo-url>
```

## If you already cloned (no submodules yet)

Initialize and fetch all submodules:

```bash
git submodule update --init --recursive
```

## To update submodules to their recorded commits

From the top-level repository run:

```bash
git pull --recurse-submodules
git submodule update --init --recursive
```

If you want to pull the latest commits from each submodule's tracked branch (careful — this moves submodule pointers):

```bash
git submodule update --remote --merge --recursive
```

That's it — if you want a shorter or project-specific README, tell me what to include.
