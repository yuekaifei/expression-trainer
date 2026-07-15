#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
OS_NAME="$(uname -s)"
MODEL_URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-paraformer-bilingual-zh-en.tar.bz2"
MODEL_ARCHIVE="sherpa-onnx-streaming-paraformer-bilingual-zh-en.tar.bz2"

download_file() {
  local url="$1"
  local output="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -L --progress-bar -o "$output" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$output" "$url"
  else
    echo "错误: 需要 curl 或 wget 来下载模型文件"
    echo "macOS 可使用: xcode-select --install"
    exit 1
  fi
}

echo "==> 宇宙无敌表达训练系统 - 本地启动"
echo

# 1. 检查 Node.js
if ! command -v node >/dev/null 2>&1; then
  echo "错误: 未找到 Node.js，请先安装 Node.js 18+"
  exit 1
fi
echo "Node.js: $(node -v)"

# 2. 安装依赖
if [ ! -d node_modules ]; then
  echo "==> 安装依赖..."
  npm install
else
  echo "依赖已安装"
fi

# 3. 检查语音识别模型
MODEL_DIR="models/sherpa-onnx-streaming-paraformer-bilingual-zh-en"
if [ ! -f "$MODEL_DIR/encoder.int8.onnx" ] || [ ! -f "$MODEL_DIR/decoder.int8.onnx" ] || [ ! -f "$MODEL_DIR/tokens.txt" ]; then
  echo "==> 下载语音识别模型（约 1GB，首次需要几分钟）..."
  mkdir -p models
  cd models
  if [ ! -f "$MODEL_ARCHIVE" ]; then
    download_file "$MODEL_URL" "$MODEL_ARCHIVE"
  fi
  tar xvf "$MODEL_ARCHIVE"
  cd "$ROOT"
fi
echo "语音识别模型: 就绪"

# 4. 检查 API 配置（可选，也可在应用内设置页配置）
SETTINGS_DIR="$(node -e "
const os = require('os');
const path = require('path');
const home = os.homedir();
const platform = process.platform;
let dir;
if (platform === 'darwin') {
  dir = path.join(home, 'Library', 'Application Support', 'expression-trainer');
} else if (platform === 'win32') {
  dir = path.join(process.env.APPDATA || path.join(home, 'AppData', 'Roaming'), 'expression-trainer');
} else {
  dir = path.join(home, '.config', 'expression-trainer');
}
console.log(dir);
")"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
  echo
  echo "提示: 首次使用请在应用内点击右上角 ⚙️ 配置 DeepSeek API Key"
  echo "      配置文件将保存到: $SETTINGS_FILE"
fi

# 5. 启动应用
echo
echo "==> 启动应用..."
if [ "$OS_NAME" != "Darwin" ] && [ -z "${DISPLAY:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
  echo "未检测到图形界面，使用 xvfb-run 启动..."
  exec xvfb-run -a npm start
else
  exec npm start
fi
