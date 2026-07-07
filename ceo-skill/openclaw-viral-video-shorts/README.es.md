<!-- LANGS -->
[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · **Español**

# OpenClaw Viral Video Shorts

Un skill de OpenClaw + pipeline de extremo a extremo para convertir una **página de proveedor / producto** en un **short viral vertical (9:16) de 30 segundos**:

1. **Descubrir** referencias virales reales en Instagram / TikTok / Shorts
2. **Extraer** su *estructura* viral reutilizable (gancho → dolor → demo → recompensa → CTA) en un guion original
3. **Generar** el vídeo con material real del producto —clips IA imagen-a-vídeo + metraje real + locución IA + música libre de derechos— y montarlo con `ffmpeg`

> Principio clave: **aprende la estructura, nunca copies identidad/contenido.** Se transfiere el ritmo, la mecánica del gancho, la emoción y la lógica de escenas —guion, visuales y voz son nuevos.

Este README documenta el flujo completo **descubrir → guion → generar** tal como se ejecutó de principio a fin (caso: un short de espejos LED de ZekSmart). `SKILL.md` es el flujo orientado al agente; este archivo es el manual para el operador humano.

---

## Visión general del pipeline

```
[1] Descubrir referencias   Exa + Tavily  → reels de IG/TikTok
        ↓
[2] Extraer estructura       gancho/dolor/demo/recompensa/CTA → guion + subtítulos
        ↓
[3] Reunir material          imágenes de producto de Alibaba  /  metraje subido (zip)
        ↓
[4] Generar clips            "Seedance 2.0" de Volcengine Ark imagen-a-vídeo (9:16, 720p, 5s c/u)
        ↓
[5] Locución                 ElevenLabs TTS (una línea por escena, sincronizada a slots de 5s)
        ↓
[6] Música de fondo          Pixabay libre de derechos (mp3 directo desde CDN)
        ↓
[7] Montaje                  ffmpeg: normalizar → subtítulos (overlay PNG) → concatenar → mezcla con ducking → multiplexar
        ↓
[8] (opcional) Entrega       subir / enviar el mp4 final
```

---

## Requisitos previos

**Herramientas CLI**

| Herramienta | Para qué | Notas |
|-------------|----------|-------|
| `ffmpeg` / `ffprobe` | todo el trabajo de audio/vídeo | **puede no traer `drawtext`** (sin libfreetype) → los subtítulos se renderizan como overlays PNG, ver [Trampas](#trampas-y-lecciones) |
| `python3` + `Pillow` | PNG de subtítulos, llamadas API | `pip install --break-system-packages Pillow` |
| Playwright (navegador) | extraer la URL de música de Pixabay | solo para el paso de BGM |
| `yt-dlp` *(opcional)* | descargar una referencia como mp4 local | opcional; la estructura también se extrae de los snippets |

**Claves API (exportar como variables de entorno — nunca las subas al repo)**

```bash
export EXA_API_KEY=...          # descubrimiento de referencias virales
export TAVILY_API_KEY=...       # búsqueda + extracción de páginas (Alibaba, respaldo Pixabay)
export ARK_API_KEY=...          # generación de vídeo Volcengine Ark / Seedance 2.0
export ELEVENLABS_API_KEY=...   # locución TTS
export KIE_API_KEY=...          # opcional: generación de avatar GPT-Image (ruta por defecto del skill)
```

---

## [1] Descubrir referencias virales

Encuentra shorts reales que estén rindiendo en el nicho. Usa **ambos** motores —tienen cobertura distinta.

```bash
# Exa — descubrimiento semántico (nota: Exa NO sirve el dominio instagram.com;
# incluye tiktok/youtube y deja que Tavily cubra instagram)
curl -s -X POST https://api.exa.ai/search -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"viral LED mirror smart mirror short video reel",
       "numResults":8,
       "includeDomains":["tiktok.com","youtube.com"]}'

# Tavily — cubre instagram.com + devuelve texto del snippet
curl -s -X POST https://api.tavily.com/search -H "Content-Type: application/json" \
  -d "{\"api_key\":\"$TAVILY_API_KEY\",
       \"query\":\"viral LED mirror tiktok instagram reel hook\",
       \"search_depth\":\"advanced\",\"max_results\":6,
       \"include_domains\":[\"tiktok.com\",\"instagram.com\"]}"
```

Opcional: descargar una referencia a mp4 local para análisis cuadro a cuadro (requiere `yt-dlp`):

```bash
node scripts/ingest-source-video.mjs --url "<reel-url>" --out source
```

---

## [2] Extraer estructura viral → guion

Destila las referencias en una estructura reutilizable y escribe encima un guion de producto **original**.

```json
{
  "viral_pattern": "aburrido-vs-wow → demo → prueba → CTA",
  "emotional_driver": "aspiración + satisfacción",
  "structure": ["0-5 gancho", "5-15 demo", "15-25 prueba", "25-30 CTA"]
}
```

Una estructura de 30s fiable (6 × 5s escenas), cada una con un subtítulo/línea de voz corta:

| t | escena | subtítulo / voz |
|---|--------|-----------------|
| 0–5 | gancho (la toma que más frena el scroll) | "Your bathroom mirror? So boring." |
| 5–10 | demo de función | "Touch to dim. Three light colors." |
| 10–15 | variedad / escala | "Round, oval, any shape, any size." |
| 15–20 | **prueba real** (fábrica / control de calidad) | "Made in our own factory." |
| 20–25 | funciones de confianza | "Anti-fog, bluetooth, memory function." |
| 25–30 | CTA | "OEM/ODM — DM us for wholesale pricing!" |

---

## [3] Reunir material del producto

Dos fuentes reales funcionan bien:

**A. Imágenes de producto de una tienda Alibaba / 1688** (extrae a resolución completa, quitando el sufijo de tamaño del CDN):

```bash
curl -s -X POST https://api.tavily.com/extract -H "Content-Type: application/json" \
  -d "{\"api_key\":\"$TAVILY_API_KEY\",\"urls\":[\"<url-listado-tienda>\"],\"extract_depth\":\"advanced\"}" \
  | python3 -c "import sys,json,re; t=json.load(sys.stdin)['results'][0]['raw_content']; \
[print(re.sub(r'_\d+x\d+\.jpg$','.jpg',u)) for u in set(re.findall(r'https://s\.alicdn\.com/@sc04/kf/[^\"\s]+?\.jpg', t))]"
# descarga con UA de navegador + referer o el CDN puede dar 403
curl -sL -A "Mozilla/5.0" -e "https://example.en.alibaba.com/" "<url-imagen>" -o img01.jpg
```

**B. Metraje real subido por el cliente** (p. ej. un `.zip` de inspección de fábrica). Los zips de Windows en chino usan nombres **GBK** que el `unzip` de macOS no procesa —extrae con Python y recodifica:

```python
import zipfile, os
z = zipfile.ZipFile("footage.zip"); os.makedirs("ex", exist_ok=True); i = 0
for info in z.infolist():
    if info.is_dir(): continue
    try: name = info.filename.encode('cp437').decode('gbk')   # arregla nombres GBK
    except Exception: name = info.filename
    if os.path.splitext(name)[1].lower() in ('.mp4', '.mov'):
        i += 1
        open(f"ex/clip{i:02d}.mp4", "wb").write(z.open(info).read())
```

---

## [4] Generar clips — "Seedance 2.0" de Volcengine Ark (imagen-a-vídeo)

Pasa cada imagen de producto como primer fotograma; Seedance la anima (luces encendiéndose, acercamiento, antivaho despejando, cambio de color…).

```bash
# Crear tarea — imagen-a-vídeo. image_url puede ser una URL pública o data:base64.
# Los parámetros de generación van como flags de texto al final del prompt.
curl -s -X POST "https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks" \
  -H "Authorization: Bearer $ARK_API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"doubao-seedance-2-0-fast-260128",
       "content":[
         {"type":"text","text":"LED mirror lights turn on, slow cinematic push-in, premium reveal --resolution 720p --ratio 9:16 --duration 5 --camerafixed false"},
         {"type":"image_url","image_url":{"url":"<url-imagen-publica>"}}
       ]}'
# → {"id":"cgt-..."}

# Sondea hasta status == "succeeded", luego lee content.video_url
curl -s "https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks/<id>" \
  -H "Authorization: Bearer $ARK_API_KEY"
```

- Modelos: `doubao-seedance-2-0-260128` (calidad) / `doubao-seedance-2-0-fast-260128` (más rápido y barato).
- **Lanza todas las tareas de escena en paralelo** y sondéalas juntas —la generación (~3–6 min/clip) es el cuello de botella.
- Cada clip devuelve 9:16 720p ~5s.

---

## [5] Locución — ElevenLabs

Genera una línea corta por escena y coloca cada una en su marca de 5 segundos.

```bash
# elige una voz femenina creadora, p. ej. "Jessica" (juguetona, brillante, cálida)
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/cgSgspJ2msm6clMCkdW9?output_format=mp3_44100_128" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" -H "Content-Type: application/json" \
  -d '{"text":"Your bathroom mirror? So boring.",
       "model_id":"eleven_multilingual_v2",
       "voice_settings":{"stability":0.4,"similarity_boost":0.8,"style":0.45,"use_speaker_boost":true}}' \
  -o vo1.mp3
```

`eleven_multilingual_v2` también cubre chino / japonés / español para locuciones localizadas. (Respaldo sin clave: la voz `say -v Samantha` de macOS.)

Coloca las líneas en una pista de 30s con `adelay` en 0.3s, 5.3s, 10.3s … y luego `amix`.

---

## [6] Música de fondo — Pixabay (libre de derechos)

La **API pública de Pixabay solo cubre imágenes y vídeo —la música no está en la API**, y la página de búsqueda carga las URLs por JS. Usa un navegador headless para leer la URL mp3 directa del CDN y descárgala (el archivo del CDN no necesita clave):

```js
// tras navegar a https://pixabay.com/music/search/upbeat/
() => {
  const found = new Set();
  document.querySelectorAll('script').forEach(s => {
    const m = (s.textContent||'').match(/https:\/\/cdn\.pixabay\.com\/audio\/[^"' ]+?\.mp3/g);
    if (m) m.forEach(u => found.add(u));
  });
  const btn = document.querySelector('button[aria-label*="Play" i]'); if (btn) btn.click();
  document.querySelectorAll('audio,source').forEach(a => a.src && found.add(a.src));
  return [...found];
}
```

```bash
curl -sL -A "Mozilla/5.0" -e "https://pixabay.com/" "<url-audio-cdn>" -o bgm.mp3
```

---

## [7] Montaje con ffmpeg

**Normaliza cada clip a 720×1280, 30fps.** Los clips IA verticales se recortan para llenar; el metraje horizontal se ajusta con fondo desenfocado:

```bash
# clip IA vertical
ffmpeg -y -i scene.mp4 -t 5 -vf "scale=720:1280:force_original_aspect_ratio=increase,crop=720:1280,fps=30" -an seg.mp4
# metraje horizontal → 9:16 con fondo desenfocado
ffmpeg -y -ss 30 -t 5 -i factory.mp4 -filter_complex \
  "[0:v]scale=720:1280:force_original_aspect_ratio=increase,crop=720:1280,boxblur=24:6[bg];\
   [0:v]scale=720:-2[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2,fps=30" -an seg4.mp4
```

**Subtítulos como overlay PNG** (esta build de ffmpeg no tiene `drawtext`). Renderiza tiras transparentes con Pillow y luego `overlay`:

```python
from PIL import Image, ImageDraw, ImageFont
f = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 46)
img = Image.new("RGBA", (720, 160), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
d.rounded_rectangle([60, 10, 660, 150], radius=24, fill=(0, 0, 0, 150))
d.text((360, 80), "Touch to dim", font=f, fill="white", anchor="mm")
img.save("cap.png")
```
```bash
ffmpeg -y -i seg.mp4 -i cap.png -filter_complex "[0:v][1:v]overlay=x=(W-w)/2:y=H-360" -an final_seg.mp4
ffmpeg -y -f concat -safe 0 -i concat.txt -c:v libx264 -pix_fmt yuv420p -r 30 video.mp4   # concatena todo
```

**Audio: ducking con sidechain** para que la música baje bajo la voz y suba en los silencios:

```bash
ffmpeg -y -i voice30.wav -i bgm_seg.wav -filter_complex \
 "[1]volume=0.55[bg];[bg][0]sidechaincompress=threshold=0.03:ratio=8:attack=15:release=350[duck];\
  [0][duck]amix=inputs=2:normalize=0,alimiter=limit=0.95[m]" -map "[m]" mixed.wav
# multiplexa sobre el vídeo sin audio
ffmpeg -y -i video.mp4 -i mixed.wav -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -t 30 final.mp4
```

Verifica niveles con `volumedetect`: media de la mezcla ≈ −15 dB, y confirma que el BGM se oye (≈ −22 dB) dentro de un silencio de voz.

---

## [8] Entrega (opcional)

Exporta `final.mp4` (720×1280, ~30s). Añade un **sonido de tendencia dentro de la app** en CapCut / 剪映 antes de publicar —las plataformas favorecen el audio de tendencia nativo sobre cualquier pista incrustada.

---

## Trampas y lecciones

Problemas reales encontrados al ejecutar este pipeline —a ti también te morderán:

- **ffmpeg sin `drawtext`** → no quemes texto con `drawtext`; renderiza subtítulos como **overlays PNG** (Pillow) + `overlay`.
- **Los arrays de `zsh` empiezan en 1**, no en 0 como bash → `${arr[1]}` es el primer elemento; un off-by-one descarta/duplica líneas en silencio.
- **Exa rechaza `instagram.com`** en `includeDomains` (`SOURCE_NOT_AVAILABLE`) → usa Tavily para Instagram.
- **Imágenes del CDN de Alibaba** dan 403 sin `User-Agent` + `Referer` de navegador; quita el sufijo `_480x480.jpg` para el original.
- **Nombres GBK en zips** de Windows en chino rompen `unzip` de macOS → extrae con Python recodificando `cp437→gbk`.
- **La música de Pixabay no está en la API pública** → renderiza la página con navegador headless y lee la URL mp3 del CDN desde JS / `<audio>`.
- **BGM inaudible tras mezclar** → es un problema de *nivel*: normaliza la música a una sonoridad conocida (p. ej. `loudnorm I=-22`) y revisa `volumedetect` en un silencio de voz; no confíes en un `volume=0.18` crudo.
- **Latencia de Seedance** → lanza todas las tareas en paralelo y sondéalas juntas; un bucle en serie desperdicia minutos.

---

## Estructura de salida

```
viral-shorts/<campaign>/<YYYY-MM-DD>/
  source-images/      # fotos de producto
  real-footage/ex/    # metraje del cliente (nombres normalizados)
  clips/              # clips Seedance generados
  audio/              # locución, bgm, mezclas
  caps/               # PNG de subtítulos
  final.mp4           # el entregable
  receipts.json       # modelos, ids de tarea, rutas, notas
```

---

## Contenido del repositorio

- `SKILL.md` — flujo de trabajo orientado al agente
- `scripts/ingest-source-video.mjs` — ayudante URL de origen → mp4 local
- `scripts/apply-overlays.mjs` — renderizador de overlays de subtítulos / UI

## Seguridad y cumplimiento

- **Aprende la estructura, no la identidad** — nunca copies las palabras, escenas, voz o imagen de un creador.
- Usa solo música libre de derechos / licenciada; no incluyas audio de tendencia con copyright.
- No afirmes capacidades del producto no respaldadas por la página.
- **No subas al repo** vídeos generados, capturas, receipts, claves API ni archivos `.env` locales.
