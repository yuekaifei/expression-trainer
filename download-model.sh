#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

MODEL_DIR="models/sherpa-onnx-streaming-paraformer-bilingual-zh-en"
MODEL_ARCHIVE="sherpa-onnx-streaming-paraformer-bilingual-zh-en.tar.bz2"
MODEL_URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-paraformer-bilingual-zh-en.tar.bz2"
REQUIRED_FILES=("encoder.int8.onnx" "decoder.int8.onnx" "tokens.txt")

download_file() {
  local url="$1"
  local output="$2"

  echo "下载地址: $url"
  echo "保存位置: $output"
  echo

  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --retry 3 --retry-delay 2 --progress-bar -o "$output" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget --tries=3 --timeout=30 -O "$output" "$url"
  else
    echo "错误: 需要 curl 或 wget 来下载模型"
    echo "macOS 通常自带 curl；若缺失可执行: xcode-select --install"
    exit 1
  fi
}

verify_model_files() {
  local missing=0
  for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$MODEL_DIR/$file" ]; then
      echo "缺少模型文件: $MODEL_DIR/$file"
      missing=1
    fi
  done
  return "$missing"
}

echo "==> 语音识别模型管理"
echo "项目目录: $ROOT"
echo

if verify_model_files; then
  echo "模型已存在，跳过下载。"
  ls -lh "$MODEL_DIR"/encoder.int8.onnx "$MODEL_DIR"/decoder.int8.onnx "$MODEL_DIR"/tokens.txt
  exit 0
fi

echo "模型未就绪，开始下载（约 1GB，首次需要几分钟）..."
mkdir -p models
cd models

if [ -f "$MODEL_ARCHIVE" ]; then
  archive_size="$(wc -c < "$MODEL_ARCHIVE" | tr -d ' ')"
  if [ "$archive_size" -lt 100000000 ]; then
    echo "检测到不完整的压缩包（${archive_size} 字节），重新下载..."
    rm -f "$MODEL_ARCHIVE"
  else
    echo "发现已有压缩包，直接解压..."
  fi
fi

if [ ! -f "$MODEL_ARCHIVE" ]; then
  download_file "$MODEL_URL" "$MODEL_ARCHIVE"
fi

archive_size="$(wc -c < "$MODEL_ARCHIVE" | tr -d ' ')"
echo
echo "压缩包大小: $archive_size 字节"
if [ "$archive_size" -lt 100000000 ]; then
  echo "错误: 下载不完整，请检查网络后重试"
  rm -f "$MODEL_ARCHIVE"
  exit 1
fi

echo "==> 解压模型..."
tar xvf "$MODEL_ARCHIVE"
cd "$ROOT"

if ! verify_model_files; then
  echo "错误: 模型解压后仍不完整，请删除 models/ 后重试"
  exit 1
fi

echo
echo "模型下载完成："
ls -lh "$MODEL_DIR"/encoder.int8.onnx "$MODEL_DIR"/decoder.int8.onnx "$MODEL_DIR"/tokens.txt
