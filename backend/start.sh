#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR" || exit

echo "Starting NST-AI Backend Server..."

# Check if virtual environment exists, create if not
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install/upgrade essential dependencies
echo "Installing/upgrading essential dependencies..."
pip install --upgrade pip

# Install core FastAPI and server dependencies
echo "Installing core server dependencies..."
pip install fastapi uvicorn pydantic aiohttp python-multipart starlette-compress itsdangerous

# Install authentication and security
echo "Installing authentication dependencies..."
pip install python-jose cryptography passlib bcrypt PyJWT authlib

# Install database dependencies
echo "Installing database dependencies..."
pip install sqlalchemy alembic peewee peewee-migrate asyncpg psycopg2-binary

# Install utility dependencies
echo "Installing utility dependencies..."
pip install requests redis python-dotenv watchdog loguru pytz markdown beautifulsoup4 asgiref

# Install websocket and real-time dependencies
echo "Installing websocket dependencies..."
pip install python-socketio websockets pycrdt

# Install data processing dependencies
echo "Installing data processing dependencies..."
pip install httpx email-validator jsonschema

# Install OpenTelemetry for monitoring
echo "Installing monitoring dependencies..."
pip install opentelemetry-api opentelemetry-sdk

# Install AI/ML dependencies (if needed)
if [[ "${INSTALL_ML_DEPS}" == "true" ]]; then
    echo "Installing ML dependencies..."
    pip install torch transformers sentence-transformers scikit-learn numpy scipy
fi

# Install MongoDB dependencies (if needed)
if [[ "${USE_MONGODB}" == "true" ]]; then
    echo "Installing MongoDB dependencies..."
    pip install motor pymongo
fi

# Set PYTHONPATH for proper module resolution
export PYTHONPATH="$SCRIPT_DIR:$PYTHONPATH"

# Add conditional Playwright browser installation
if [[ "${WEB_LOADER_ENGINE}" == "playwright" ]]; then
    if [[ -z "${PLAYWRIGHT_WS_URL}" ]]; then
        echo "Installing Playwright browsers..."
        pip install playwright
        playwright install chromium
        playwright install-deps chromium
    fi

    python -c "import nltk; nltk.download('punkt_tab')" 2>/dev/null || echo "NLTK punkt_tab download skipped"
fi

if [ -n "${WEBUI_SECRET_KEY_FILE}" ]; then
    KEY_FILE="${WEBUI_SECRET_KEY_FILE}"
else
    KEY_FILE=".webui_secret_key"
fi

PORT="${PORT:-8080}"
HOST="${HOST:-0.0.0.0}"
if test "$WEBUI_SECRET_KEY $WEBUI_JWT_SECRET_KEY" = " "; then
  echo "Loading WEBUI_SECRET_KEY from file, not provided as an environment variable."

  if ! [ -e "$KEY_FILE" ]; then
    echo "Generating WEBUI_SECRET_KEY"
    # Generate a random value to use as a WEBUI_SECRET_KEY in case the user didn't provide one.
    echo $(head -c 12 /dev/random | base64) > "$KEY_FILE"
  fi

  echo "Loading WEBUI_SECRET_KEY from $KEY_FILE"
  WEBUI_SECRET_KEY=$(cat "$KEY_FILE")
fi

if [[ "${USE_OLLAMA_DOCKER}" == "true" ]]; then
    echo "USE_OLLAMA is set to true, starting ollama serve."
    ollama serve &
fi

if [[ "${USE_CUDA_DOCKER}" == "true" ]]; then
  echo "CUDA is enabled, appending LD_LIBRARY_PATH to include torch/cudnn & cublas libraries."
  export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib/python3.11/site-packages/torch/lib:/usr/local/lib/python3.11/site-packages/nvidia/cudnn/lib"
fi

# Check if SPACE_ID is set, if so, configure for space
if [ -n "$SPACE_ID" ]; then
  echo "Configuring for HuggingFace Space deployment"
  if [ -n "$ADMIN_USER_EMAIL" ] && [ -n "$ADMIN_USER_PASSWORD" ]; then
    echo "Admin user configured, creating"
    WEBUI_SECRET_KEY="$WEBUI_SECRET_KEY" uvicorn nst_ai.main:app --host "$HOST" --port "$PORT" --forwarded-allow-ips '*' &
    webui_pid=$!
    echo "Waiting for webui to start..."
    while ! curl -s http://localhost:8080/health > /dev/null; do
      sleep 1
    done
    echo "Creating admin user..."
    curl \
      -X POST "http://localhost:8080/api/v1/auths/signup" \
      -H "accept: application/json" \
      -H "Content-Type: application/json" \
      -d "{ \"email\": \"${ADMIN_USER_EMAIL}\", \"password\": \"${ADMIN_USER_PASSWORD}\", \"name\": \"Admin\" }"
    echo "Shutting down webui..."
    kill $webui_pid
  fi

  export WEBUI_URL=${SPACE_HOST}
fi

PYTHON_CMD=$(command -v python3 || command -v python)

echo "Starting server with Python command: $PYTHON_CMD"
echo "Host: $HOST, Port: $PORT"
echo "PYTHONPATH: $PYTHONPATH"

# Use uvicorn with proper module path
WEBUI_SECRET_KEY="$WEBUI_SECRET_KEY" exec "$PYTHON_CMD" -m uvicorn nst_ai.main:app --host "$HOST" --port "$PORT" --forwarded-allow-ips '*' --workers "${UVICORN_WORKERS:-1}"
