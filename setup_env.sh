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

# Load pyenv environment
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

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

# === STEP 6: Install Python packages ===
PACKAGES=(
  "pandas==2.2.2"
  "numpy==1.26.4"
  "scipy==1.13.1"
  "pyarrow==15.0.2"
  "openpyxl==3.1.2"
  "matplotlib==3.8.4"
  "seaborn==0.13.2"
  "plotly==5.21.0"
  "altair==5.3.0"
  "scikit-learn==1.4.2"
  "xgboost==2.0.3"
  "catboost==1.2.5"
  "statsmodels==0.14.1"
  "missingno==0.5.2"
  "tqdm==4.66.4"
  "pyjanitor==0.25.0"
)

for entry in "${PACKAGES[@]}"; do
  pkg=$(echo "$entry" | cut -d= -f1)
  required_version=$(echo "$entry" | cut -d= -f3)

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
done

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



pip install scikit-build-core
pip install lightgbm==4.3.0 --no-build-isolation

echo ""
echo "🎉 Environment setup complete!"
echo "👉 Activate with: source env/bin/activate"

