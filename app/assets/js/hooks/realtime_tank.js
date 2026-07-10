import * as THREE from "three"

const CLEAN_WATER = new THREE.Color(0x63c9dc)
const WARNING_WATER = new THREE.Color(0x72b7a4)
const DANGER_WATER = new THREE.Color(0xb78242)
const CLEAN_BACKGROUND = new THREE.Color(0xdff5f7)
const DANGER_BACKGROUND = new THREE.Color(0xf4e4c4)

const clamp = (value, minimum, maximum) => Math.min(maximum, Math.max(minimum, value))
const mix = (from, to, amount) => from + (to - from) * amount

const seededRandom = seed => {
  const value = Math.sin(seed * 12.9898 + 78.233) * 43758.5453
  return value - Math.floor(value)
}

const numericData = (element, key, fallback) => {
  const value = Number.parseFloat(element.dataset[key])
  return Number.isFinite(value) ? value : fallback
}

const stateFromElement = element => ({
  ammonia: numericData(element, "ammonia", 0.35),
  oxygen: numericData(element, "oxygen", 6.8),
  fishBiomass: numericData(element, "fishBiomass", 12),
  prawnBiomass: numericData(element, "prawnBiomass", 2.5),
  plantBiomass: numericData(element, "plantBiomass", 5),
  duckweed: numericData(element, "duckweed", 3),
  collapsed: element.dataset.collapsed === "true",
  health: element.dataset.health || "stable",
})

const material = (color, options = {}) => new THREE.MeshStandardMaterial({
  color,
  roughness: 0.55,
  metalness: 0.02,
  ...options,
})

const finGeometry = () => {
  const shape = new THREE.Shape()
  shape.moveTo(0.05, 0)
  shape.lineTo(-0.55, 0.42)
  shape.lineTo(-0.5, -0.42)
  shape.closePath()
  return new THREE.ShapeGeometry(shape)
}

const makeFish = (index, palette) => {
  const group = new THREE.Group()
  const bodyMaterial = material(palette[index % palette.length], {
    emissive: 0x102a32,
    emissiveIntensity: 0.04,
  })
  const finMaterial = material(palette[index % palette.length], {
    transparent: true,
    opacity: 0.85,
    side: THREE.DoubleSide,
  })

  const body = new THREE.Mesh(new THREE.SphereGeometry(0.48, 24, 16), bodyMaterial)
  body.scale.set(1.5, 0.7, 0.52)
  group.add(body)

  const tail = new THREE.Mesh(finGeometry(), finMaterial)
  tail.position.set(-0.64, 0, 0)
  group.add(tail)

  const topFin = new THREE.Mesh(finGeometry(), finMaterial)
  topFin.scale.set(0.48, 0.48, 0.48)
  topFin.position.set(-0.05, 0.36, 0)
  topFin.rotation.z = -Math.PI / 2
  group.add(topFin)

  const eyeMaterial = new THREE.MeshBasicMaterial({color: 0x071b24})
  const eyeWhite = new THREE.Mesh(
    new THREE.SphereGeometry(0.075, 12, 8),
    new THREE.MeshBasicMaterial({color: 0xf8fafc}),
  )
  eyeWhite.position.set(0.43, 0.14, 0.39)
  group.add(eyeWhite)

  const eye = new THREE.Mesh(new THREE.SphereGeometry(0.035, 10, 8), eyeMaterial)
  eye.position.set(0.45, 0.14, 0.454)
  group.add(eye)

  group.userData = {
    phase: index * 1.37,
    speed: 0.42 + seededRandom(index + 4) * 0.22,
    level: -1.15 + seededRandom(index + 13) * 2.45,
    depth: -0.85 + seededRandom(index + 22) * 1.7,
    tail,
    bodyMaterial,
  }

  return group
}

const lineFromPoints = (points, color, opacity = 1) => new THREE.Line(
  new THREE.BufferGeometry().setFromPoints(points),
  new THREE.LineBasicMaterial({color, transparent: opacity < 1, opacity}),
)

const makePrawn = index => {
  const group = new THREE.Group()
  const shellMaterial = material(index % 2 === 0 ? 0xe8793e : 0xf19955, {
    roughness: 0.42,
    emissive: 0x3d1307,
    emissiveIntensity: 0.04,
  })

  for (let segment = 0; segment < 6; segment += 1) {
    const shell = new THREE.Mesh(new THREE.SphereGeometry(0.15, 16, 10), shellMaterial)
    shell.scale.set(1.2 - segment * 0.08, 0.78, 0.72)
    shell.position.set(0.35 - segment * 0.2, 0.03 + Math.sin(segment * 0.65) * 0.06, 0)
    group.add(shell)
  }

  const head = new THREE.Mesh(new THREE.SphereGeometry(0.22, 18, 12), shellMaterial)
  head.scale.set(1.15, 0.9, 0.82)
  head.position.set(0.48, 0.09, 0)
  group.add(head)

  const eyeMaterial = new THREE.MeshBasicMaterial({color: 0x17202a})
  for (const z of [-0.12, 0.12]) {
    const eye = new THREE.Mesh(new THREE.SphereGeometry(0.035, 10, 8), eyeMaterial)
    eye.position.set(0.62, 0.22, z)
    group.add(eye)

    const antenna = lineFromPoints([
      new THREE.Vector3(0.61, 0.2, z),
      new THREE.Vector3(1.05, 0.42 + z * 0.4, z * 1.8),
      new THREE.Vector3(1.4, 0.32 + z * 0.7, z * 2.4),
    ], 0xb4532a, 0.9)
    group.add(antenna)
  }

  for (let leg = 0; leg < 5; leg += 1) {
    const x = 0.28 - leg * 0.17
    for (const z of [-0.09, 0.09]) {
      group.add(lineFromPoints([
        new THREE.Vector3(x, -0.06, z),
        new THREE.Vector3(x + 0.06, -0.28, z * 2.2),
      ], 0xc75f32, 0.85))
    }
  }

  const tailMaterial = material(0xf6a45e, {side: THREE.DoubleSide})
  for (const rotation of [-0.45, 0, 0.45]) {
    const fan = new THREE.Mesh(finGeometry(), tailMaterial)
    fan.scale.set(0.42, 0.28, 0.42)
    fan.position.set(-0.78, 0.08, 0)
    fan.rotation.x = rotation
    group.add(fan)
  }

  group.userData = {
    phase: index * 1.83,
    speed: 0.16 + seededRandom(index + 31) * 0.09,
    depth: -0.95 + seededRandom(index + 41) * 1.7,
    shellMaterial,
  }

  return group
}

const addPlant = (runtime, parent, x, y, z, scale, hue) => {
  const plant = new THREE.Group()
  const stemMaterial = material(0x2f7d5d)
  const leafMaterial = material(hue, {side: THREE.DoubleSide})
  const stem = new THREE.Mesh(new THREE.CylinderGeometry(0.035, 0.055, 1.1, 8), stemMaterial)
  stem.position.y = 0.5
  plant.add(stem)

  for (let leafIndex = 0; leafIndex < 4; leafIndex += 1) {
    const leaf = new THREE.Mesh(new THREE.SphereGeometry(0.18, 14, 8), leafMaterial)
    leaf.scale.set(1.7, 0.45, 0.75)
    leaf.position.set((leafIndex % 2 === 0 ? -1 : 1) * 0.14, 0.35 + leafIndex * 0.22, 0)
    leaf.rotation.z = (leafIndex % 2 === 0 ? 1 : -1) * 0.48
    plant.add(leaf)
  }

  plant.position.set(x, y, z)
  plant.scale.setScalar(scale)
  runtime.plants.push(plant)
  parent.add(plant)
}

const buildTank = runtime => {
  runtime.scene = new THREE.Scene()
  runtime.scene.background = CLEAN_BACKGROUND.clone()
  runtime.scene.fog = new THREE.Fog(CLEAN_BACKGROUND.clone(), 18, 42)

  runtime.camera = new THREE.PerspectiveCamera(35, 1, 0.1, 60)
  runtime.camera.position.set(0, 0.65, 9.6)
  runtime.camera.lookAt(0, -0.1, 0)

  runtime.scene.add(new THREE.HemisphereLight(0xf7fdff, 0x356c73, 2.8))
  const sunlight = new THREE.DirectionalLight(0xffffff, 3.1)
  sunlight.position.set(-4, 7, 7)
  runtime.scene.add(sunlight)
  const waterLight = new THREE.PointLight(0x7dd3fc, 18, 12, 2)
  waterLight.position.set(3, 1, 3)
  runtime.scene.add(waterLight)

  runtime.tank = new THREE.Group()
  runtime.scene.add(runtime.tank)

  runtime.waterMaterial = new THREE.MeshPhysicalMaterial({
    color: CLEAN_WATER.clone(),
    transparent: true,
    opacity: 0.3,
    roughness: 0.18,
    metalness: 0,
    transmission: 0.14,
    thickness: 0.8,
    side: THREE.BackSide,
    depthWrite: false,
  })
  const water = new THREE.Mesh(new THREE.BoxGeometry(8.4, 4.1, 3.15), runtime.waterMaterial)
  water.position.y = -0.02
  runtime.tank.add(water)

  const glassGeometry = new THREE.BoxGeometry(8.55, 4.3, 3.3)
  const glassEdges = new THREE.LineSegments(
    new THREE.EdgesGeometry(glassGeometry),
    new THREE.LineBasicMaterial({color: 0x8ac7d0, transparent: true, opacity: 0.72}),
  )
  runtime.tank.add(glassEdges)

  const floor = new THREE.Mesh(
    new THREE.BoxGeometry(8.5, 0.16, 3.2),
    material(0x586b66, {roughness: 0.9}),
  )
  floor.position.y = -2.12
  runtime.tank.add(floor)

  const gravelGeometry = new THREE.DodecahedronGeometry(0.08, 0)
  const gravelMaterial = material(0x8c8070, {roughness: 1})
  const gravel = new THREE.InstancedMesh(gravelGeometry, gravelMaterial, 110)
  const matrix = new THREE.Matrix4()
  for (let index = 0; index < 110; index += 1) {
    const x = -4 + seededRandom(index + 100) * 8
    const z = -1.4 + seededRandom(index + 200) * 2.8
    const size = 0.55 + seededRandom(index + 300) * 0.9
    matrix.compose(
      new THREE.Vector3(x, -1.99 + seededRandom(index + 400) * 0.08, z),
      new THREE.Quaternion().setFromEuler(new THREE.Euler(0, seededRandom(index + 500) * Math.PI, 0)),
      new THREE.Vector3(size, size * 0.7, size),
    )
    gravel.setMatrixAt(index, matrix)
  }
  gravel.instanceMatrix.needsUpdate = true
  runtime.tank.add(gravel)

  runtime.surfaceGeometry = new THREE.PlaneGeometry(8.3, 3.05, 32, 12)
  runtime.surfaceMaterial = new THREE.MeshPhongMaterial({
    color: 0xa7ecf2,
    transparent: true,
    opacity: 0.48,
    side: THREE.DoubleSide,
    shininess: 110,
    depthWrite: false,
  })
  runtime.surface = new THREE.Mesh(runtime.surfaceGeometry, runtime.surfaceMaterial)
  runtime.surface.rotation.x = -Math.PI / 2
  runtime.surface.position.y = 2.05
  runtime.tank.add(runtime.surface)

  const pipeCurve = new THREE.CatmullRomCurve3([
    new THREE.Vector3(-4.1, 1.6, -1.7),
    new THREE.Vector3(-4.9, 2.6, -1.3),
    new THREE.Vector3(-2.5, 3.2, -1.2),
    new THREE.Vector3(0, 2.75, -1.3),
    new THREE.Vector3(3.7, 3.05, -1.3),
    new THREE.Vector3(4.1, 1.3, -1.6),
  ])
  const pipe = new THREE.Mesh(
    new THREE.TubeGeometry(pipeCurve, 72, 0.07, 10, false),
    material(0x3a7e83, {roughness: 0.35}),
  )
  runtime.scene.add(pipe)

  const growBed = new THREE.Mesh(
    new THREE.BoxGeometry(5.2, 0.32, 1.0),
    material(0xdee8df, {roughness: 0.85}),
  )
  growBed.position.set(-0.65, 2.74, -1.55)
  runtime.scene.add(growBed)

  runtime.plants = []
  addPlant(runtime, runtime.tank, -3.5, -1.88, -1.1, 0.82, 0x5fbf6d)
  addPlant(runtime, runtime.tank, -2.8, -1.88, -1.18, 1.02, 0x4cae63)
  addPlant(runtime, runtime.tank, 2.9, -1.88, -1.2, 0.75, 0x68bb75)
  addPlant(runtime, runtime.tank, 3.5, -1.88, -1.1, 0.9, 0x52a66a)
  for (let index = 0; index < 6; index += 1) {
    addPlant(runtime, runtime.scene, -2.8 + index * 0.88, 2.78, -1.5, 0.48, 0x4eaf62)
  }

  runtime.duckweedPatch = new THREE.Group()
  const duckweedGeometry = new THREE.CircleGeometry(0.12, 14)
  const duckweedMaterial = material(0x6fae45, {
    side: THREE.DoubleSide,
    roughness: 0.72,
  })
  for (let index = 0; index < 18; index += 1) {
    const leaf = new THREE.Mesh(duckweedGeometry, duckweedMaterial)
    leaf.rotation.x = -Math.PI / 2
    leaf.position.set(
      1.7 + seededRandom(index + 1600) * 2.1,
      2.1 + seededRandom(index + 1700) * 0.025,
      -1.05 + seededRandom(index + 1800) * 2.0,
    )
    leaf.scale.set(0.65 + seededRandom(index + 1900) * 0.7, 0.65, 1)
    runtime.duckweedPatch.add(leaf)
  }
  runtime.tank.add(runtime.duckweedPatch)

  runtime.fish = []
  const fishPalette = [0x0ea5a8, 0x2563a8, 0xe4a52d, 0xd95f59, 0x4f8d65, 0x6d70b3]
  for (let index = 0; index < 7; index += 1) {
    const fish = makeFish(index, fishPalette)
    runtime.fish.push(fish)
    runtime.tank.add(fish)
  }

  runtime.prawns = []
  for (let index = 0; index < 4; index += 1) {
    const prawn = makePrawn(index)
    runtime.prawns.push(prawn)
    runtime.tank.add(prawn)
  }

  const bubbleCount = 64
  const bubblePositions = new Float32Array(bubbleCount * 3)
  runtime.bubbleSeeds = []
  for (let index = 0; index < bubbleCount; index += 1) {
    const seed = {
      x: -3.65 + seededRandom(index + 700) * 7.3,
      y: -1.8 + seededRandom(index + 800) * 3.6,
      z: -1.15 + seededRandom(index + 900) * 2.3,
      speed: 0.45 + seededRandom(index + 1000) * 0.75,
      drift: seededRandom(index + 1100) * Math.PI * 2,
    }
    runtime.bubbleSeeds.push(seed)
    bubblePositions[index * 3] = seed.x
    bubblePositions[index * 3 + 1] = seed.y
    bubblePositions[index * 3 + 2] = seed.z
  }
  runtime.bubbleGeometry = new THREE.BufferGeometry()
  runtime.bubbleGeometry.setAttribute("position", new THREE.BufferAttribute(bubblePositions, 3))
  runtime.bubbles = new THREE.Points(
    runtime.bubbleGeometry,
    new THREE.PointsMaterial({
      color: 0xe8fbff,
      size: 0.095,
      transparent: true,
      opacity: 0.82,
      depthWrite: false,
      sizeAttenuation: true,
    }),
  )
  runtime.tank.add(runtime.bubbles)

  const particleCount = 90
  const particlePositions = new Float32Array(particleCount * 3)
  runtime.particleSeeds = []
  for (let index = 0; index < particleCount; index += 1) {
    const seed = {
      x: -3.9 + seededRandom(index + 1200) * 7.8,
      y: -1.7 + seededRandom(index + 1300) * 3.5,
      z: -1.3 + seededRandom(index + 1400) * 2.6,
      phase: seededRandom(index + 1500) * Math.PI * 2,
    }
    runtime.particleSeeds.push(seed)
    particlePositions[index * 3] = seed.x
    particlePositions[index * 3 + 1] = seed.y
    particlePositions[index * 3 + 2] = seed.z
  }
  runtime.particleGeometry = new THREE.BufferGeometry()
  runtime.particleGeometry.setAttribute("position", new THREE.BufferAttribute(particlePositions, 3))
  runtime.particleMaterial = new THREE.PointsMaterial({
    color: 0xc9792b,
    size: 0.045,
    transparent: true,
    opacity: 0,
    depthWrite: false,
  })
  runtime.particles = new THREE.Points(runtime.particleGeometry, runtime.particleMaterial)
  runtime.tank.add(runtime.particles)

  runtime.alertMaterial = new THREE.MeshBasicMaterial({
    color: 0xe64e3c,
    transparent: true,
    opacity: 0,
    side: THREE.DoubleSide,
    depthWrite: false,
  })
  runtime.alertRing = new THREE.Mesh(
    new THREE.RingGeometry(0.8, 0.88, 64),
    runtime.alertMaterial,
  )
  runtime.alertRing.position.set(0, 0, 1.7)
  runtime.alertRing.visible = false
  runtime.scene.add(runtime.alertRing)
}

const updateWaterSurface = (runtime, time, stress) => {
  const positions = runtime.surfaceGeometry.attributes.position
  for (let index = 0; index < positions.count; index += 1) {
    const x = positions.getX(index)
    const y = positions.getY(index)
    const wave = Math.sin(x * 1.2 + time * 1.4) * 0.035 + Math.cos(y * 1.8 + time) * 0.025
    positions.setZ(index, wave * (1 + stress * 1.8))
  }
  positions.needsUpdate = true
  runtime.surfaceGeometry.computeVertexNormals()
}

const updateBubbles = (runtime, delta, time, oxygenFactor) => {
  const positions = runtime.bubbleGeometry.attributes.position
  const visibleCount = Math.round(10 + oxygenFactor * (runtime.bubbleSeeds.length - 10))
  runtime.bubbleGeometry.setDrawRange(0, visibleCount)

  for (let index = 0; index < visibleCount; index += 1) {
    const seed = runtime.bubbleSeeds[index]
    let y = positions.getY(index) + delta * seed.speed * (0.45 + oxygenFactor)
    if (y > 1.95) y = -1.85 - seededRandom(index + Math.floor(time)) * 0.3
    positions.setXYZ(
      index,
      seed.x + Math.sin(time * 0.7 + seed.drift) * 0.08,
      y,
      seed.z + Math.cos(time * 0.55 + seed.drift) * 0.04,
    )
  }
  positions.needsUpdate = true
}

const updateParticles = (runtime, time, ammoniaStress) => {
  runtime.particleMaterial.opacity = ammoniaStress * 0.72
  const positions = runtime.particleGeometry.attributes.position
  for (let index = 0; index < runtime.particleSeeds.length; index += 1) {
    const seed = runtime.particleSeeds[index]
    positions.setXYZ(
      index,
      seed.x + Math.sin(time * 0.14 + seed.phase) * 0.12,
      seed.y + Math.cos(time * 0.18 + seed.phase) * 0.08,
      seed.z,
    )
  }
  positions.needsUpdate = true
}

const updateAnimals = (runtime, time, oxygenFactor, ammoniaStress, collapsed) => {
  const distress = collapsed ? 1 : Math.max(ammoniaStress, 1 - oxygenFactor)
  const fishScale = clamp(0.78 + runtime.visual.fishBiomass / 30, 0.82, 1.2)

  runtime.fish.forEach((fish, index) => {
    const data = fish.userData
    const pace = data.speed * (0.35 + oxygenFactor * 0.8) * (1 - distress * 0.35)
    const phase = time * pace + data.phase
    const x = Math.sin(phase) * (3.25 - (index % 3) * 0.18)
    const direction = Math.cos(phase) >= 0 ? 1 : -1
    const healthyLevel = data.level + Math.sin(time * 0.85 + data.phase) * 0.16
    const surfaceLevel = 1.48 + Math.sin(time * 1.4 + data.phase) * 0.09
    const y = mix(healthyLevel, surfaceLevel, clamp(distress * 0.9, 0, 1))
    const z = data.depth + Math.cos(time * 0.5 + data.phase) * 0.12
    const scale = fishScale * (0.88 + (index % 3) * 0.07)

    fish.position.set(x, collapsed ? mix(y, -1.4, 0.55) : y, z)
    fish.scale.set(direction * scale, scale, scale)
    fish.rotation.z = collapsed ? direction * 0.8 : Math.sin(time + data.phase) * 0.035
    data.tail.rotation.y = Math.sin(time * 7 * pace + data.phase) * (0.18 + oxygenFactor * 0.2)
    data.bodyMaterial.emissiveIntensity = distress * 0.17
  })

  const prawnScale = clamp(0.82 + runtime.visual.prawnBiomass / 12, 0.84, 1.18)
  runtime.prawns.forEach((prawn, index) => {
    const data = prawn.userData
    const phase = time * data.speed * (0.4 + oxygenFactor) + data.phase
    const direction = Math.cos(phase) >= 0 ? 1 : -1
    const x = Math.sin(phase) * (2.8 - index * 0.2)
    const scale = prawnScale * (0.84 + index * 0.06)
    prawn.position.set(x, -1.78 + Math.sin(time * 1.2 + data.phase) * 0.025, data.depth)
    prawn.scale.set(direction * scale, scale, scale)
    prawn.rotation.y = Math.sin(time * 0.4 + data.phase) * 0.08
    data.shellMaterial.emissiveIntensity = distress * 0.12
  })
}

const updatePlants = (runtime, time) => {
  const plantScale = clamp(0.75 + runtime.visual.plantBiomass / 20, 0.82, 1.15)
  runtime.plants.forEach((plant, index) => {
    const baseScale = plant.userData.baseScale || plant.scale.x
    plant.userData.baseScale = baseScale
    const sway = Math.sin(time * 0.72 + index) * 0.045
    plant.rotation.z = sway
    plant.scale.setScalar(baseScale * plantScale)
  })
  const duckweedScale = clamp(0.72 + runtime.visual.duckweed / 12, 0.78, 1.12)
  runtime.duckweedPatch.scale.setScalar(duckweedScale)
  runtime.duckweedPatch.position.y = Math.sin(time * 0.8) * 0.015
}

const renderFrame = (runtime, timeMilliseconds) => {
  const time = timeMilliseconds * 0.001
  const delta = clamp((timeMilliseconds - runtime.lastFrame) * 0.001 || 0.016, 0.001, 0.05)
  runtime.lastFrame = timeMilliseconds

  const smoothing = 1 - Math.exp(-delta * 2.8)
  for (const key of ["ammonia", "oxygen", "fishBiomass", "prawnBiomass", "plantBiomass", "duckweed"]) {
    runtime.visual[key] = mix(runtime.visual[key], runtime.target[key], smoothing)
  }
  runtime.visual.collapsed = runtime.target.collapsed

  const ammoniaStress = clamp((runtime.visual.ammonia - 1.1) / 3.4, 0, 1)
  const oxygenFactor = clamp((runtime.visual.oxygen - 2.6) / 4.2, 0, 1)
  const waterMix = clamp(ammoniaStress * 0.9 + (1 - oxygenFactor) * 0.16, 0, 1)
  const waterTarget = waterMix < 0.55
    ? new THREE.Color().lerpColors(CLEAN_WATER, WARNING_WATER, waterMix / 0.55)
    : new THREE.Color().lerpColors(WARNING_WATER, DANGER_WATER, (waterMix - 0.55) / 0.45)
  runtime.waterMaterial.color.lerp(waterTarget, smoothing)
  runtime.waterMaterial.opacity = 0.24 + ammoniaStress * 0.2
  runtime.surfaceMaterial.color.copy(runtime.waterMaterial.color).offsetHSL(0, 0.02, 0.12)
  runtime.scene.background.lerpColors(CLEAN_BACKGROUND, DANGER_BACKGROUND, ammoniaStress * 0.7)
  runtime.scene.fog.color.copy(runtime.scene.background)

  updateWaterSurface(runtime, time, Math.max(ammoniaStress, 1 - oxygenFactor))
  updateBubbles(runtime, delta, time, oxygenFactor)
  updateParticles(runtime, time, ammoniaStress)
  updateAnimals(runtime, time, oxygenFactor, ammoniaStress, runtime.visual.collapsed)
  updatePlants(runtime, time)

  const cameraX = runtime.pointer.x * 0.7
  const cameraY = 0.65 + runtime.pointer.y * 0.35
  runtime.camera.position.x = mix(runtime.camera.position.x, cameraX, 0.035)
  runtime.camera.position.y = mix(runtime.camera.position.y, cameraY, 0.035)
  runtime.camera.lookAt(0, -0.08, 0)

  if (runtime.alertEnergy > 0.01) {
    runtime.alertRing.visible = true
    runtime.alertEnergy *= Math.pow(0.17, delta)
    const ringScale = 1 + (1 - runtime.alertEnergy) * 4.5
    runtime.alertRing.scale.setScalar(ringScale)
    runtime.alertMaterial.opacity = runtime.alertEnergy * 0.55
  } else {
    runtime.alertRing.visible = false
  }

  runtime.renderer.render(runtime.scene, runtime.camera)
}

const disposeRuntime = runtime => {
  if (!runtime) return
  runtime.renderer?.setAnimationLoop(null)
  runtime.resizeObserver?.disconnect()
  runtime.mediaQuery?.removeEventListener?.("change", runtime.handleMotionChange)
  runtime.element?.removeEventListener("pointermove", runtime.handlePointerMove)
  runtime.element?.removeEventListener("pointerleave", runtime.handlePointerLeave)

  const geometries = new Set()
  const materials = new Set()
  runtime.scene?.traverse(object => {
    if (object.geometry) geometries.add(object.geometry)
    if (Array.isArray(object.material)) object.material.forEach(item => materials.add(item))
    else if (object.material) materials.add(object.material)
  })
  geometries.forEach(geometry => geometry.dispose())
  materials.forEach(item => item.dispose())
  runtime.renderer?.dispose()
  runtime.renderer?.forceContextLoss()
}

const RealtimeTank = {
  mounted() {
    const canvas = this.el.querySelector("[data-tank-canvas]")
    if (!canvas) return

    try {
      const initialState = stateFromElement(this.el)
      const runtime = {
        element: this.el,
        canvas,
        target: {...initialState},
        visual: {...initialState},
        pointer: {x: 0, y: 0},
        alertEnergy: 0,
        lastFrame: 0,
      }

      runtime.renderer = new THREE.WebGLRenderer({
        canvas,
        antialias: true,
        alpha: false,
        powerPreference: "high-performance",
      })
      runtime.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2))
      runtime.renderer.outputColorSpace = THREE.SRGBColorSpace
      runtime.renderer.toneMapping = THREE.ACESFilmicToneMapping
      runtime.renderer.toneMappingExposure = 1.08

      buildTank(runtime)

      runtime.resize = () => {
        const bounds = canvas.parentElement.getBoundingClientRect()
        const width = Math.max(1, Math.round(bounds.width))
        const height = Math.max(1, Math.round(bounds.height))
        runtime.renderer.setSize(width, height, false)
        runtime.camera.aspect = width / height
        const halfHorizontalScene = 4.65
        const verticalHalfAngle = THREE.MathUtils.degToRad(runtime.camera.fov * 0.5)
        const distanceForWidth = halfHorizontalScene / Math.tan(verticalHalfAngle) / runtime.camera.aspect
        runtime.camera.position.z = Math.max(9.6, distanceForWidth)
        runtime.camera.updateProjectionMatrix()
      }
      runtime.resizeObserver = new ResizeObserver(runtime.resize)
      runtime.resizeObserver.observe(canvas.parentElement)
      runtime.resize()

      runtime.handlePointerMove = event => {
        const bounds = this.el.getBoundingClientRect()
        runtime.pointer.x = clamp(((event.clientX - bounds.left) / bounds.width) * 2 - 1, -1, 1)
        runtime.pointer.y = clamp(-(((event.clientY - bounds.top) / bounds.height) * 2 - 1), -1, 1)
      }
      runtime.handlePointerLeave = () => {
        runtime.pointer.x = 0
        runtime.pointer.y = 0
      }
      this.el.addEventListener("pointermove", runtime.handlePointerMove)
      this.el.addEventListener("pointerleave", runtime.handlePointerLeave)

      runtime.mediaQuery = window.matchMedia("(prefers-reduced-motion: reduce)")
      runtime.reducedMotion = runtime.mediaQuery.matches
      runtime.handleMotionChange = event => { runtime.reducedMotion = event.matches }
      runtime.mediaQuery.addEventListener?.("change", runtime.handleMotionChange)

      runtime.animation = time => {
        if (runtime.reducedMotion && time - runtime.lastFrame < 120) return
        renderFrame(runtime, time)
      }
      runtime.renderer.setAnimationLoop(runtime.animation)
      renderFrame(runtime, performance.now())

      this.runtime = runtime
      this.el.dataset.rendererReady = "true"
      this.el.dataset.renderer = `three-${THREE.REVISION}`
    } catch (error) {
      this.el.dataset.rendererError = "true"
      console.error("ProteinLoop real-time tank could not start", error)
    }
  },

  updated() {
    if (!this.runtime) return
    const next = stateFromElement(this.el)
    const previous = this.runtime.target
    if (
      Math.abs(next.ammonia - previous.ammonia) > 0.25 ||
      Math.abs(next.oxygen - previous.oxygen) > 0.35 ||
      next.health !== previous.health
    ) {
      this.runtime.alertEnergy = 1
    }
    this.runtime.target = next
  },

  destroyed() {
    disposeRuntime(this.runtime)
    this.runtime = null
  },
}

export default RealtimeTank
