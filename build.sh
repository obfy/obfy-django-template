#!/usr/bin/env bash
#
# Protect the Django project in ./src into a drop-in mirror at ./protected.
# Run it with:  python protected/manage.py runserver   (or gunicorn config.wsgi)
#
# Use the SAME Python you deploy with — obfy's marshal/bytecode format is
# interpreter-version specific.
set -euo pipefail

PYTHON="${PYTHON:-python3}"

rm -rf protected

# --level 3 stops BELOW cross-module public-name renaming on purpose: Django
#   resolves a lot by dotted string (INSTALLED_APPS, ROOT_URLCONF, model labels,
#   "app.views.fn" references) and renaming public names would break those lookups.
# --exclude keeps the framework plumbing as plain source: settings/wsgi/asgi are
#   located by string, manage.py is run as a script, and Django introspects
#   migration modules as source.
obfy build --src ./src --out ./protected --python "$PYTHON" --level 3 \
  --exclude "*/migrations/*" \
  --exclude "*/manage.py" \
  --exclude "*/config/settings.py" \
  --exclude "*/config/wsgi.py" \
  --exclude "*/config/asgi.py"

echo
echo "Done. Serve it with:  python protected/manage.py runserver"
