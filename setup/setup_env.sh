#!/bin/bash

set -e  # Exit on any error

# === Detect OS and set package manager ===
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  PKG_MANAGER="apt"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  PKG_MANAGER="brew"
else
  echo "❌ Unsupported OS: $OSTYPE"
  exit 1
fi

# === STEP 1: Install system dependencies ===
echo "🔧 Checking dependencies for pyenv and Python build on $PKG_MANAGER..."

if [ "$PKG_MANAGER" = "apt" ]; then
  sudo apt update

  REQUIRED_PACKAGES=(
    build-essential curl git libssl-dev zlib1g-dev libbz2-dev
    libreadline-dev libsqlite3-dev wget llvm libncurses5-dev
    libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev
    python3-openssl cmake
  )

  for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      echo "📦 Installing $pkg"
      sudo apt install -y "$pkg"
    else
      echo "✅ $pkg already installed"
    fi
  done

elif [ "$PKG_MANAGER" = "brew" ]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "🍺 Homebrew not found, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  BREW_PACKAGES=(
    openssl readline sqlite3 xz zlib tcl-tk llvm libomp cmake
  )

  for pkg in "${BREW_PACKAGES[@]}"; do
    if ! brew list "$pkg" >/dev/null 2>&1; then
      echo "📦 Installing $pkg"
      brew install "$pkg"
    else
      echo "✅ $pkg already installed"
    fi
  done

  export CXX=/usr/bin/clang++
  export CC=/usr/bin/clang
  export LDFLAGS="-L/opt/homebrew/opt/libomp/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/libomp/include"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/libomp/lib/pkgconfig"
fi

# === STEP 2: Install pyenv ===
if [ ! -d "$HOME/.pyenv" ]; then
  echo "📥 Installing pyenv..."
  curl https://pyenv.run | bash
else
  echo "✅ pyenv already installed at ~/.pyenv"
fi

# Load pyenv environment if pyenv command exists or ~/.pyenv/bin is in PATH
if command -v pyenv >/dev/null 2>&1 || [ -d "$HOME/.pyenv" ]; then
  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
else
  echo "❌ pyenv not found, skipping pyenv init"
fi

# Fix pyenv permissions if needed
if [ -d "$HOME/.pyenv/shims" ] && [ ! -w "$HOME/.pyenv/shims" ]; then
  echo "🔧 Fixing pyenv shims directory permissions..."
  sudo chown -R "$USER:$USER" "$HOME/.pyenv"
  chmod -R u+w "$HOME/.pyenv/shims"
fi


# === STEP 3: Install Python 3.11.5 ===
TARGET_PYTHON_VERSION="3.11.5"

if ! pyenv versions --bare | grep -q "^$TARGET_PYTHON_VERSION$"; then
  echo "🐍 Installing Python $TARGET_PYTHON_VERSION with pyenv..."
  pyenv install "$TARGET_PYTHON_VERSION"
else
  echo "✅ Python $TARGET_PYTHON_VERSION already available in pyenv"
fi

pyenv global "$TARGET_PYTHON_VERSION"

# === STEP 4: Create virtual environment ===
# Usage: ./setup.sh [--clean]
RECREATE_ENV=false
if [[ "$1" == "--clean" ]]; then
  RECREATE_ENV=true
fi

if $RECREATE_ENV && [ -d "env" ]; then
  echo "🧹 Removing existing virtual environment..."
  rm -rf env
fi

if [ ! -d "env" ]; then
  echo "🧪 Creating new virtual environment..."
  python -m venv env
else
  echo "✅ Reusing existing virtual environment"
fi


# === STEP 5: Activate and install Python libraries ===
echo "📦 Activating environment and verifying packages..."
source env/bin/activate
pip install --upgrade pip


# === STEP 6: Install Python packages from requirements.txt with check ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQ_FILE="$SCRIPT_DIR/requirements.txt"

if [ ! -f "$REQ_FILE" ]; then
  echo "❌ requirements.txt not found at $REQ_FILE"
  exit 1
fi

echo "📄 Installing from requirements.txt with version checks..."

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" == \#* ]] && continue

  pkg=$(echo "$line" | cut -d= -f1)
  required_version=$(echo "$line" | cut -d= -f3)
  current_version=$(pip freeze | grep -i "^${pkg}==" | cut -d= -f3)

  if [[ "$current_version" == "$required_version" ]]; then
    echo "✅ $pkg==$required_version already installed"
  else
    if [ -z "$current_version" ]; then
      echo "📥 Installing $pkg==$required_version"
    else
      echo "🔁 Upgrading $pkg from $current_version to $required_version"
    fi
    pip install "$pkg==$required_version"
  fi
done < "$REQ_FILE"


# === STEP 7: Special install for LightGBM ===
echo "⚙️  Verifying LightGBM==4.3.0 (requires CMake >= 3.18)..."

LGBM_VERSION_REQUIRED="4.3.0"
LGBM_CURRENT=$(pip freeze | grep -i "^lightgbm==" | cut -d= -f3)

if [[ "$LGBM_CURRENT" == "$LGBM_VERSION_REQUIRED" ]]; then
  echo "✅ lightgbm==$LGBM_VERSION_REQUIRED already installed"
else
  if ! command -v cmake >/dev/null 2>&1; then
    echo "❌ CMake not found. Please install CMake >= 3.18"
    exit 1
  fi

  CMAKE_VERSION=$(cmake --version | head -n1 | awk '{print $3}')
  REQUIRED_CMAKE="3.18"
  version_check=$(printf "%s\n%s" "$REQUIRED_CMAKE" "$CMAKE_VERSION" | sort -V | head -n1)

  if [[ "$version_check" != "$REQUIRED_CMAKE" ]]; then
    echo "❌ CMake version $CMAKE_VERSION is too old. Upgrade to >= $REQUIRED_CMAKE"
    exit 1
  fi

  echo "📥 Installing LightGBM==$LGBM_VERSION_REQUIRED..."
  pip install scikit-build-core
  pip install lightgbm==$LGBM_VERSION_REQUIRED --no-build-isolation
fi

echo ""
echo "🎉 Environment setup complete!"
echo "👉 Activate with: source env/bin/activate"

