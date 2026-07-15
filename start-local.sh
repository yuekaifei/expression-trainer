#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

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
  if [ ! -f sherpa-onnx-streaming-paraformer-bilingual-zh-en.tar.bz2 ]; then
    wget https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-paraformer-bilingual-zh-en.tar.bz2
  fi
  tar xvf sherpa-onnx-streaming-paraformer-bilingual-zh-en.tar.bz2
  cd "$ROOT"
fi
echo "语音识别模型: 就绪"

# 4. 检查 API 配置（可选，也可在应用内设置页配置）
SETTINGS_DIR="$(node -e "const os=require('os'),path=require('path');console.log(path.join(os.homedir(),'.config','expression-trainer'))")"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
  echo
  echo "提示: 首次使用请在应用内点击右上角 ⚙️ 配置 DeepSeek API Key"
  echo "      配置文件将保存到: $SETTINGS_FILE"
fi

# 5. 启动应用
echo
echo "==> 启动应用..."
if [ -z "${DISPLAY:-}" ]; then
  echo "未检测到图形界面，使用 xvfb-run 启动..."
  exec xvfb-run -a npm start
else
  exec npm start
fi
