#!/bin/bash

set -e  # Exit on any error

# === STEP 1: Install pyenv dependencies ===
echo "🔧 Checking dependencies for pyenv and Python build..."

sudo apt update

REQUIRED_PACKAGES=(
  build-essential curl git libssl-dev zlib1g-dev libbz2-dev
  libreadline-dev libsqlite3-dev wget llvm libncurses5-dev
  libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev
  python3-openssl
)

for pkg in "${REQUIRED_PACKAGES[@]}"; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    echo "📦 Installing $pkg"
    sudo apt install -y "$pkg"
  else
    echo "✅ $pkg already installed"
  fi
done

# === STEP 2: Install pyenv ===
if [ ! -d "$HOME/.pyenv" ]; then
  echo "📥 Installing pyenv..."
  curl https://pyenv.run | bash
else
  echo "✅ pyenv already installed at ~/.pyenv"
fi

# Load pyenv environment
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# === STEP 3: Install Python 3.11.5 if not already or outdated ===
TARGET_PYTHON_VERSION="3.11.5"

if ! pyenv versions --bare | grep -q "^$TARGET_PYTHON_VERSION$"; then
  echo "🐍 Installing Python $TARGET_PYTHON_VERSION with pyenv..."
  pyenv install "$TARGET_PYTHON_VERSION"
else
  echo "✅ Python $TARGET_PYTHON_VERSION already available in pyenv"
fi

pyenv global "$TARGET_PYTHON_VERSION"

# === STEP 4: Create virtual environment ===
if [ ! -d "env" ]; then
  echo "🧪 Creating virtual environment 'env'..."
  python -m venv env
else
  echo "✅ Virtual environment 'env' already exists"
fi

# === STEP 5: Activate and install Python libraries ===
echo "📦 Activating environment and verifying packages..."

source env/bin/activate
pip install --upgrade pip

declare -A packages=(
  [pandas]=2.2.2
  [numpy]=1.26.4
  [scipy]=1.13.1
  [pyarrow]=15.0.2
  [openpyxl]=3.1.2
  [matplotlib]=3.8.4
  [seaborn]=0.13.2
  [plotly]=5.21.0
  [altair]=5.3.0
  [scikit-learn]=1.4.2
  [xgboost]=2.0.3
  [lightgbm]=4.3.0
  [catboost]=1.2.5
  [statsmodels]=0.14.1
  [missingno]=0.5.2
  [tqdm]=4.66.4
  [pyjanitor]=0.25.0
)

for pkg in "${!packages[@]}"; do
  desired_version="${packages[$pkg]}"
  installed_version=$(pip show "$pkg" 2>/dev/null | grep ^Version: | awk '{print $2}')

  if [ -z "$installed_version" ]; then
    echo "📥 Installing $pkg==$desired_version"
    pip install "$pkg==$desired_version"
  elif [ "$installed_version" != "$desired_version" ]; then
    echo "🔁 Upgrading $pkg from $installed_version to $desired_version"
    pip install --upgrade "$pkg==$desired_version"
  else
    echo "✅ $pkg==$desired_version already installed"
  fi
done

echo ""
echo "🎉 Environment setup complete!"
echo "👉 Activate with: source env/bin/activate"

