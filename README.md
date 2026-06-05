# obfy + Django template

A minimal Django project wired to ship with its source **obfuscated and
AES-256-GCM encrypted** by [obfy](https://github.com/obfy/obfy). `obfy build`
turns `./src` into a drop-in protected mirror (`./protected`) that you serve
exactly like the original — `runserver`, gunicorn, or uvicorn all just work.

```
src/manage.py + config/ + core/  ──► obfy build ──► protected/  ──► runserver / gunicorn
        (your code)                                 (encrypted)
```

## Layout

| Path | What it is |
|------|------------|
| `src/manage.py` | Django entry point (kept as plain source — see below). |
| `src/config/` | Project settings, URLs, WSGI/ASGI. |
| `src/core/` | A sample app. `core/services.py` is the **protected business logic**. |
| `build.sh` | Runs `obfy build` with Django-safe flags. |
| `Pipfile` | Deps (`django`, plus `obfy` as a build tool), managed with pipenv. |
| `protected/` | Generated protected mirror (git-ignored). |

## Prerequisites

- **CPython 3.10–3.13.** Build with the **same Python version** you deploy with —
  obfy's marshalled bytecode is interpreter-version specific.
- macOS, Linux, or Windows.

## Setup

This template uses [pipenv](https://pipenv.pypa.io/) (the `Pipfile` pins
`python_version = "3.12"`):

```bash
pip install --user pipenv          # if you don't have it
pipenv install
```

Prefer plain venv + pip? `python3 -m venv .venv && source .venv/bin/activate &&
pip install "django>=5.0,<6.0" obfy`.

## Develop (unprotected)

Iterate on the real source as usual:

```bash
pipenv run python src/manage.py migrate
pipenv run python src/manage.py runserver
# -> http://127.0.0.1:8000/?units=10
```

## Build the protected tree

```bash
pipenv run build                   # == bash build.sh
```

Then run the **protected** mirror — same commands, different directory:

```bash
pipenv run python protected/manage.py migrate
pipenv run serve                   # == python protected/manage.py runserver
```

`./protected` is a 1:1 mirror of `./src`: each protected `.py` becomes a tiny
self-activating stub, the real code lives encrypted under `protected/__obfy__/`,
and obfy's native loader is bundled in. Decryption happens in memory at import
time; plaintext source never lands on disk.

## Why the build flags matter (Django specifics)

Django resolves a lot of things by **dotted string** — `INSTALLED_APPS`,
`ROOT_URLCONF`, `DJANGO_SETTINGS_MODULE`, model labels like `"core.Quote"`,
view references like `"core.views.quote"`. Two settings in `build.sh` keep that
working:

- **`--level 3`** (not 4/5). Levels 4+ rename *public, cross-module* names; Django
  would then look up names that no longer exist. Level 3 still does docstring
  stripping, string mangling, dead-code injection, and function-local renaming —
  it just leaves public symbol names intact. obfy preserves **module names** at
  every level, so imports and dotted lookups resolve.
- **`--exclude`** keeps the framework plumbing as plain source:
  - `*/manage.py` — invoked directly as a script.
  - `config/settings.py`, `config/wsgi.py`, `config/asgi.py` — located by string
    by Django and the WSGI/ASGI servers.
  - `*/migrations/*` — Django introspects migration modules.

  Excluded `.py` files are copied through verbatim, so they still run. Everything
  else (your `core/services.py`, `core/views.py`, …) is fully protected.

Want maximum protection on a specific module with no Django string coupling? Pull
it into its own package and protect that at a higher level separately.

## Deploying

Serve `./protected` with whatever you already use:

```bash
gunicorn --chdir protected config.wsgi:application
# or
uvicorn config.asgi:application --app-dir protected
```

For Docker, build `./protected` in a build stage and `COPY` it into the image
instead of your source. See
[packaging](https://docs.camouflage.network/obfy/guides/packaging) and
[deploying](https://docs.camouflage.network/obfy/deploying).

## Honest posture

Python obfuscation is **deterrence, not encryption-grade security** — CPython must
eventually execute real bytecode. obfy stops casual copying and raises the cost for
everyone else; it does not replace legal protection for sensitive IP. See the
[honest posture](https://docs.camouflage.network/obfy/guides/obfuscation-levels#honest-posture).

## Docs

Full obfy documentation: **[docs.camouflage.network/obfy](https://docs.camouflage.network/obfy/introduction)**.

## License

MIT — see [LICENSE](./LICENSE). The code you build with this template is yours.
