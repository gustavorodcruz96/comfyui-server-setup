#!/usr/bin/env bash
set -Eeuo pipefail

COMFY_DIR="/workspace/ComfyUI"
WORKSPACE="/workspace"

LATENTSYNC_WRAPPER_DIR="$COMFY_DIR/custom_nodes/ComfyUI-LatentSyncWrapper"
VHS_DIR="$COMFY_DIR/custom_nodes/ComfyUI-VideoHelperSuite"

MUSETALK_DIR="$WORKSPACE/MuseTalk"
HUNYUAN_AVATAR_DIR="$WORKSPACE/HunyuanVideo-Avatar"

export HF_XET_HIGH_PERFORMANCE=1

log() {
  echo ""
  echo "=================================================="
  echo "$1"
  echo "=================================================="
}

clone_or_pull() {
  local repo_url="$1"
  local target_dir="$2"

  if [ -d "$target_dir/.git" ]; then
    echo "Atualizando: $target_dir"
    git -C "$target_dir" pull || true
  else
    echo "Clonando: $repo_url"
    git clone "$repo_url" "$target_dir"
  fi
}

hf_download() {
  local repo="$1"
  local local_dir="$2"
  shift 2

  mkdir -p "$local_dir"

  echo "Baixando de Hugging Face:"
  echo "Repo: $repo"
  echo "Destino: $local_dir"
  echo "Arquivos: $*"

  hf download "$repo" "$@" --local-dir "$local_dir"
}

log "ComfyUI Lip Sync Setup — Free/Open Models"

if [ ! -d "$COMFY_DIR" ]; then
  echo "ERRO: ComfyUI não encontrado em $COMFY_DIR"
  echo "Use um template Vast.ai com ComfyUI + Jupyter."
  exit 1
fi

log "Instalando pacotes do sistema"

if command -v apt-get >/dev/null 2>&1; then
  apt-get update || true
  apt-get install -y git curl wget ffmpeg unzip || true
fi

log "Atualizando pip e dependências base"

python -m pip install -U pip

python -m pip install -U \
  "huggingface_hub[cli]" \
  hf_transfer \
  gdown \
  accelerate \
  transformers \
  diffusers \
  sentencepiece \
  protobuf \
  imageio-ffmpeg \
  opencv-python \
  einops \
  safetensors \
  soundfile \
  ffmpeg-python \
  decord \
  omegaconf \
  pytorch-lightning

log "Atualizando ComfyUI"

cd "$COMFY_DIR"
git pull || true

log "Criando pastas principais"

mkdir -p "$WORKSPACE/input"
mkdir -p "$WORKSPACE/output"

mkdir -p "$COMFY_DIR/models/checkpoints"
mkdir -p "$COMFY_DIR/models/diffusion_models"
mkdir -p "$COMFY_DIR/models/text_encoders"
mkdir -p "$COMFY_DIR/models/vae"
mkdir -p "$COMFY_DIR/models/clip_vision"
mkdir -p "$COMFY_DIR/models/loras"

log "Instalando custom nodes do ComfyUI"

mkdir -p "$COMFY_DIR/custom_nodes"

clone_or_pull \
  "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git" \
  "$VHS_DIR"

clone_or_pull \
  "https://github.com/ShmuelRonen/ComfyUI-LatentSyncWrapper.git" \
  "$LATENTSYNC_WRAPPER_DIR"

log "Instalando requirements dos custom nodes"

for node_dir in "$VHS_DIR" "$LATENTSYNC_WRAPPER_DIR"; do
  if [ -f "$node_dir/requirements.txt" ]; then
    echo "Instalando requirements de: $node_dir"
    python -m pip install -r "$node_dir/requirements.txt" || true
  fi
done

log "Baixando LatentSync público para ComfyUI"

mkdir -p "$LATENTSYNC_WRAPPER_DIR/checkpoints"
mkdir -p "$LATENTSYNC_WRAPPER_DIR/checkpoints/whisper"
mkdir -p "$LATENTSYNC_WRAPPER_DIR/checkpoints/vae"

# LatentSync público.
# Evita depender do repo privado ByteDance/LatentSync-1.6.
hf_download \
  "ByteDance/LatentSync" \
  "$LATENTSYNC_WRAPPER_DIR/checkpoints" \
  "latentsync_unet.pt" \
  "whisper/tiny.pt" || true

# VAE usado pelo LatentSync.
hf_download \
  "stabilityai/sd-vae-ft-mse" \
  "$LATENTSYNC_WRAPPER_DIR/checkpoints/vae" \
  "config.json" \
  "diffusion_pytorch_model.safetensors" || true

# Forçar config 1.5 pública, caso o wrapper tenha config 512 da versão 1.6.
# Isso evita tentar rodar checkpoint público 1.5 com config 1.6.
if [ "${USE_LATENTSYNC_16:-0}" != "1" ]; then
  if [ -f "$LATENTSYNC_WRAPPER_DIR/configs/unet/stage2_512.yaml" ] && [ -f "$LATENTSYNC_WRAPPER_DIR/configs/unet/stage2.yaml" ]; then
    mv -f \
      "$LATENTSYNC_WRAPPER_DIR/configs/unet/stage2_512.yaml" \
      "$LATENTSYNC_WRAPPER_DIR/configs/unet/stage2_512.yaml.disabled_for_public_1_5" || true
  fi
fi

log "Instalando MuseTalk"

cd "$WORKSPACE"

clone_or_pull \
  "https://github.com/TMElyralab/MuseTalk.git" \
  "$MUSETALK_DIR"

mkdir -p "$MUSETALK_DIR/models/musetalk"
mkdir -p "$MUSETALK_DIR/models/musetalkV15"
mkdir -p "$MUSETALK_DIR/models/syncnet"
mkdir -p "$MUSETALK_DIR/models/dwpose"
mkdir -p "$MUSETALK_DIR/models/face-parse-bisent"
mkdir -p "$MUSETALK_DIR/models/sd-vae"
mkdir -p "$MUSETALK_DIR/models/whisper"

log "Baixando pesos MuseTalk V1.5"

hf_download \
  "TMElyralab/MuseTalk" \
  "$MUSETALK_DIR/models" \
  "musetalkV15/musetalk.json" \
  "musetalkV15/unet.pth" || true

log "Baixando pesos MuseTalk V1 fallback"

hf_download \
  "TMElyralab/MuseTalk" \
  "$MUSETALK_DIR/models" \
  "musetalk/musetalk.json" \
  "musetalk/pytorch_model.bin" || true

log "Baixando SyncNet para MuseTalk"

hf_download \
  "ByteDance/LatentSync" \
  "$MUSETALK_DIR/models/syncnet" \
  "latentsync_syncnet.pt" || true

log "Baixando DWPose"

hf_download \
  "yzd-v/DWPose" \
  "$MUSETALK_DIR/models/dwpose" \
  "dw-ll_ucoco_384.pth" || true

log "Baixando SD VAE para MuseTalk"

hf_download \
  "stabilityai/sd-vae-ft-mse" \
  "$MUSETALK_DIR/models/sd-vae" \
  "config.json" \
  "diffusion_pytorch_model.bin" || true

log "Baixando Whisper Tiny para MuseTalk"

hf_download \
  "openai/whisper-tiny" \
  "$MUSETALK_DIR/models/whisper" \
  "config.json" \
  "pytorch_model.bin" \
  "preprocessor_config.json" || true

log "Baixando face-parse-bisent"

if [ ! -f "$MUSETALK_DIR/models/face-parse-bisent/79999_iter.pth" ]; then
  gdown --id 154JgKpzCPW82qINcVieuPH3fZ2e0P812 \
    -O "$MUSETALK_DIR/models/face-parse-bisent/79999_iter.pth" || true
fi

if [ ! -f "$MUSETALK_DIR/models/face-parse-bisent/resnet18-5c106cde.pth" ]; then
  curl -L \
    "https://download.pytorch.org/models/resnet18-5c106cde.pth" \
    -o "$MUSETALK_DIR/models/face-parse-bisent/resnet18-5c106cde.pth" || true
fi

log "Runtime MuseTalk opcional"

if [ "${INSTALL_MUSETALK_RUNTIME:-0}" = "1" ]; then
  echo "Instalando runtime MuseTalk no ambiente atual."
  echo "Atenção: pode demorar e pode exigir compatibilidade específica de Python/CUDA."

  cd "$MUSETALK_DIR"

  python -m pip install -r requirements.txt || true
  python -m pip install -U openmim || true

  if command -v mim >/dev/null 2>&1; then
    mim install mmengine || true
    mim install "mmcv==2.0.1" || true
    mim install "mmdet==3.1.0" || true
    mim install "mmpose==1.1.0" || true
  fi
else
  echo "Pulando runtime MuseTalk."
  echo "Para instalar depois:"
  echo "INSTALL_MUSETALK_RUNTIME=1 bash setup.sh"
fi

log "HunyuanVideo-Avatar opcional"

if [ "${INSTALL_HUNYUAN_AVATAR:-0}" = "1" ]; then
  echo "Instalando HunyuanVideo-Avatar."
  echo "Atenção: download grande. Use 200GB+ de disco."

  cd "$WORKSPACE"

  clone_or_pull \
    "https://github.com/Tencent-Hunyuan/HunyuanVideo-Avatar.git" \
    "$HUNYUAN_AVATAR_DIR"

  mkdir -p "$HUNYUAN_AVATAR_DIR/weights"

  hf download \
    "tencent/HunyuanVideo-Avatar" \
    --local-dir "$HUNYUAN_AVATAR_DIR/weights" || true
else
  echo "Pulando HunyuanVideo-Avatar."
  echo "Para instalar depois:"
  echo "INSTALL_HUNYUAN_AVATAR=1 bash setup.sh"
fi

log "Criando helper foto -> vídeo 25 FPS"

cat > "$WORKSPACE/photo_to_video_25fps.sh" <<'EOF'
#!/usr/bin/env bash
set -e

IMG="${1:-}"
DUR="${2:-8}"
OUT="${3:-/workspace/input/avatar_base.mp4}"

if [ -z "$IMG" ]; then
  echo "Uso:"
  echo "/workspace/photo_to_video_25fps.sh /workspace/input/foto.png 8 /workspace/input/avatar_base.mp4"
  exit 1
fi

if [ ! -f "$IMG" ]; then
  echo "Arquivo não encontrado: $IMG"
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

ffmpeg -y \
  -loop 1 \
  -i "$IMG" \
  -t "$DUR" \
  -vf "fps=25,scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p" \
  -c:v libx264 \
  -pix_fmt yuv420p \
  "$OUT"

echo "Vídeo criado em: $OUT"
EOF

chmod +x "$WORKSPACE/photo_to_video_25fps.sh"

log "Criando helper MuseTalk foto/vídeo + áudio"

cat > "$WORKSPACE/run_musetalk_photo_audio.sh" <<'EOF'
#!/usr/bin/env bash
set -e

INPUT_MEDIA="${1:-}"
AUDIO="${2:-}"
OUT="${3:-/workspace/output/avatar_musetalk.mp4}"
DURATION="${DURATION:-8}"
BATCH_SIZE="${BATCH_SIZE:-8}"

MUSETALK_DIR="/workspace/MuseTalk"
TMP_DIR="/workspace/output/musetalk_tmp"
CONFIG_PATH="$TMP_DIR/inference_auto.yaml"

if [ -z "$INPUT_MEDIA" ] || [ -z "$AUDIO" ]; then
  echo "Uso:"
  echo "/workspace/run_musetalk_photo_audio.sh /workspace/input/foto.png /workspace/input/audio.wav /workspace/output/avatar_musetalk.mp4"
  echo ""
  echo "Opcional:"
  echo "DURATION=10 BATCH_SIZE=4 /workspace/run_musetalk_photo_audio.sh foto.png audio.wav out.mp4"
  exit 1
fi

if [ ! -f "$INPUT_MEDIA" ]; then
  echo "Arquivo de imagem/vídeo não encontrado: $INPUT_MEDIA"
  exit 1
fi

if [ ! -f "$AUDIO" ]; then
  echo "Arquivo de áudio não encontrado: $AUDIO"
  exit 1
fi

mkdir -p "$TMP_DIR"
mkdir -p "$(dirname "$OUT")"

EXT="${INPUT_MEDIA##*.}"
EXT_LOWER="$(echo "$EXT" | tr '[:upper:]' '[:lower:]')"

BASE_VIDEO="$INPUT_MEDIA"

if [ "$EXT_LOWER" = "png" ] || [ "$EXT_LOWER" = "jpg" ] || [ "$EXT_LOWER" = "jpeg" ] || [ "$EXT_LOWER" = "webp" ]; then
  BASE_VIDEO="$TMP_DIR/photo_base_25fps.mp4"

  ffmpeg -y \
    -loop 1 \
    -i "$INPUT_MEDIA" \
    -t "$DURATION" \
    -vf "fps=25,scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p" \
    -c:v libx264 \
    -pix_fmt yuv420p \
    "$BASE_VIDEO"
fi

RESULT_NAME="$(basename "$OUT")"

cat > "$CONFIG_PATH" <<YAML
task_0:
  video_path: "$BASE_VIDEO"
  audio_path: "$AUDIO"
  result_name: "$RESULT_NAME"
YAML

cd "$MUSETALK_DIR"

python -m scripts.inference \
  --inference_config "$CONFIG_PATH" \
  --result_dir "$TMP_DIR/results" \
  --unet_model_path "$MUSETALK_DIR/models/musetalkV15/unet.pth" \
  --unet_config "$MUSETALK_DIR/models/musetalkV15/musetalk.json" \
  --whisper_dir "$MUSETALK_DIR/models/whisper" \
  --version v15 \
  --ffmpeg_path /usr/bin \
  --fps 25 \
  --batch_size "$BATCH_SIZE" \
  --use_float16

FOUND="$(find "$TMP_DIR/results" -type f -name "$RESULT_NAME" | head -n 1 || true)"

if [ -z "$FOUND" ]; then
  echo "Não encontrei o resultado final."
  echo "Veja a pasta: $TMP_DIR/results"
  exit 1
fi

cp -f "$FOUND" "$OUT"

echo "Vídeo MuseTalk criado em: $OUT"
EOF

chmod +x "$WORKSPACE/run_musetalk_photo_audio.sh"

log "Criando verificador de modelos"

cat > "$WORKSPACE/check_lipsync_models.sh" <<'EOF'
#!/usr/bin/env bash

echo ""
echo "=== LatentSync Wrapper ==="
find /workspace/ComfyUI/custom_nodes/ComfyUI-LatentSyncWrapper/checkpoints -maxdepth 4 -type f 2>/dev/null | sort || true

echo ""
echo "=== MuseTalk Models ==="
find /workspace/MuseTalk/models -maxdepth 4 -type f 2>/dev/null | sort || true

echo ""
echo "=== HunyuanVideo-Avatar opcional ==="
if [ -d /workspace/HunyuanVideo-Avatar/weights ]; then
  find /workspace/HunyuanVideo-Avatar/weights -maxdepth 4 -type f 2>/dev/null | head -100 | sort || true
else
  echo "Não instalado."
fi
EOF

chmod +x "$WORKSPACE/check_lipsync_models.sh"

log "Verificação final"

echo ""
echo "--- LatentSync checkpoints ---"
find "$LATENTSYNC_WRAPPER_DIR/checkpoints" -maxdepth 4 -type f 2>/dev/null | sort | head -80 || true

echo ""
echo "--- MuseTalk models ---"
find "$MUSETALK_DIR/models" -maxdepth 4 -type f 2>/dev/null | sort | head -120 || true

echo ""
echo "--- Helpers criados ---"
ls -lh \
  "$WORKSPACE/photo_to_video_25fps.sh" \
  "$WORKSPACE/run_musetalk_photo_audio.sh" \
  "$WORKSPACE/check_lipsync_models.sh" || true

log "Setup concluído"

echo "Próximos passos:"
echo ""
echo "1. Reinicie o ComfyUI pela Vast:"
echo "   Stop Instance -> Start Instance"
echo ""
echo "2. Para transformar foto em vídeo-base:"
echo "   /workspace/photo_to_video_25fps.sh /workspace/input/foto.png 8 /workspace/input/avatar_base.mp4"
echo ""
echo "3. No ComfyUI:"
echo "   Load Video -> avatar_base.mp4"
echo "   Load Audio -> audio.wav"
echo "   LatentSync -> Save Video"
echo ""
echo "4. Para testar MuseTalk direto no terminal:"
echo "   INSTALL_MUSETALK_RUNTIME=1 bash setup.sh"
echo "   /workspace/run_musetalk_photo_audio.sh /workspace/input/foto.png /workspace/input/audio.wav /workspace/output/avatar_musetalk.mp4"
echo ""
echo "5. Para verificar modelos:"
echo "   /workspace/check_lipsync_models.sh"
echo ""
