# ComfyUI Lip Sync Setup — Vast.ai

Setup para criar um servidor ComfyUI na Vast.ai focado em:

```text
foto + áudio -> avatar falando
vídeo + áudio -> lip sync
```

Este setup usa apenas modelos/repositórios free/open-source.

Não usa:

```text
Veo
Runway
HeyGen
ElevenLabs
APIs pagas
modelos pagos
```

---

## Template recomendado na Vast.ai

Use um template ComfyUI com Jupyter.

Exemplo:

```text
vastai/comfy_v0.22.0-cuda-12.9-py312/jupyter
```

ou uma versão mais nova equivalente.

---

## GPU recomendada

```text
RTX 5090 32GB       bom para começar
RTX 6000 Ada 48GB   melhor custo/benefício
H100 80GB           melhor opção
```

Disco recomendado:

```text
120GB mínimo
200GB+ se instalar HunyuanVideo-Avatar
```

---

## Instalação rápida

No terminal do Jupyter do servidor Vast:

```bash
cd /workspace

git clone https://github.com/gustavorodcruz96/comfyui-server-setup.git

cd comfyui-server-setup

bash setup.sh
```

Depois reinicie o ComfyUI:

```text
Stop Instance -> Start Instance
```

ou use o botão de restart/reload do template.

---

## O que o setup instala

### 1. ComfyUI-LatentSyncWrapper

Instala o node de LatentSync no ComfyUI.

Uso principal:

```text
vídeo + áudio -> vídeo com boca sincronizada
```

Como o LatentSync trabalha melhor com vídeo, o setup cria um helper para transformar foto em vídeo-base.

Exemplo:

```bash
/workspace/photo_to_video_25fps.sh /workspace/input/foto.png 8 /workspace/input/avatar_base.mp4
```

Isso cria um vídeo de 8 segundos a partir da foto.

Depois, dentro do ComfyUI:

```text
avatar_base.mp4 + audio.wav -> LatentSync -> vídeo final
```

---

### 2. MuseTalk

Instala o MuseTalk e baixa os pesos públicos.

Uso principal:

```text
foto/vídeo + áudio -> vídeo falando
```

Ele fica em:

```text
/workspace/MuseTalk
```

O setup baixa os pesos em:

```text
/workspace/MuseTalk/models/
```

Arquivos principais:

```text
models/
├── musetalk/
│   ├── musetalk.json
│   └── pytorch_model.bin
├── musetalkV15/
│   ├── musetalk.json
│   └── unet.pth
├── syncnet/
│   └── latentsync_syncnet.pt
├── dwpose/
│   └── dw-ll_ucoco_384.pth
├── face-parse-bisent/
│   ├── 79999_iter.pth
│   └── resnet18-5c106cde.pth
├── sd-vae/
│   ├── config.json
│   └── diffusion_pytorch_model.bin
└── whisper/
    ├── config.json
    ├── pytorch_model.bin
    └── preprocessor_config.json
```

---

### 3. HunyuanVideo-Avatar opcional

O HunyuanVideo-Avatar é mais avançado, mas é muito grande e pesado.

Ele não instala por padrão.

Para instalar também:

```bash
INSTALL_HUNYUAN_AVATAR=1 bash setup.sh
```

Ele será instalado em:

```text
/workspace/HunyuanVideo-Avatar
```

---

## Como usar dentro do ComfyUI

### Fluxo recomendado com LatentSync

1. Coloque sua foto em:

```text
/workspace/input/foto.png
```

2. Coloque seu áudio em:

```text
/workspace/input/audio.wav
```

3. Crie o vídeo-base:

```bash
/workspace/photo_to_video_25fps.sh /workspace/input/foto.png 8 /workspace/input/avatar_base.mp4
```

4. Abra o ComfyUI.

5. Use nodes para carregar:

```text
Load Video -> /workspace/input/avatar_base.mp4
Load Audio -> /workspace/input/audio.wav
LatentSync
Video Combine / Save Video
```

6. Parâmetros iniciais:

```text
FPS: 25
inference_steps: 20
lips_expression: 1.5
```

Para fala mais expressiva:

```text
lips_expression: 2.0 até 2.5
```

Para fala mais suave:

```text
lips_expression: 1.2 até 1.5
```

---

## Como usar MuseTalk direto no terminal

O setup cria este helper:

```bash
/workspace/run_musetalk_photo_audio.sh
```

Exemplo:

```bash
/workspace/run_musetalk_photo_audio.sh \
  /workspace/input/foto.png \
  /workspace/input/audio.wav \
  /workspace/output/avatar_musetalk.mp4
```

Se quiser instalar também o runtime completo do MuseTalk:

```bash
INSTALL_MUSETALK_RUNTIME=1 bash setup.sh
```

Observação:

```text
MuseTalk pode exigir dependências específicas de MMLab.
Se der erro no runtime, use primeiro o fluxo do ComfyUI com LatentSync.
```

---

## Melhor fluxo para VSL/avatar

```text
foto limpa e frontal
↓
criar vídeo-base 25 FPS
↓
LatentSync no ComfyUI
↓
áudio limpo
↓
vídeo final
```

Para qualidade melhor:

```text
foto
↓
gerar movimento leve com Hunyuan/Wan
↓
LatentSync
↓
vídeo final
```

---

## Dicas para melhores resultados

Use:

```text
rosto frontal
boa iluminação
áudio limpo
áudio sem música alta
sem eco
foto em boa resolução
vídeos curtos de 5 a 10 segundos
25 FPS
```

Evite:

```text
rosto muito de lado
óculos escuros
mão na boca
cabelo cobrindo a boca
áudio com ruído
foto muito borrada
```

---

## Se der erro de VRAM

Tente:

```text
reduzir duração do vídeo
usar 5 segundos em vez de 10
usar batch menor
clicar em Unload Models no ComfyUI
reiniciar o ComfyUI
usar RTX 6000 Ada ou H100
```

---

## Reinstalar em servidor novo

Em qualquer novo servidor Vast:

```bash
cd /workspace

git clone https://github.com/gustavorodcruz96/comfyui-server-setup.git

cd comfyui-server-setup

bash setup.sh
```

Se o repositório estiver privado, faça login no GitHub no servidor ou torne o repo público.

---

## Comandos úteis

Criar vídeo-base a partir de foto:

```bash
/workspace/photo_to_video_25fps.sh /workspace/input/foto.png 8 /workspace/input/avatar_base.mp4
```

Rodar MuseTalk direto:

```bash
/workspace/run_musetalk_photo_audio.sh /workspace/input/foto.png /workspace/input/audio.wav /workspace/output/avatar_musetalk.mp4
```

Verificar modelos baixados:

```bash
/workspace/check_lipsync_models.sh
```
