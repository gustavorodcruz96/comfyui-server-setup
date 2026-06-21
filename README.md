# ComfyUI Server Setup for Talking Head Lip-Sync

Este repositório instala um ambiente de **talking head / lip-sync** no ComfyUI para o fluxo:

**UMA FOTO + UM ÁUDIO -> vídeo sincronizado**

## Objetivo

Este setup cobre quatro caminhos:

1. **HunyuanVideo-Avatar (recomendado para máxima qualidade open-source)**
   - Entrada: 1 foto + 1 áudio
   - Saída: vídeo talking head / avatar animado
   - Melhor para: RTX 6000 Ada 48GB e H100 80GB
   - Também roda na RTX 5090 32GB com resolução/frames mais modestos

2. **HunyuanVideo 1.5 Image-to-Video + LatentSync 1.6 (recomendado para estabilidade no ComfyUI)**
   - Entrada: 1 foto + 1 áudio
   - Passo 1: gera um vídeo-base a partir da foto
   - Passo 2: refina o sincronismo labial com o áudio
   - Melhor para: RTX 5090 32GB, RTX 6000 Ada 48GB, H100 80GB

3. **SadTalker (fallback clássico para single-image talking head)**
   - Entrada: 1 foto + 1 áudio
   - Mais leve e mais antigo

4. **Wav2Lip (fallback para retarget de boca em vídeo)**
   - Normalmente usado quando você já tem um vídeo-base
   - Aqui fica como alternativa opcional

## Requisitos

- Linux
- NVIDIA GPU com CUDA
- ComfyUI já instalado em `/workspace/ComfyUI`
- Python / pip disponíveis no ambiente do ComfyUI
- `ffmpeg`, `git`, `wget`, `curl`

## GPUs alvo

### RTX 5090 32GB
Recomendado:
- HunyuanVideo 1.5 I2V + LatentSync 1.6
- SadTalker
- Wav2Lip

Aceitável:
- HunyuanVideo-Avatar com resolução menor e clipes mais curtos

### RTX 6000 Ada 48GB
Recomendado:
- HunyuanVideo-Avatar
- HunyuanVideo 1.5 I2V + LatentSync 1.6
- SadTalker
- Wav2Lip

### H100 80GB
Recomendado:
- HunyuanVideo-Avatar
- HunyuanVideo 1.5 I2V + LatentSync 1.6
- SadTalker
- Wav2Lip

## Estrutura de pastas esperada

### HunyuanVideo-Avatar
```text
ComfyUI/models/HunyuanVideo-Avatar/weights/ckpts/...
