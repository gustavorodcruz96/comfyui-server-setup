#!/usr/bin/env bash
set -e

COMFY_DIR="/workspace/ComfyUI"
export HF_HUB_ENABLE_HF_TRANSFER=1

echo "=================================================="
echo " ComfyUI Video AI Setup — Vast.ai"
echo "=================================================="

if [ ! -d "$COMFY_DIR" ]; then
  echo "Erro: ComfyUI não encontrado em $COMFY_DIR"
  echo "Use um template Vast.ai com ComfyUI + Jupyter."
  exit 1
fi

cd "$COMFY_DIR"

echo "==> Atualizando ComfyUI..."
git pull || true

echo "==> Instalando dependências base..."
python -m pip install -U pip
python -m pip install -U \
  huggingface_hub \
  hf_transfer \
  accelerate \
  transformers \
  diffusers \
  sentencepiece \
  protobuf \
  imageio-ffmpeg \
  opencv-python \
  einops \
  safetensors

echo "==> Criando pastas de modelos..."
mkdir -p models/diffusion_models
mkdir -p models/text_encoders
mkdir -p models/vae
mkdir -p models/clip_vision
mkdir -p models/loras
mkdir -p models/checkpoints

echo "==> Instalando custom nodes..."
cd "$COMFY_DIR/custom_nodes"

git clone https://github.com/kijai/ComfyUI-WanVideoWrapper || true
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite || true
git clone https://github.com/ShmuelRonen/ComfyUI-LatentSyncWrapper || true

echo "==> Instalando requirements dos custom nodes..."
for d in */ ; do
  if [ -f "$d/requirements.txt" ]; then
    echo "Instalando requirements de $d"
    python -m pip install -r "$d/requirements.txt" || true
  fi
done

cd "$COMFY_DIR"

echo "=================================================="
echo " Baixando Hunyuan Video 1.5 I2V"
echo "=================================================="

hf download Comfy-Org/HunyuanVideo_1.5_ComfyUI_Repackaged \
  split_files/clip_vision/sigclip_vision_patch14_384.safetensors \
  --local-dir models || true

hf download Comfy-Org/HunyuanVideo_1.5_ComfyUI_Repackaged \
  split_files/diffusion_models/hunyuanvideo1.5_720p_i2v_fp16.safetensors \
  --local-dir models || true

hf download Comfy-Org/HunyuanVideo_1.5_ComfyUI_Repackaged \
  split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors \
  --local-dir models || true

hf download Comfy-Org/HunyuanVideo_1.5_ComfyUI_Repackaged \
  split_files/text_encoders/byt5_small_glyphxl_fp16.safetensors \
  --local-dir models || true

hf download Comfy-Org/HunyuanVideo_1.5_ComfyUI_Repackaged \
  split_files/vae/hunyuanvideo15_vae_fp16.safetensors \
  --local-dir models || true

echo "==> Organizando Hunyuan Video 1.5..."
mv -f models/split_files/clip_vision/* models/clip_vision/ 2>/dev/null || true
mv -f models/split_files/diffusion_models/* models/diffusion_models/ 2>/dev/null || true
mv -f models/split_files/text_encoders/* models/text_encoders/ 2>/dev/null || true
mv -f models/split_files/vae/* models/vae/ 2>/dev/null || true
rm -rf models/split_files

echo "=================================================="
echo " Baixando Hunyuan Video base"
echo "=================================================="

hf download Comfy-Org/HunyuanVideo_repackaged \
  split_files/text_encoders/clip_l.safetensors \
  --local-dir models || true

hf download Comfy-Org/HunyuanVideo_repackaged \
  split_files/text_encoders/llava_llama3_fp8_scaled.safetensors \
  --local-dir models || true

hf download Comfy-Org/HunyuanVideo_repackaged \
  split_files/vae/hunyuan_video_vae_bf16.safetensors \
  --local-dir models || true

hf download Comfy-Org/HunyuanVideo_repackaged \
  split_files/diffusion_models/hunyuan_video_t2v_720p_bf16.safetensors \
  --local-dir models || true

hf download Comfy-Org/HunyuanVideo_repackaged \
  split_files/diffusion_models/hunyuan_video_image_to_video_720p_bf16.safetensors \
  --local-dir models || true

echo "==> Organizando Hunyuan Video base..."
mv -f models/split_files/clip_vision/* models/clip_vision/ 2>/dev/null || true
mv -f models/split_files/diffusion_models/* models/diffusion_models/ 2>/dev/null || true
mv -f models/split_files/text_encoders/* models/text_encoders/ 2>/dev/null || true
mv -f models/split_files/vae/* models/vae/ 2>/dev/null || true
rm -rf models/split_files

echo "=================================================="
echo " Baixando Wan 2.2 5B"
echo "=================================================="

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors \
  --local-dir models || true

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
  --local-dir models || true

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
  split_files/vae/wan2.2_vae.safetensors \
  --local-dir models || true

echo "==> Organizando Wan 2.2..."
mv -f models/split_files/diffusion_models/* models/diffusion_models/ 2>/dev/null || true
mv -f models/split_files/text_encoders/* models/text_encoders/ 2>/dev/null || true
mv -f models/split_files/vae/* models/vae/ 2>/dev/null || true
rm -rf models/split_files

echo "=================================================="
echo " Verificação final"
echo "=================================================="

echo "--- diffusion_models ---"
ls -lh models/diffusion_models || true

echo "--- text_encoders ---"
ls -lh models/text_encoders || true

echo "--- vae ---"
ls -lh models/vae || true

echo "--- clip_vision ---"
ls -lh models/clip_vision || true

echo "=================================================="
echo " Setup concluído."
echo " Reinicie o ComfyUI pela Vast.ai:"
echo " Stop Instance -> Start Instance"
echo "=================================================="
