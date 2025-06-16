#!/bin/bash

set -e  # Exit on error

# === STEP 1: Install pyenv dependencies ===
echo "🔧 Installing dependencies for pyenv and Python build..."

sudo apt update
sudo apt install -y build-essential curl git libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev wget llvm libncurses5-dev \
  libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl

# === STEP 2: Install pyenv ===
if ! command -v pyenv >/dev/null 2>&1; then
  echo "📥 Installing pyenv..."
  curl https://pyenv.run | bash
fi

# Load pyenv environment for current shell session
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# === STEP 3: Install Python 3.11.5 with pyenv if not installed ===
if ! pyenv versions --bare | grep -q '^3.11.5$'; then
  echo "🐍 Installing Python 3.11.5 with pyenv..."
  pyenv install 3.11.5
fi

pyenv global 3.11.5

# === STEP 4: Create virtual environment ===
echo "🧪 Creating virtual environment 'env'..."

python -m venv env

# === STEP 5: Activate and install libraries ===
echo "📦 Activating environment and installing libraries..."

source env/bin/activate

pip install --upgrade pip

pip install \
  pandas==2.2.2 \
  numpy==1.26.4 \
  scipy==1.13.1 \
  pyarrow==15.0.2 \
  openpyxl==3.1.2 \
  matplotlib==3.8.4 \
  seaborn==0.13.2 \
  plotly==5.21.0 \
  altair==5.3.0 \
  scikit-learn==1.4.2 \
  xgboost==2.0.3 \
  lightgbm==4.3.0 \
  catboost==1.2.5 \
  statsmodels==0.14.1 \
  missingno==0.5.2 \
  tqdm==4.66.4 \
  pyjanitor==0.25.0

echo "✅ Setup complete. Activate with: source env/bin/activate"

