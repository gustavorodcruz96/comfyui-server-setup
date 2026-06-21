# ComfyUI Video AI Setup — Vast.ai

Setup para configurar um servidor ComfyUI na Vast.ai com foco em geração de vídeo realista, image-to-video, b-roll para VSL, talking avatar e lip sync.

---

## Objetivo

Este repositório instala e organiza os principais modelos para workflows de vídeo no ComfyUI:

* Hunyuan Video 1.5 Image-to-Video
* Hunyuan Video base
* Wan 2.2 5B
* LatentSync
* VideoHelperSuite

---

## GPU recomendada

Para qualidade mais próxima de Veo:

1. H100 80GB — melhor opção
2. RTX 6000 Ada 48GB — melhor custo/benefício
3. RTX 5090 32GB — funciona, mas com mais limites
4. RTX 4090 24GB — apenas testes menores

---

## Template recomendado na Vast.ai

Use um template ComfyUI com Jupyter.

Exemplo:

```text
vastai/comfy_v0.22.0-cuda-12.9-py312/jupyter
```

ou a versão ComfyUI mais nova equivalente.

---

## Instalação rápida em novo servidor

No terminal do Jupyter:

```bash
cd /workspace

git clone https://github.com/gustavorodcruz96/comfyui-server-setup.git

cd comfyui-server-setup

bash setup.sh
```

Depois reinicie o ComfyUI pela Vast.ai:

```text
Stop Instance → Start Instance
```

ou use o botão de restart/reload se o template permitir.

---

## Ordem de prioridade dos modelos

Para VSL, BionPet, vídeos realistas, imagem animada e avatar:

1. Hunyuan Video 1.5 Image-to-Video
2. Hunyuan Video base
3. HunyuanVideo-Avatar
4. LatentSync
5. Wan 2.2 5B

Wan 2.2 fica como modelo leve para testes rápidos. Para produção, priorize Hunyuan.

---

## Modelos baixados

### Hunyuan Video 1.5 I2V

Usado para:

* Image-to-video
* Animar imagens
* B-roll realista
* Talking head base
* VSL com imagens de personagem/produto

Arquivos:

```text
models/clip_vision/
└── sigclip_vision_patch14_384.safetensors

models/diffusion_models/
└── hunyuanvideo1.5_720p_i2v_fp16.safetensors

models/text_encoders/
├── qwen_2.5_vl_7b_fp8_scaled.safetensors
└── byt5_small_glyphxl_fp16.safetensors

models/vae/
└── hunyuanvideo15_vae_fp16.safetensors
```

---

### Hunyuan Video base

Usado para:

* Text-to-video
* B-roll cinematográfico
* Testes de vídeo geral

Arquivos:

```text
models/text_encoders/
├── clip_l.safetensors
└── llava_llama3_fp8_scaled.safetensors

models/vae/
└── hunyuan_video_vae_bf16.safetensors

models/diffusion_models/
├── hunyuan_video_t2v_720p_bf16.safetensors
└── hunyuan_video_image_to_video_720p_bf16.safetensors
```

---

### Wan 2.2 5B

Usado para:

* Testes rápidos
* Text-to-video leve
* Image-to-video leve
* B-roll simples

Arquivos:

```text
models/diffusion_models/
└── wan2.2_ti2v_5B_fp16.safetensors

models/text_encoders/
└── umt5_xxl_fp8_e4m3fn_scaled.safetensors

models/vae/
└── wan2.2_vae.safetensors
```

---

## Custom nodes instalados

```text
custom_nodes/
├── ComfyUI-WanVideoWrapper
├── ComfyUI-VideoHelperSuite
└── ComfyUI-LatentSyncWrapper
```

---

## Como usar no ComfyUI

### Hunyuan Video 1.5 Image-to-Video

1. Abra o ComfyUI.
2. Clique em Templates.
3. Pesquise:

```text
hunyuan
```

4. Escolha o workflow de Hunyuan Video 1.5 Image-to-Video.
5. Faça upload da imagem.
6. Escreva um prompt em inglês.
7. Use configurações iniciais:

```text
Resolution: 1280x704 ou 832x480
Frames: 81 a 121
FPS: 16 a 24
Steps: 20 a 30
Batch size: 1
```

---

## Prompt de teste para image-to-video

```text
A cinematic realistic shot of a middle-aged man standing in a modern home office, subtle natural head movement, soft facial expression, realistic skin texture, natural blinking, shallow depth of field, soft window light, premium commercial video style, slow camera push-in.
```

Negative prompt:

```text
low quality, blurry, distorted face, extra fingers, extra limbs, bad anatomy, unnatural mouth movement, text, watermark, logo, cartoon, plastic skin, flickering, deformed eyes
```

---

## Fluxo recomendado para VSL

```text
Imagem do personagem ou produto
↓
Hunyuan Video 1.5 I2V
↓
LatentSync ou HunyuanVideo-Avatar
↓
Upscale / edição final
```

---

## Fluxo recomendado para avatar falando

```text
Foto do avatar
↓
Gerar vídeo base com Hunyuan Video 1.5 I2V
↓
Aplicar áudio com LatentSync ou HunyuanVideo-Avatar
↓
Exportar vídeo final
```

Para melhor qualidade, gere vídeos curtos de 5 a 10 segundos e depois edite em sequência.

---

## Configurações recomendadas por GPU

### RTX 5090 32GB

Teste:

```text
832x480
81 frames
16 FPS
20 steps
```

Qualidade média:

```text
1280x704
81 frames
16 FPS
20 steps
```

### RTX 6000 Ada 48GB

```text
1280x704
121 frames
24 FPS
20–30 steps
```

### H100 80GB

```text
1280x704 ou maior
121+ frames
24 FPS
30 steps
```

---

## Se der erro de VRAM

Tente:

* reduzir resolução
* reduzir frames
* usar batch size 1
* fechar outros workflows
* clicar em Unload Models no ComfyUI
* reiniciar o ComfyUI

---

## Observações importantes

* Sem volume persistente, os modelos serão perdidos ao destruir a instância.
* Os downloads podem passar de 50GB.
* Use disco de pelo menos 150GB.
* Para modelos grandes, prefira servidores com internet rápida.
* Hunyuan é prioridade para produção.
* Wan é fallback leve.
