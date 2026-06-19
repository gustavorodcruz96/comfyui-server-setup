# ComfyUI Video AI Setup — Vast.ai RTX 5090

Setup para criar um servidor ComfyUI na Vast.ai com modelos de vídeo e avatar.

## Template recomendado na Vast.ai

Use sempre um template ComfyUI com Jupyter, de preferência:

```text
vastai/comfy_v0.22.0-cuda-12.9-py312/jupyter
```

ou a versão ComfyUI mais nova equivalente.

---

# 1. Abrir terminal do Jupyter

Depois que o servidor iniciar:

1. Clique em **Open**
2. Abra o **Jupyter**
3. Abra o **Terminal**
4. Execute os comandos abaixo

---

# 2. Atualizar ComfyUI e dependências

```bash
cd /workspace/ComfyUI

git pull

python -m pip install -U pip
python -m pip install -U huggingface_hub hf_transfer accelerate transformers diffusers sentencepiece protobuf imageio-ffmpeg opencv-python
```

---

# 3. Criar pastas de modelos

```bash
cd /workspace/ComfyUI

mkdir -p models/diffusion_models
mkdir -p models/text_encoders
mkdir -p models/vae
mkdir -p models/clip_vision
mkdir -p models/loras
mkdir -p models/checkpoints
```

---

# 4. Instalar custom nodes principais

```bash
cd /workspace/ComfyUI/custom_nodes

git clone https://github.com/kijai/ComfyUI-WanVideoWrapper || true
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite || true
git clone https://github.com/ShmuelRonen/ComfyUI-LatentSyncWrapper || true
```

Instalar dependências:

```bash
cd /workspace/ComfyUI/custom_nodes

for d in */ ; do
  if [ -f "$d/requirements.txt" ]; then
    python -m pip install -r "$d/requirements.txt"
  fi
done
```

---

# 5. Baixar Wan 2.2 5B

Modelo recomendado para começar com:

* Texto → Vídeo
* Imagem → Vídeo
* B-roll para VSL

```bash
cd /workspace/ComfyUI

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
split_files/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors \
--local-dir models

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
--local-dir models

hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
split_files/vae/wan2.2_vae.safetensors \
--local-dir models
```

Organizar arquivos:

```bash
cd /workspace/ComfyUI

mv -f models/split_files/diffusion_models/* models/diffusion_models/ 2>/dev/null || true
mv -f models/split_files/text_encoders/* models/text_encoders/ 2>/dev/null || true
mv -f models/split_files/vae/* models/vae/ 2>/dev/null || true

rm -rf models/split_files
```

---

# 6. Baixar Hunyuan Video

Modelo para vídeo com melhor qualidade e base para workflows mais avançados.

```bash
cd /workspace/ComfyUI

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
```

Opcional para imagem → vídeo:

```bash
cd /workspace/ComfyUI

hf download Comfy-Org/HunyuanVideo_repackaged \
split_files/diffusion_models/hunyuan_video_image_to_video_720p_bf16.safetensors \
--local-dir models
```

Organizar arquivos:

```bash
cd /workspace/ComfyUI

mv -f models/split_files/text_encoders/* models/text_encoders/ 2>/dev/null || true
mv -f models/split_files/diffusion_models/* models/diffusion_models/ 2>/dev/null || true
mv -f models/split_files/vae/* models/vae/ 2>/dev/null || true
mv -f models/split_files/clip_vision/* models/clip_vision/ 2>/dev/null || true

rm -rf models/split_files
```

---

# 7. Verificar se os arquivos estão no lugar certo

```bash
cd /workspace/ComfyUI

ls models/diffusion_models
ls models/text_encoders
ls models/vae
```

Arquivos esperados:

```text
models/diffusion_models/
├── wan2.2_ti2v_5B_fp16.safetensors
├── hunyuan_video_t2v_720p_bf16.safetensors
└── hunyuan_video_image_to_video_720p_bf16.safetensors

models/text_encoders/
├── umt5_xxl_fp8_e4m3fn_scaled.safetensors
├── clip_l.safetensors
└── llava_llama3_fp8_scaled.safetensors

models/vae/
├── wan2.2_vae.safetensors
└── hunyuan_video_vae_bf16.safetensors
```

---

# 8. Reiniciar ComfyUI

```bash
pkill -f main.py
```

Depois, na Vast.ai:

```text
Stop Instance → Start Instance
```

ou apenas reinicie o app se o template permitir.

---

# 9. Como usar Wan 2.2 no ComfyUI

1. Abra o ComfyUI
2. Clique em **Templates**
3. Pesquise por:

```text
wan 2.2
```

4. Escolha:

```text
Wan 2.2 5B Video Generation
```

5. Para texto → vídeo, deixe o node de imagem desativado.
6. Preencha o prompt positivo.
7. Use configurações iniciais:

```text
Resolution: 832x480
Frames: 81
FPS: 16
Steps: 20
CFG: 5 a 7
```

8. Clique em **Run**

---

# 10. Prompt inicial de teste

```text
A cinematic realistic shot of a golden retriever sitting in a modern living room, soft sunlight coming through the window, natural camera movement, shallow depth of field, realistic fur, warm atmosphere, premium commercial video style.
```

Negative prompt:

```text
low quality, blurry, distorted, extra limbs, bad anatomy, text, watermark, logo, cartoon, unrealistic movement
```

---

# 11. Como usar Hunyuan Video

1. Abra o ComfyUI
2. Clique em **Templates**
3. Pesquise:

```text
hunyuan
```

4. Escolha um workflow de:

```text
Hunyuan Text to Video
```

ou

```text
Hunyuan Image to Video
```

5. Selecione os modelos:

```text
Diffusion Model:
hunyuan_video_t2v_720p_bf16.safetensors

Text Encoders:
clip_l.safetensors
llava_llama3_fp8_scaled.safetensors

VAE:
hunyuan_video_vae_bf16.safetensors
```

---

# 12. Avatar falando / Lip Sync

Para avatar falando com foto + áudio, a ordem ideal é:

```text
Foto do avatar
↓
Gerar vídeo base com movimento facial/corporal
↓
Aplicar lip sync com áudio
↓
Exportar vídeo final
```

Modelos possíveis:

```text
HunyuanVideo-Avatar
LatentSync
InfiniteTalk
```

Recomendação:

* Para começar: usar LatentSync no ComfyUI
* Para qualidade mais avançada: testar HunyuanVideo-Avatar separadamente
* Para VSL/avatar realista: manter vídeos curtos, entre 5 e 10 segundos por geração

---

# 13. Configuração recomendada para RTX 5090 32GB

Para testes rápidos:

```text
832x480
81 frames
16 FPS
20 steps
```

Para qualidade maior:

```text
1280x704
121 frames
24 FPS
20 a 30 steps
```

Se der erro de VRAM:

* reduzir resolução
* reduzir frames
* usar batch size 1
* fechar outros workflows
* clicar em unload models no ComfyUI

---

# 14. Comando rápido para novo servidor

Depois que este repositório existir no GitHub:

```bash
cd /workspace

git clone https://github.com/gustavorodcruz96/comfyui-server-setup.git

cd comfyui-server-setup
```

Depois seguir o README ou executar o setup.sh, se existir.

---

# 15. Observações importantes

* O template da Vast.ai não salva tudo se você destruir a instância.
* Sem volume persistente, os modelos baixados são perdidos.
* Para não perder tempo, salve este setup no GitHub.
* Sempre que criar um servidor novo, use o template ComfyUI + rode os comandos deste README.
* Modelos grandes podem demorar de 20 a 60 minutos para baixar.
