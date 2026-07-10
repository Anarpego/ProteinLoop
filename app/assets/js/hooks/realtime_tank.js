import * as THREE from "three"
import {RoomEnvironment} from "three/addons/environments/RoomEnvironment.js"
import {GLTFLoader} from "three/addons/loaders/GLTFLoader.js"

const CLEAN_WATER = new THREE.Color(0x63c9dc)
const WARNING_WATER = new THREE.Color(0x72b7a4)
const DANGER_WATER = new THREE.Color(0xb78242)
const CLEAN_BACKGROUND = new THREE.Color(0xd9ecec)
const DANGER_BACKGROUND = new THREE.Color(0xf4e4c4)
const CLEAN_GLASS = new THREE.Color(0xe8fbfb)
const DANGER_GLASS = new THREE.Color(0xf1d8ae)
const FISH_MODEL_URL = "/models/barramundi-fish.glb"
const PRAWN_TEXTURE_URL = "/models/greasyback-shrimp.jpeg"

const clamp = (value, minimum, maximum) => Math.min(maximum, Math.max(minimum, value))
const mix = (from, to, amount) => from + (to - from) * amount
const angleDifference = (from, to) => Math.atan2(Math.sin(to - from), Math.cos(to - from))

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
  shape.moveTo(0.08, 0)
  shape.bezierCurveTo(-0.2, 0.08, -0.42, 0.38, -0.62, 0.4)
  shape.bezierCurveTo(-0.52, 0.13, -0.52, -0.13, -0.62, -0.4)
  shape.bezierCurveTo(-0.38, -0.34, -0.18, -0.08, 0.08, 0)
  shape.closePath()
  return new THREE.ShapeGeometry(shape)
}

const makeFish = (index, palette) => {
  const group = new THREE.Group()
  const fallback = new THREE.Group()
  const bodyMaterial = new THREE.MeshPhysicalMaterial({
    color: palette[index % palette.length],
    roughness: 0.38,
    metalness: 0.02,
    clearcoat: 0.32,
    clearcoatRoughness: 0.28,
    emissive: 0x102a32,
    emissiveIntensity: 0.02,
  })
  const finMaterial = new THREE.MeshPhysicalMaterial({
    color: palette[index % palette.length],
    roughness: 0.48,
    clearcoat: 0.18,
    transparent: true,
    opacity: 0.72,
    side: THREE.DoubleSide,
  })

  const body = new THREE.Mesh(new THREE.SphereGeometry(0.38, 32, 20), bodyMaterial)
  body.scale.set(1.55, 0.68, 0.42)
  body.castShadow = true
  fallback.add(body)

  const tail = new THREE.Mesh(finGeometry(), finMaterial)
  tail.scale.set(0.62, 0.62, 0.62)
  tail.position.set(-0.56, 0, 0)
  tail.castShadow = true
  fallback.add(tail)

  const topFin = new THREE.Mesh(finGeometry(), finMaterial)
  topFin.scale.set(0.3, 0.22, 0.3)
  topFin.position.set(-0.08, 0.25, 0)
  topFin.rotation.z = -Math.PI / 2
  topFin.castShadow = true
  fallback.add(topFin)

  const pectoralFin = new THREE.Mesh(finGeometry(), finMaterial)
  pectoralFin.scale.set(0.25, 0.18, 0.25)
  pectoralFin.position.set(0.12, -0.05, 0.16)
  pectoralFin.rotation.set(0.35, -0.2, -0.35)
  fallback.add(pectoralFin)

  const eyeMaterial = new THREE.MeshBasicMaterial({color: 0x071b24})
  const eyeWhite = new THREE.Mesh(
    new THREE.SphereGeometry(0.045, 14, 10),
    new THREE.MeshPhysicalMaterial({color: 0xdde7e3, roughness: 0.18, clearcoat: 0.8}),
  )
  eyeWhite.position.set(0.39, 0.09, 0.15)
  fallback.add(eyeWhite)

  const eye = new THREE.Mesh(new THREE.SphereGeometry(0.022, 10, 8), eyeMaterial)
  eye.position.set(0.407, 0.09, 0.188)
  fallback.add(eye)

  group.add(fallback)

  group.userData = {
    phase: index * 1.37,
    speed: 0.32 + seededRandom(index + 4) * 0.16,
    level: -0.95 + seededRandom(index + 13) * 2.05,
    depth: -0.72 + seededRandom(index + 22) * 1.35,
    heading: 0,
    fallback,
    tail,
    bodyMaterial,
  }

  return group
}

const disposeObject3D = root => {
  const geometries = new Set()
  const materials = new Set()
  const textures = new Set()

  root?.traverse(object => {
    if (object.geometry) geometries.add(object.geometry)
    const objectMaterials = Array.isArray(object.material) ? object.material : [object.material]
    objectMaterials.filter(Boolean).forEach(item => {
      materials.add(item)
      Object.values(item).forEach(value => {
        if (value?.isTexture) textures.add(value)
      })
    })
  })

  geometries.forEach(geometry => geometry.dispose())
  materials.forEach(item => item.dispose())
  textures.forEach(texture => texture.dispose())
}

const loadPBRFish = async runtime => {
  try {
    const loader = new GLTFLoader()
    const gltf = await loader.loadAsync(runtime.element.dataset.fishModelUrl || FISH_MODEL_URL)

    if (runtime.disposed) {
      disposeObject3D(gltf.scene)
      return
    }

    const bounds = new THREE.Box3().setFromObject(gltf.scene)
    const size = bounds.getSize(new THREE.Vector3())
    const center = bounds.getCenter(new THREE.Vector3())
    const modelScale = 1.5 / Math.max(size.x, size.y, size.z)

    runtime.fish.forEach(fish => {
      const model = gltf.scene.clone(true)
      model.position.sub(center)
      const visual = new THREE.Group()
      visual.rotation.y = Math.PI / 2
      visual.scale.setScalar(modelScale)
      visual.add(model)
      visual.traverse(object => {
        if (!object.isMesh) return
        object.castShadow = true
        object.receiveShadow = true
      })

      fish.userData.fallback.visible = false
      fish.userData.modelVisual = visual
      fish.add(visual)
    })

    runtime.fishTemplate = gltf.scene
    runtime.element.dataset.fishModelReady = "true"
  } catch (error) {
    if (runtime.disposed) return
    runtime.element.dataset.fishModelError = "true"
    console.warn("ProteinLoop PBR fish model could not load; using procedural fish", error)
  }
}

const makePrawnVisualMaterial = texture => new THREE.ShaderMaterial({
  uniforms: {
    prawnMap: {value: texture},
  },
  vertexShader: `
    varying vec2 vPrawnUv;

    void main() {
      vPrawnUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: `
    uniform sampler2D prawnMap;
    varying vec2 vPrawnUv;

    void main() {
      vec2 imageUv = vec2(
        mix(0.035, 0.94, vPrawnUv.x),
        mix(0.13, 0.9, vPrawnUv.y)
      );
      vec4 sampled = texture2D(prawnMap, imageUv);
      float brightness = max(sampled.r, max(sampled.g, sampled.b));
      float alpha = smoothstep(0.018, 0.09, brightness);
      if (alpha < 0.02) discard;
      gl_FragColor = vec4(sampled.rgb * 1.04, alpha * 0.96);
    }
  `,
  transparent: true,
  depthWrite: false,
  side: THREE.DoubleSide,
})

const loadPrawnVisual = async runtime => {
  try {
    const texture = await new THREE.TextureLoader().loadAsync(
      runtime.element.dataset.prawnTextureUrl || PRAWN_TEXTURE_URL,
    )
    texture.colorSpace = THREE.SRGBColorSpace
    texture.anisotropy = Math.min(8, runtime.renderer.capabilities.getMaxAnisotropy())

    if (runtime.disposed) {
      texture.dispose()
      return
    }

    const geometry = new THREE.PlaneGeometry(1.55, 0.68)
    const visualMaterial = makePrawnVisualMaterial(texture)

    runtime.prawns.forEach(prawn => {
      const visual = new THREE.Mesh(geometry, visualMaterial)
      visual.position.set(0, 0.2, 0.12)
      visual.rotation.y = Math.PI
      visual.renderOrder = 4
      prawn.userData.fallback.visible = false
      prawn.userData.photoVisual = visual
      prawn.add(visual)
    })

    runtime.prawnTexture = texture
    runtime.element.dataset.prawnVisualReady = "true"
  } catch (error) {
    if (runtime.disposed) return
    runtime.element.dataset.prawnVisualError = "true"
    console.warn("ProteinLoop realistic prawn visual could not load; using procedural prawns", error)
  }
}

const lineFromPoints = (points, color, opacity = 1) => new THREE.Line(
  new THREE.BufferGeometry().setFromPoints(points),
  new THREE.LineBasicMaterial({color, transparent: opacity < 1, opacity}),
)

const makePrawn = index => {
  const group = new THREE.Group()
  const shellMaterial = new THREE.MeshPhysicalMaterial({
    color: index % 2 === 0 ? 0xa86745 : 0xb87850,
    roughness: 0.36,
    metalness: 0,
    clearcoat: 0.45,
    clearcoatRoughness: 0.22,
    transparent: true,
    opacity: 0.9,
    transmission: 0.04,
    thickness: 0.12,
    emissive: 0x2d1008,
    emissiveIntensity: 0.02,
  })

  for (let segment = 0; segment < 7; segment += 1) {
    const shell = new THREE.Mesh(new THREE.SphereGeometry(0.12, 18, 12), shellMaterial)
    shell.scale.set(1.25 - segment * 0.07, 0.72, 0.68)
    shell.position.set(0.3 - segment * 0.145, 0.02 + Math.sin(segment * 0.55) * 0.045, 0)
    shell.castShadow = true
    group.add(shell)
  }

  const head = new THREE.Mesh(new THREE.SphereGeometry(0.17, 20, 14), shellMaterial)
  head.scale.set(1.28, 0.84, 0.76)
  head.position.set(0.44, 0.08, 0)
  head.castShadow = true
  group.add(head)

  const rostrum = new THREE.Mesh(
    new THREE.ConeGeometry(0.045, 0.32, 10),
    new THREE.MeshPhysicalMaterial({
      color: 0xc08b68,
      roughness: 0.3,
      clearcoat: 0.35,
      transparent: true,
      opacity: 0.84,
    }),
  )
  rostrum.rotation.z = -Math.PI / 2
  rostrum.position.set(0.69, 0.11, 0)
  group.add(rostrum)

  const eyeMaterial = new THREE.MeshBasicMaterial({color: 0x17202a})
  for (const z of [-0.12, 0.12]) {
    const stalk = new THREE.Mesh(
      new THREE.CylinderGeometry(0.012, 0.016, 0.15, 8),
      shellMaterial,
    )
    stalk.rotation.z = -0.35
    stalk.position.set(0.54, 0.17, z * 0.72)
    group.add(stalk)

    const eye = new THREE.Mesh(new THREE.SphereGeometry(0.027, 12, 8), eyeMaterial)
    eye.position.set(0.57, 0.24, z * 0.78)
    group.add(eye)

    const antenna = lineFromPoints([
      new THREE.Vector3(0.59, 0.2, z * 0.72),
      new THREE.Vector3(1.0, 0.38 + z * 0.35, z * 1.5),
      new THREE.Vector3(1.36, 0.27 + z * 0.5, z * 2.1),
    ], 0x8f513a, 0.72)
    group.add(antenna)
  }

  for (let leg = 0; leg < 5; leg += 1) {
    const x = 0.28 - leg * 0.17
    for (const z of [-0.09, 0.09]) {
      group.add(lineFromPoints([
        new THREE.Vector3(x, -0.06, z),
        new THREE.Vector3(x + 0.05, -0.22, z * 2.0),
      ], 0x97553c, 0.72))
    }
  }

  const tailMaterial = new THREE.MeshPhysicalMaterial({
    color: 0xbc7951,
    side: THREE.DoubleSide,
    roughness: 0.42,
    clearcoat: 0.25,
    transparent: true,
    opacity: 0.8,
  })
  for (const rotation of [-0.45, 0, 0.45]) {
    const fan = new THREE.Mesh(finGeometry(), tailMaterial)
    fan.scale.set(0.32, 0.2, 0.32)
    fan.position.set(-0.66, 0.07, 0)
    fan.rotation.x = rotation
    group.add(fan)
  }

  const fallback = new THREE.Group()
  for (const child of [...group.children]) fallback.add(child)
  group.add(fallback)

  group.userData = {
    phase: index * 1.83,
    speed: 0.11 + seededRandom(index + 31) * 0.06,
    depth: 0.32 + seededRandom(index + 41) * 0.72,
    heading: 0,
    fallback,
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
  stem.castShadow = true
  plant.add(stem)

  for (let leafIndex = 0; leafIndex < 4; leafIndex += 1) {
    const leaf = new THREE.Mesh(new THREE.SphereGeometry(0.18, 14, 8), leafMaterial)
    leaf.scale.set(1.7, 0.45, 0.75)
    leaf.position.set((leafIndex % 2 === 0 ? -1 : 1) * 0.14, 0.35 + leafIndex * 0.22, 0)
    leaf.rotation.z = (leafIndex % 2 === 0 ? 1 : -1) * 0.48
    leaf.castShadow = true
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
  runtime.scene.fog = new THREE.Fog(CLEAN_BACKGROUND.clone(), 13, 32)

  runtime.camera = new THREE.PerspectiveCamera(36, 1, 0.1, 60)
  runtime.camera.position.set(0, 0.35, 11)
  runtime.camera.lookAt(0, 0.15, 0)

  const environmentScene = new RoomEnvironment()
  const environmentGenerator = new THREE.PMREMGenerator(runtime.renderer)
  runtime.environmentTarget = environmentGenerator.fromScene(environmentScene, 0.04)
  runtime.scene.environment = runtime.environmentTarget.texture
  environmentGenerator.dispose()
  disposeObject3D(environmentScene)

  runtime.scene.add(new THREE.HemisphereLight(0xf3fbfa, 0x365f63, 1.65))
  const sunlight = new THREE.DirectionalLight(0xfff8e7, 2.8)
  sunlight.position.set(-4.5, 7.5, 6.5)
  sunlight.castShadow = true
  sunlight.shadow.mapSize.set(1024, 1024)
  sunlight.shadow.camera.left = -6
  sunlight.shadow.camera.right = 6
  sunlight.shadow.camera.top = 5
  sunlight.shadow.camera.bottom = -4
  sunlight.shadow.bias = -0.0004
  runtime.scene.add(sunlight)
  const waterLight = new THREE.RectAreaLight(0xb8f2f2, 8.5, 8, 3)
  waterLight.position.set(0, 3.8, 2.8)
  waterLight.lookAt(0, -0.5, 0)
  runtime.scene.add(waterLight)

  const backdrop = new THREE.Mesh(
    new THREE.PlaneGeometry(9.4, 5.1),
    material(0xc8dcda, {roughness: 0.92}),
  )
  backdrop.position.set(0, -0.02, -1.78)
  backdrop.receiveShadow = true
  runtime.scene.add(backdrop)

  runtime.tank = new THREE.Group()
  runtime.scene.add(runtime.tank)

  runtime.waterMaterial = new THREE.MeshPhysicalMaterial({
    color: CLEAN_WATER.clone(),
    transparent: true,
    opacity: 0.24,
    roughness: 0.12,
    metalness: 0,
    transmission: 0.24,
    thickness: 1.2,
    ior: 1.333,
    attenuationColor: 0x7ccbd1,
    attenuationDistance: 5.5,
    side: THREE.BackSide,
    depthWrite: false,
  })
  const water = new THREE.Mesh(new THREE.BoxGeometry(8.4, 4.1, 3.15), runtime.waterMaterial)
  water.position.y = -0.02
  runtime.tank.add(water)

  const glassGeometry = new THREE.BoxGeometry(8.58, 4.32, 3.32)
  runtime.glassMaterial = new THREE.MeshPhysicalMaterial({
    color: 0xe8fbfb,
    roughness: 0.08,
    metalness: 0,
    transmission: 0.82,
    thickness: 0.08,
    ior: 1.45,
    transparent: true,
    opacity: 0.12,
    side: THREE.DoubleSide,
    depthWrite: false,
  })
  const glass = new THREE.Mesh(glassGeometry, runtime.glassMaterial)
  glass.renderOrder = 7
  runtime.tank.add(glass)

  const glassEdges = new THREE.LineSegments(
    new THREE.EdgesGeometry(glassGeometry),
    new THREE.LineBasicMaterial({color: 0x52777b, transparent: true, opacity: 0.42}),
  )
  glassEdges.renderOrder = 8
  runtime.tank.add(glassEdges)

  const floor = new THREE.Mesh(
    new THREE.BoxGeometry(8.5, 0.16, 3.2),
    material(0x514b42, {roughness: 0.96}),
  )
  floor.position.y = -2.12
  floor.receiveShadow = true
  runtime.tank.add(floor)

  const gravelGeometry = new THREE.DodecahedronGeometry(0.08, 0)
  const gravelMaterial = material(0x8c8070, {roughness: 1})
  const gravel = new THREE.InstancedMesh(gravelGeometry, gravelMaterial, 190)
  const matrix = new THREE.Matrix4()
  const gravelPalette = [0x71685c, 0x8f826e, 0x625d55, 0xa0927a, 0x4d5550]
  for (let index = 0; index < 190; index += 1) {
    const x = -4 + seededRandom(index + 100) * 8
    const z = -1.4 + seededRandom(index + 200) * 2.8
    const size = 0.45 + seededRandom(index + 300) * 1.15
    matrix.compose(
      new THREE.Vector3(x, -1.99 + seededRandom(index + 400) * 0.08, z),
      new THREE.Quaternion().setFromEuler(new THREE.Euler(0, seededRandom(index + 500) * Math.PI, 0)),
      new THREE.Vector3(size, size * 0.7, size),
    )
    gravel.setMatrixAt(index, matrix)
    gravel.setColorAt(index, new THREE.Color(gravelPalette[index % gravelPalette.length]))
  }
  gravel.instanceMatrix.needsUpdate = true
  gravel.instanceColor.needsUpdate = true
  gravel.castShadow = true
  gravel.receiveShadow = true
  runtime.tank.add(gravel)

  const rockGeometry = new THREE.DodecahedronGeometry(0.22, 1)
  for (let index = 0; index < 7; index += 1) {
    const rock = new THREE.Mesh(
      rockGeometry,
      material(index % 2 === 0 ? 0x65706a : 0x777168, {roughness: 0.98}),
    )
    rock.position.set(-3.35 + index * 1.12, -1.82, -0.95 + (index % 3) * 0.7)
    rock.scale.set(0.65 + seededRandom(index + 2100), 0.5 + seededRandom(index + 2200), 0.7)
    rock.rotation.set(0, seededRandom(index + 2300) * Math.PI, 0)
    rock.castShadow = true
    rock.receiveShadow = true
    runtime.tank.add(rock)
  }

  runtime.surfaceGeometry = new THREE.PlaneGeometry(8.3, 3.05, 32, 12)
  runtime.surfaceMaterial = new THREE.MeshPhysicalMaterial({
    color: 0xa7ecf2,
    transparent: true,
    opacity: 0.34,
    transmission: 0.38,
    roughness: 0.08,
    clearcoat: 0.55,
    clearcoatRoughness: 0.12,
    side: THREE.DoubleSide,
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
    new THREE.MeshPhysicalMaterial({
      color: 0x447b80,
      roughness: 0.24,
      metalness: 0.18,
      clearcoat: 0.38,
    }),
  )
  pipe.castShadow = true
  runtime.scene.add(pipe)

  const growBed = new THREE.Mesh(
    new THREE.BoxGeometry(5.2, 0.32, 1.0),
    material(0xc9d2ce, {roughness: 0.82}),
  )
  growBed.position.set(-0.65, 2.74, -1.55)
  growBed.castShadow = true
  growBed.receiveShadow = true
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
  const fishPalette = [0x718a83, 0x6c858d, 0x7f8d78, 0x8a8474, 0x637c84]
  for (let index = 0; index < 5; index += 1) {
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
  const fishScale = clamp(0.82 + runtime.visual.fishBiomass / 55, 0.9, 1.12)

  runtime.fish.forEach((fish, index) => {
    const data = fish.userData
    const pace = data.speed * (0.35 + oxygenFactor * 0.8) * (1 - distress * 0.35)
    const phase = time * pace + data.phase
    const x = Math.sin(phase) * (3.05 - (index % 3) * 0.2)
    const direction = Math.cos(phase) >= 0 ? 1 : -1
    const healthyLevel = data.level + Math.sin(time * 0.85 + data.phase) * 0.16
    const surfaceLevel = 1.48 + Math.sin(time * 1.4 + data.phase) * 0.09
    const y = mix(healthyLevel, surfaceLevel, clamp(distress * 0.9, 0, 1))
    const z = data.depth + Math.cos(time * 0.5 + data.phase) * 0.12
    const scale = fishScale * (0.86 + (index % 3) * 0.06)
    const targetHeading = direction > 0 ? 0 : Math.PI
    data.heading += angleDifference(data.heading, targetHeading) * 0.08

    fish.position.set(x, collapsed ? mix(y, -1.4, 0.55) : y, z)
    fish.scale.setScalar(scale)
    fish.rotation.y = data.heading
    fish.rotation.z = collapsed ? direction * 0.8 : Math.sin(time + data.phase) * 0.035
    data.tail.rotation.y = Math.sin(time * 7 * pace + data.phase) * (0.12 + oxygenFactor * 0.16)
    if (data.modelVisual) {
      data.modelVisual.rotation.y = Math.PI / 2 + Math.sin(time * 5 * pace + data.phase) * 0.035
    }
    data.bodyMaterial.emissiveIntensity = distress * 0.17
  })

  const prawnScale = clamp(0.84 + runtime.visual.prawnBiomass / 16, 0.92, 1.12)
  runtime.prawns.forEach((prawn, index) => {
    const data = prawn.userData
    const phase = time * data.speed * (0.4 + oxygenFactor) + data.phase
    const direction = Math.cos(phase) >= 0 ? 1 : -1
    const x = Math.sin(phase) * (2.65 - index * 0.18)
    const scale = prawnScale * (0.9 + index * 0.035)
    const targetHeading = direction > 0 ? 0 : Math.PI
    data.heading += angleDifference(data.heading, targetHeading) * 0.06
    const substrateLevel = -1.38 + (index % 2) * 0.08
    prawn.position.set(
      x,
      substrateLevel + Math.sin(time * 1.2 + data.phase) * 0.018,
      data.depth,
    )
    prawn.scale.setScalar(scale)
    prawn.rotation.y = data.heading + Math.sin(time * 0.4 + data.phase) * 0.035
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
  runtime.waterMaterial.opacity = 0.2 + ammoniaStress * 0.2
  runtime.surfaceMaterial.color.copy(runtime.waterMaterial.color).offsetHSL(0, 0.02, 0.12)
  runtime.glassMaterial.color.lerp(ammoniaStress > 0.5 ? DANGER_GLASS : CLEAN_GLASS, smoothing)
  runtime.scene.background.lerpColors(CLEAN_BACKGROUND, DANGER_BACKGROUND, ammoniaStress * 0.7)
  runtime.scene.fog.color.copy(runtime.scene.background)

  updateWaterSurface(runtime, time, Math.max(ammoniaStress, 1 - oxygenFactor))
  updateBubbles(runtime, delta, time, oxygenFactor)
  updateParticles(runtime, time, ammoniaStress)
  updateAnimals(runtime, time, oxygenFactor, ammoniaStress, runtime.visual.collapsed)
  updatePlants(runtime, time)

  const cameraX = runtime.pointer.x * 0.38
  const cameraY = 0.35 + runtime.pointer.y * 0.2
  runtime.camera.position.x = mix(runtime.camera.position.x, cameraX, 0.035)
  runtime.camera.position.y = mix(runtime.camera.position.y, cameraY, 0.035)
  runtime.camera.lookAt(0, 0.15, 0)

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
  runtime.disposed = true
  runtime.renderer?.setAnimationLoop(null)
  runtime.resizeObserver?.disconnect()
  runtime.mediaQuery?.removeEventListener?.("change", runtime.handleMotionChange)
  runtime.element?.removeEventListener("pointermove", runtime.handlePointerMove)
  runtime.element?.removeEventListener("pointerleave", runtime.handlePointerLeave)
  runtime.fullscreenButton?.removeEventListener("click", runtime.handleFullscreenClick)
  document.removeEventListener("fullscreenchange", runtime.handleFullscreenChange)
  document.removeEventListener("webkitfullscreenchange", runtime.handleFullscreenChange)

  disposeObject3D(runtime.scene)
  runtime.prawnTexture?.dispose()
  runtime.environmentTarget?.dispose()
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
        disposed: false,
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
      runtime.renderer.toneMappingExposure = 1.02
      runtime.renderer.shadowMap.enabled = true
      runtime.renderer.shadowMap.type = THREE.PCFSoftShadowMap

      buildTank(runtime)
      loadPBRFish(runtime)
      loadPrawnVisual(runtime)

      runtime.resize = () => {
        const bounds = canvas.parentElement.getBoundingClientRect()
        const width = Math.max(1, Math.round(bounds.width))
        const height = Math.max(1, Math.round(bounds.height))
        runtime.renderer.setSize(width, height, false)
        runtime.camera.aspect = width / height
        const verticalHalfAngle = THREE.MathUtils.degToRad(runtime.camera.fov * 0.5)
        const distanceForWidth = 5.1 / Math.tan(verticalHalfAngle) / runtime.camera.aspect
        const distanceForHeight = 3.5 / Math.tan(verticalHalfAngle)
        runtime.camera.position.z = Math.max(10.8, distanceForWidth, distanceForHeight)
        runtime.camera.updateProjectionMatrix()
      }
      runtime.resizeObserver = new ResizeObserver(runtime.resize)
      runtime.resizeObserver.observe(canvas.parentElement)
      runtime.resize()

      runtime.fullscreenButton = this.el.querySelector("[data-tank-fullscreen]")
      runtime.handleFullscreenChange = () => {
        const fullscreenElement = document.fullscreenElement || document.webkitFullscreenElement
        const isFullscreen = fullscreenElement === this.el
        const label = isFullscreen ? "Exit tank full screen" : "Open tank full screen"

        this.el.dataset.fullscreen = String(isFullscreen)
        runtime.fullscreenButton?.setAttribute("aria-pressed", String(isFullscreen))
        runtime.fullscreenButton?.setAttribute("aria-label", label)
        if (runtime.fullscreenButton) runtime.fullscreenButton.title = label
        runtime.resize()
      }
      runtime.handleFullscreenClick = async () => {
        const fullscreenElement = document.fullscreenElement || document.webkitFullscreenElement
        const isFullscreen = fullscreenElement === this.el

        try {
          if (isFullscreen) {
            const exitFullscreen = document.exitFullscreen || document.webkitExitFullscreen
            if (exitFullscreen) await exitFullscreen.call(document)
          } else {
            const requestFullscreen = this.el.requestFullscreen || this.el.webkitRequestFullscreen
            if (requestFullscreen) await requestFullscreen.call(this.el)
          }
        } catch (error) {
          this.el.dataset.fullscreenError = "true"
          console.warn("ProteinLoop tank could not change full-screen mode", error)
        }
      }
      runtime.fullscreenButton?.addEventListener("click", runtime.handleFullscreenClick)
      document.addEventListener("fullscreenchange", runtime.handleFullscreenChange)
      document.addEventListener("webkitfullscreenchange", runtime.handleFullscreenChange)
      runtime.handleFullscreenChange()

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
    const fullscreenButton = this.el.querySelector("[data-tank-fullscreen]")
    if (fullscreenButton !== this.runtime.fullscreenButton) {
      this.runtime.fullscreenButton?.removeEventListener("click", this.runtime.handleFullscreenClick)
      this.runtime.fullscreenButton = fullscreenButton
      this.runtime.fullscreenButton?.addEventListener("click", this.runtime.handleFullscreenClick)
    }
    this.runtime.handleFullscreenChange?.()

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
