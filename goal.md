# 🦄 ProteinLoop — Master Plan · AMD Developer Hackathon: ACT II

**Track:** Unicorn 🦄 (all levels · build your startup)
**Fechas:** Julio 6–11, 2026 · Online · lablab.ai · Kick-off Jul 6, 10:00 AM CST
**Objetivo:** 1er lugar Unicorn ($2,500) + Best AMD-Hosted Gemma ($2,000) = **$4,500**
**Stack:** Python (sim + RLVR + Gemma self-host en ROCm) · llama.cpp/Metal (Gemma local offline para desarrollo) · Elixir/Sagents/Phoenix (orquestación + demo)

---

## El nombre: ProteinLoop (doble lectura)

- **Negocio:** cierra el *loop de la proteína* que la aquaponía deja afuera — pescado, langostino, huevos + vegetales, en ciclo cerrado.
- **Técnico:** es literalmente un *agentic loop* — el vocabulario de loop/harness engineering de 2026. Un nombre que le habla al productor **y** al ingeniero de AMD.

**Tagline:** *"An agentic loop that closes the protein cycle."* / *"Una milpa acuática con cerebro AI."*

---

## La tesis (pitch en una línea)

> *"Aquaponics sin proteína es un huerto caro. ProteinLoop cierra el loop con proteína animal — pescado, langostino y huevos — y un agentic loop tolerante a fallos lo hace operable para cualquier familia rural de Latinoamérica."*

**El problema:** todos celebran hidroponia/acuaponia como el futuro de la seguridad alimentaria, pero solo entregan vegetales (+ tilapia de adorno). La proteína animal queda afuera. Un loop cerrado con peces, langostinos, gallinas y plantas SÍ resuelve proteína a bajo costo — pero es demasiado complejo para operar a mano. Esa complejidad es la barrera, y el agentic loop es lo que la derriba.

**El héroe es el agente. DECT NR+ es la historia de escala. La acuicultura es el impacto.**

**Idioma:** inglés para jurado/documentación, español para la interfaz del productor.

---

## El sistema (loop cerrado)

```
   Lenteja de agua (Lemna)  ← crece gratis en superficie
        │  alimenta a:
        ├──────────────► Peces (tilapia / carpa / trucha)  ┐
        ├──────────────► Langostino (M. rosenbergii)       │ en tanques 1000L (IBC/tambores)
        └──────────────► Gallinas ponedoras                │
                                                           │
   Desechos peces + langostino ──► fertilizan ──► Grow beds hidropónicos
                                                           │
   Recortes vegetales ──► alimentan gallinas               │
   Agua filtrada ◄─────────────────────────────────────────┘
        └──► regresa al tanque

   PRODUCTOS: pescado + langostino + huevos + vegetales
```

**Por qué cada organismo:**
- **Langostino M. rosenbergii** — agua dulce (compatible directo con hidroponia), come detritos, control biológico de sólidos. Talla comercial 6–9 meses. (Vannamei descartado: necesita salobre.)
- **Peces (policultivo):** tilapia (genera nitratos), carpa/bagre (otros nichos), trucha (tierras altas frías). Tilapia + langostino conviven en el mismo tanque.
- **Gallinas ponedoras** — huevos = proteína diaria. Comen recortes + lenteja de agua (da yema naranja). Gallinaza composta de vuelta.
- **Lenteja de agua (Lemna)** — conector universal. Duplica biomasa cada 48h, 90% menos agua por kilo de proteína.

Setup físico real y barato: 3 tambores + 1 tanque conectados con PVC (kit casero brasileño "camarão 3x mais barato").

---

## El corazón técnico

Esto separa un top-10 de un ganador. ACT I la ganó **Chaos Economy**: multi-agente + RL (GRPO sobre Llama-3.2) con comportamiento emergente. Lección: premian agentes que interactúan + profundidad técnica, no apps bonitas. ProteinLoop lo sube de nivel con cuatro pilares.

### Pilar 1 — Agentic loop + harness engineering
Progresión 2026: prompt → context → harness → **loop**. El **harness** es la capa determinista que envuelve al LLM: el modelo *propone* acciones (alimentar, airear, cosechar), el harness *valida* contra las reglas físicas del ecosistema, *ejecuta* en el sim, *registra*. Regla de oro del loop: **condición de terminación verificable** = "completar el ciclo de cultivo sin colapso". En Sagents esto se implementa como un **custom execution step** insertado en el pipeline del agente (`verify_ecosystem_safety`), y como **`until_tool`** que fuerza el loop hasta cerrar el ciclo con resultado estructurado.

### Pilar 2 — Multi-agente con comportamiento emergente
Sub-agentes (tanque de peces, langostino, hidroponia, gallinas/lenteja) **compiten por recursos limitados** (agua, nutrientes, alimento, O₂). El equilibrio del ecosistema **emerge** de la negociación, no está programado. En Sagents = **SubAgents** con delegación y ejecución paralela.

### Pilar 3 — RLVR: el simulador ES el verificador
RL 2026 se movió a métodos critic-free y por verificación: **GRPO** (critic-free, referencia central) y **RLVR** (reward por verificación programática, no labels humanos). Tu simulador es el verificador perfecto: ¿sobrevivieron los camarones? ¿amonio bajo el umbral letal? ¿biomasa maximizada sin colapso? Todo verificable. El digital twin no es solo el gimnasio del agente — es el **reward verifier** que lo entrena. Loop GRPO/RLVR ligero sobre Gemma, unos cientos de pasos, mostrando la política mejorar ("antes vs. después" = oro para el video).

### Pilar 4 — Gemma self-hosted en AMD Developer Cloud (gana el criterio de plataforma)
**Gemma 4** (Google DeepMind, Apache 2.0), servida por vos con **vLLM sobre ROCm en AMD Developer Cloud**. Hay imagen Docker oficial Day-Zero: `vllm/vllm-openai-rocm:gemma4`. Expone API OpenAI-compatible → tu app Elixir le pega igual que a Fireworks. En el pitch: *"Gemma 4 corriendo sobre ROCm en GPUs AMD Instinct, servida por nosotros."* Multimodal (evaluación de salud por foto) + razonamiento (decisiones). Un solo modelo cubre agentes + visión + pelea el **Best AMD-Hosted Gemma Project ($2,000)**.

---

## Las 5 cosas locas / innovadoras (todas sobre Sagents + OTP)

1. **Self-healing a nivel cluster (Horde).** Sagents distribuye agentes en un cluster con redistribución automática y **migración de estado** cuando un nodo entra/sale (eventos `node_transferring`/`node_transferred`). En vivo: matás un nodo, el agente **migra con su estado intacto** a otro nodo, visible en pantalla. Eso ES el mesh DECT NR+ self-healing, real, no mock.

2. **Cascada de mortalidad en tiempo real.** Sim acelerado (1 día = segundos). Provocás spike de amonio en tanque 3 → sensor emite Signal → sub-agente razona con Gemma → supervisor rebalancea recursos del resto → todo el árbol reacciona en cascada, visible en LiveView vía PubSub (sin JS). Sin AI colapsa (control); con el agente se salva. El "antes vs. después" **en vivo frente al jurado**.

3. **Harness como custom step.** El run loop de Sagents es un pipeline Elixir componible (`call_llm |> check_pre_tool_hitl |> execute_tools |> ...`). Insertás tu `verify_ecosystem_safety` que valida cada acción contra la física del sim antes de ejecutar. Tu harness determinista, encajado limpio en el loop del agente.

4. **Terminación verificable (`until_tool`).** Fuerza al agente a loopear hasta cerrar el ciclo de cultivo, devolviendo `{:ok, state, %ToolResult{}}`, garantizado incluso a través de interrupts HITL y sub-agentes. Tu condición de terminación del agentic loop, ya implementada.

5. **HITL granular en español.** Antes de una acción irreversible (cosechar, descartar agua), el agente **pausa** ese sub-árbol y pregunta al productor en español: *"El tanque 2 está listo para cosechar. ¿Procedo?"* Cada tool call se aprueba/**edita**/rechaza individualmente ("cosechá, pero solo la mitad"), y el interrupt se propaga de sub-agentes al padre. Supervisión humana como control de flujo del actor system, no como un `if`.

**Lo "loco" del proyecto:** el sistema de acuicultura ES un actor system distribuido tolerante a fallos que se ve reaccionar en vivo. Ningún competidor va a tener esto — casi todos harán un chatbot Python con dashboard estático.

---

## Diseño para comunidades pobres (impacto real)

- **El mesh funciona sin internet del productor** — sensores en malla local, sin WiFi ni datos de la familia. Solo UN nodo comunitario sube la telemetría de todo el pueblo.
- **El agente en la nube se comparte** — sirve a 50 patios a la vez; costo tiende a centavos por familia.
- **Interfaz por voz vía WhatsApp/SMS en español, no dashboard** — resuelve accesibilidad y hardware (celular viejo).
- **Offline con degradación elegante** — si se cae internet, una Raspberry Pi comunitaria corre un modelo chico con alertas de emergencia; vuelve la conexión → el agente grande retoma la optimización fina.
- **Modelo cooperativo** — el pueblo comparte nodo de internet, Pi de respaldo, pool de sensores.

El agente no es solo el optimizador — es el traductor entre la tecnología compleja y la persona que no tiene nada.

---

## Frontend de control: Phoenix LiveView (server-authoritative real-time)

El estado del sistema cambia constantemente (telemetría, decisiones del agente, transiciones de tanque, nodos cayendo/recuperándose). Es *server-authoritative real-time state* — exactamente para lo que LiveView fue hecho. El estado vive en el servidor (donde ya corren los agentes Sagents) y LiveView empuja los cambios por WebSocket sin JavaScript. Mismo BEAM que corre los agentes renderiza la UI. Sin REST intermedio, sin polling, sin sync manual.

Flujo:
```
Sensores/sim (Python) ──► Agentes Sagents (Elixir/OTP)
                                │
                          Phoenix.PubSub  ← bus de eventos
                                │
                          LiveView (suscrito a topics)
                                │
                          WebSocket ──► pantalla
```
Cada agente hace `broadcast` a un topic al decidir o cambiar de estado; el LiveView re-renderiza solo lo que cambió. Reactivo de punta a punta.

**Dos rutas del mismo backend (dos audiencias):**
- **Vista operador/jurado (inglés, rica):** dashboard completo — digital twin, topología del mesh, decisiones de agentes, curva de aprendizaje RLVR, cascada de mortalidad en vivo, self-healing visible.
- **Vista productor (español, mínima):** orientada a la acción — "tu tanque necesita X, aprobá o rechazá". En campo se degrada a WhatsApp/voz; en el demo, una `live` route limpia.

Mismo backend, mismos agentes, mismo PubSub, dos `live` routes. Comunica que pensaste en el usuario real, no solo en el panel bonito.

**Precaución:** LiveView es ideal mientras el control viva del lado Elixir. Para visuales, usá SVG para el diagrama del mesh + transiciones CSS. NO metas un motor 3D tipo videojuego en un hackathon — quema días sin sumar al juicio.

---

## Arquitectura de endpoint abstraído (protege el desarrollo)

```
Elixir/Sagents  ──llama a──►  GEMMA_ENDPOINT (env var)
                                   │
                 ┌─────────────────┴─────────────────┐
                 │  Local: llama.cpp + Gemma 4 E2B    │  ← modelo menor, offline, mismo contrato
                 │  Fallback: Fireworks API           │  ← respaldo administrado
                 │  Final: vLLM en AMD Cloud          │  ← self-host, gana puntos AMD
                 └───────────────────────────────────┘
```
Los tres exponen API OpenAI-compatible. Cambiás una env var. El desarrollo y ensayo usan Gemma 4 E2B IT Q4 local, la variante Gemma 4 más pequeña; la evidencia final usa el mismo modelo servido por vLLM/ROCm en AMD. Si el self-host se complica el día del deadline, Fireworks queda como fallback. En Sagents/Elixir LangChain se usa el provider OpenAI-compatible apuntado al endpoint.

---

## Stack concreto

| Capa | Herramienta |
|------|-------------|
| Cómputo | AMD Developer Cloud (GPUs Instinct) + ROCm |
| Modelo central | **Gemma 4 self-hosted** en `vllm/vllm-openai-rocm:gemma4` (fallback: Fireworks) |
| RL / entrenamiento | GRPO + RLVR, sim como reward verifier (TRL o verl, PyTorch/ROCm) |
| Simulador / verifier | Python (numpy/scipy) — expone estado vía HTTP/socket a Elixir |
| Orquestación agentes | **Sagents** (Elixir, OTP + LangChain): SubAgents, HITL, `until_tool`, custom steps |
| Distribución / self-heal | Horde (dentro de Sagents) — migración de estado entre nodos |
| Dashboard | **Phoenix LiveView** + PubSub (real-time) |
| Interfaz productor | Voz/texto vía WhatsApp/SMS, español |
| Offline fallback | Raspberry Pi comunitaria, modelo chico |
| Empaquetado | **Docker (obligatorio) + repo público con README que corra** |

---

## Plan de 5 días

### Día 1 (Jul 6) — Fundación + verifier + esqueleto
- Setup: confirmar Enrolled, equipo creado, Discord conectado, créditos Fireworks.
- **Python:** simulador del loop (química de agua + crecimiento organismos + flujos de nutrientes + mesh simulado). Función de **reward verificable** (supervivencia + biomasa + estabilidad) y condición de terminación.
- **Elixir:** esqueleto Phoenix + Sagents, capa de modelo abstraída detrás de `GEMMA_ENDPOINT` (apunta a Fireworks por ahora).
- **Entregable:** el sim corre y calcula reward; el esqueleto Elixir llama a Gemma vía Fireworks.

### Día 2 (Jul 7) — Multi-agente + créditos AMD
- **Sagents:** agente supervisor + SubAgents (tanque, langostino, hidroponia, gallinas). Harness como custom step (`verify_ecosystem_safety`). `until_tool` para cerrar ciclo.
- **AMD Cloud:** cuando lleguen créditos (día 7 por registro tardío), levantar `vllm/vllm-openai-rocm:gemma4`, apuntar `GEMMA_ENDPOINT` a tu instancia.
- **Entregable:** loop cerrado sim ↔ harness ↔ multi-agente; Gemma self-hosteado respondiendo.

### Día 3 (Jul 8) — RLVR + self-heal + inteligencia
- **Python:** loop GRPO/RLVR ligero sobre Gemma usando el sim como verificador. Captar "antes vs. después".
- **Sagents/Horde:** self-healing distribuido — matar un nodo, migrar agente con estado.
- Predicción de anomalías (amonio/OD) con intervención antes de la mortandad.
- **Entregable:** curva de mejora de la política + demo de nodo cayendo y recuperándose + mortandad evitada.

### Día 4 (Jul 9) — La cara + HITL
- **LiveView:** dashboard — digital twin + decisiones del agente + topología mesh + cascada en tiempo real + curva de aprendizaje.
- HITL granular en español (aprobar/editar/rechazar acciones irreversibles).
- **Entregable:** demo visual navegable con la cascada de mortalidad en vivo + escena de aprobación humana.

### Día 5 (Jul 10–11) — Empaquetar y pitch
- **Containerizar todo (Docker)** + repo público con README que corra. Obligatorio.
- **Video** (decide con jurado humano): escena de cascada en vivo + nodo self-healing + aprobación en español → cosecha.
- **Slide deck** (pitch de startup: mercado, costo por familia, visión).
- Submission en lablab con todos los campos. Deadline: **Jul 11, 10:00 AM CST** (End of Submissions).

---

## Control de scope
Cortá en este orden si falta tiempo:
1. Primero cae el **VLM de visión** (salud por foto) — lo más frágil.
2. Después el **self-heal con Horde** (mostrar en video sin cluster real de varios nodos; se puede simular con 2 nodos locales).
3. Después el **offline con Raspberry Pi** (mencionar en pitch sin implementar).
4. **Núcleo intocable:** sim/verifier + Sagents multi-agente con harness + RLVR (aunque chico) + `until_tool` + HITL + LiveView con la cascada en vivo + Gemma self-hosteado. Ese combo es el perfil ganador de ACT I, subido de nivel.

---

## Criterios de juicio (Track 3 Unicorn — jurado humano)
1. **Creativity & Originality** — comportamientos nuevos → self-heal + cascada emergente + integración de 4 organismos.
2. **Product/Market Potential** — pitch de startup → seguridad alimentaria proteica LatAm, costo por familia.
3. **Completeness** — CRÍTICO: que TODO corra de punta a punta. Completitud > sofisticación.
4. **Use of AMD Platforms** → Gemma self-hosteado en vLLM/ROCm + RLVR sobre ROCm. Uso profundo, no solo API.

## Requisitos duros de submission (o descalifican)
- Todo containerizado (Docker) · Repo GitHub público con README que corra · App ejecutable con las instrucciones · Original y MIT · Video + slides + cover image + demo URL en lablab.

## Acción inmediata
- ✅ Enrolled · ⬜ Crear equipo "ProteinLoop" (requiere conectar Discord en Settings → Connections del perfil lablab) · ⬜ Confirmar aprobación ADP (créditos AMD Cloud, 2-3 días).

---

## 📋 Contexto completo de la competencia (referencia)

### Datos generales
- **Evento:** AMD Developer Hackathon: ACT II — segunda edición (ACT I fue en mayo 2026).
- **Formato:** 100% online, en la plataforma lablab.ai. Todo corre en la nube — sin hardware local.
- **Fechas:** 6–11 julio 2026. Kick-off Jul 6, 10:00 AM CST. Fin de submissions Jul 11, 10:00 AM CST.
- **Prize pool total:** $21,000+.
- **Organizan:** AMD + lablab.ai (NativelyAI). Partners: Google DeepMind (Gemma 4), Fireworks AI, Native.Builder, theCUBE, NYSE Wired.
- **Tesis del evento:** construir AI agents y apps AI de alto rendimiento sobre GPUs AMD en la nube.

### Los tres tracks
- **Track 1 — Hybrid Token-Efficient Routing Agent** (⭐ beginner). Agente que completa tareas con la menor cantidad de tokens, decidiendo en runtime entre modelo local (cuenta 0) o remoto vía Fireworks. Scoring por leaderboard automático (token count + accuracy). Tareas reveladas en el kickoff.
- **Track 2 — Video Captioning** (🎬 beginner). Pipeline que genera captions en 4 estilos (formal, sarcástico, humor-tech, humor-no-tech) para clips de 30s–2min. Fine-tuning permitido. Scoring por LLM-Judge (accuracy + tono).
- **Track 3 — Unicorn Track** 🦄 (all levels) ← **EL NUESTRO**. "Tu idea. Infraestructura AMD. Sin benchmarks, sin restricciones — solo construí. Pensá pitch de startup, no benchmark run." Cualquier modelo open-source + AMD GPUs y/o Fireworks. **Juzgado por jueces humanos**, no leaderboard.

### Criterios de juicio del Unicorn Track (jurado humano)
1. **Creativity and Originality** — unicidad de la solución, enfoques novedosos y comportamientos nuevos.
2. **Product/Market Potential** — visión de startup, qué tan compelling y viable en un mercado real.
3. **Completeness** — qué tan realizado y funcional está el proyecto.
4. **Use of AMD Platforms** — qué tan significativamente se incorpora la infraestructura AMD.
(No hay criterio explícito de "profundidad de RL": la sofisticación suma a Originality, pero Completeness y Market pesan igual.)

### Premios (relevantes para nosotros)
- **Track 3 Unicorn:** 🥇 $2,500 · 🥈 $1,500 · 🥉 $1,000.
- **Gemma prize pool ($6,000 total, repartido en 3 tracks):** en el Track 3, **Best AMD-Hosted Gemma Project = $2,000**. (Track 1: $1,000 · Track 2: $3,000.)
- **Nuestro objetivo combinado:** 1er Unicorn ($2,500) + Best Gemma ($2,000) = **$4,500**.
- **Referral:** descartado (exige 100+ referidos aprobados; irreal).

### Tecnología y acceso
- **AMD Developer Cloud** — GPUs AMD Instinct on-demand para training, fine-tuning, deploy. Acceso vía AMD AI Developer Program (ADP).
- **ROCm** — plataforma GPU open-source de AMD (corre PyTorch/TensorFlow, porta CUDA).
- **Fireworks AI API** — acceso rápido a modelos sobre hardware AMD para inferencia/fine-tuning.
- **Gemma 4** (Google DeepMind, Apache 2.0) — accedido vía Fireworks + AMD Developer Cloud, sin sign-up separado; se paga con créditos Fireworks. Multimodal + razonamiento. Modelos a revelarse/confirmar por track en launch day.
- **Native.Builder** — entorno AI-native opcional para prototipar rápido con créditos Fireworks.

### Créditos (dos tipos, separados)
- **Hackathon credits:** $50 Fireworks AI para todos. Detalles de acceso a AMD GPU Cloud al iniciar el evento.
- **New member credits (solo nuevos ADP):** $100 AMD Developer Cloud + $50 Fireworks + 1 mes DeepLearning.AI Pro. **Aprobación manual de 2–3 días, aparte** — no atada al corte del hackathon.
- **Timing:** registro antes del 2 de julio → créditos día 1. Registro después del 2 → créditos desde el 7 de julio. (Nuestro caso: créditos desde el 7.)

### Qué se debe entregar (submission en lablab)
- Project Title · Short Description · Long Description · Technology/Category Tags.
- **Cover Image · Video Presentation · Slide Presentation.**
- **Public GitHub Repository** (con README de setup y uso).
- **Demo Application Platform · Application URL.**

### Requisitos duros (o descalifican)
- Todas las submissions **containerizadas (Docker)**.
- Repo GitHub **público** con README que corra.
- La app debe ser **ejecutable con las instrucciones provistas** (los jueces la corren).
- Submission **original y MIT-compliant**.
- Enviada por la plataforma lablab antes del deadline.

### Jueces/mentores notables (para calibrar audiencia)
Nick Ni (Sr Director AI Group, AMD), Ian Ballantyne (DevRel, Google DeepMind), Pawel Czech (CEO NativelyAI / fundador lablab), Andrei Kozlov (Principal Agentic Engineer, ENDGAME), + ingenieros de Amazon, Apple, Netflix, Oracle, Meta. Perfil técnico fuerte — valoran agentes reales y uso serio de la plataforma.

### Ganadores de ACT I (evidencia del patrón que gana)
- 🥇 **Chaos Economy** (TechMavericks) — simulación multi-agente con RL: 4 traders + market maker + regulador SEC, entrenados con **GRPO sobre Llama-3.2**, comportamiento emergente (crisis, colusión) sin scripts. Corrió en AMD Cloud + ROCm.
- Finalistas fuertes: CatalystMD (drug discovery agéntico), REPOMIND (coding agent en MI300X), ClinSight/CancerLens (AI clínico multi-agente multimodal), AtlasOps/SOCrates (agentes coordinados con human-in-the-loop).
- **Patrón ganador:** multi-agente + profundidad técnica real (RL/fine-tuning) + comportamiento emergente/verificable + corre de verdad en stack AMD + impacto claro. Casi todos fueron salud/finanzas/seguridad/dev-tools → **comida/seguridad alimentaria es territorio virgen.**

### Canales
- Discord lablab.ai (equipos, #looking-for-team, #ineedhelp) · Discord AMD (infra/GPU/ROCm/AI Academy).

---

## 🔗 URLs para research (las más recientes)

### Hackathon
- Página oficial ACT II: https://lablab.ai/ai-hackathons/amd-developer-hackathon-act-ii
- Recap ACT I (ganadores): https://lablab.ai/ai-hackathons/amd-developer

### Frameworks de agentes (Elixir)
- Sagents (elegido): https://github.com/sagents-ai/sagents
- Jido (alternativa OTP): https://github.com/agentjido/jido
- Jido AI (conector LLM): https://github.com/agentjido/jido_ai

### Gemma 4 + vLLM + ROCm (self-host)
- Receta oficial vLLM Gemma 4 (imagen `vllm-openai-rocm:gemma4`, comandos serve): https://docs.vllm.ai/projects/recipes/en/stable/Google/Gemma4.html
- vLLM inference en ROCm (docs AMD): https://rocm.docs.amd.com/en/latest/how-to/rocm-for-ai/inference/benchmark-docker/vllm.html
- vLLM V1 performance optimization (ROCm, TP/quantización): https://rocm.docs.amd.com/en/latest/how-to/rocm-for-ai/inference-optimization/vllm-optimization.html
- Blog AMD: desplegar Gemma con vLLM en Instinct MI300X (paso a paso): https://rocm.blogs.amd.com/artificial-intelligence/deployingGemma-vllm/README.html
- Gemma docs (Google): https://ai.google.dev/gemma/docs
- Fireworks AI docs (fallback / acceso rápido): https://docs.fireworks.ai

### AMD infra
- AMD AI Developer Program: https://www.amd.com/en/developer/resources/ai-developer.html
- ROCm docs: https://rocm.docs.amd.com/en/latest/
- ROCm GitHub: https://github.com/ROCm/ROCm

### RL / RLVR / GRPO (research)
- TRL (GRPO trainer, HuggingFace) — verificá la ruta exacta en el índice de docs: https://huggingface.co/docs/trl
- verl (RL framework escalable): https://github.com/volcengine/verl
- DeepSeek-R1 (RLVR razonamiento emergente): https://arxiv.org/abs/2501.12948
- DeepSeekMath (paper original de GRPO): https://arxiv.org/abs/2402.03300

### Elixir / Phoenix
- Phoenix LiveView docs: https://hexdocs.pm/phoenix_live_view
- Elixir LangChain: https://github.com/brainlid/langchain
- Horde (distribución/self-heal): https://github.com/derekkraan/horde

### Dominio (acuaponía + proteína)
- Atarraya Shrimpbox (camarón en contenedor con biofloc): https://atarraya.com
- FAO — Small-scale aquaponic food production (manual técnico 589, tilapia+catfish+DWC, cost-benefit): https://www.fao.org/3/i4021e/i4021e.pdf
