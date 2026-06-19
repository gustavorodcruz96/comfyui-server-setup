#!/usr/bin/env bash

set -e

COMFY_DIR="/workspace/ComfyUI"

echo "Atualizando ComfyUI..."
cd $COMFY_DIR
git pull || true

echo "Instalando dependências..."
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
opencv-python

echo "Criando diretórios..."
mkdir -p models/diffusion_models
mkdir -p models/text_encoders
mkdir -p models/vae
mkdir -p models/clip_vision

echo "Instalando custom nodes..."

cd custom_nodes

git clone https://github.com/kijai/ComfyUI-WanVideoWrapper || true
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite || true
git clone https://github.com/ShmuelRonen/ComfyUI-LatentSyncWrapper || true

echo "Instalando requirements..."

for d in */ ; do
    if [ -f "$d/requirements.txt" ]; then
        pip install -r "$d/requirements.txt" || true
    fi
done

echo "Baixando Wan 2.2..."

cd $COMFY_DIR

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
split_files/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors \
--local-dir models

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
--local-dir models

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
split_files/vae/wan2.2_vae.safetensors \
--local-dir models

echo "Baixando Hunyuan..."

hf download Comfy-Org/HunyuanVideo_repackaged \
split_files/text_encoders/clip_l.safetensors \
--local-dir models

hf download Comfy-Org/HunyuanVideo_repackaged \
split_files/text_encoders/llava_llama3_fp8_scaled.safetensors \
--local-dir models

hf download Comfy-Org/HunyuanVideo_repackaged \
split_files/vae/hunyuan_video_vae_bf16.safetensors \
--local-dir models

hf download Comfy-Org/HunyuanVideo_repackaged \
split_files/diffusion_models/hunyuan_video_t2v_720p_bf16.safetensors \
--local-dir models

echo "Organizando arquivos..."

mv -f models/split_files/text_encoders/* models/text_encoders/ 2>/dev/null || true
mv -f models/split_files/diffusion_models/* models/diffusion_models/ 2>/dev/null || true
mv -f models/split_files/vae/* models/vae/ 2>/dev/null || true

rm -rf models/split_files

echo "Setup concluído."
