const fs = require('fs');
const path = require('path');

const SAMPLE_RATE = 44100;

function createWavHeader(numSamples, sampleRate = SAMPLE_RATE, bitsPerSample = 16, numChannels = 1) {
  const blockAlign = numChannels * (bitsPerSample / 8);
  const byteRate = sampleRate * blockAlign;
  const dataSize = numSamples * blockAlign;
  const chunkSize = 36 + dataSize;

  const header = Buffer.alloc(44);
  header.write('RIFF', 0);
  header.writeUInt32LE(chunkSize, 4);
  header.write('WAVE', 8);
  header.write('fmt ', 12);
  header.writeUInt32LE(16, 16); // Subchunk1Size
  header.writeUInt16LE(1, 20);  // AudioFormat (1 = PCM)
  header.writeUInt16LE(numChannels, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(byteRate, 28);
  header.writeUInt16LE(blockAlign, 32);
  header.writeUInt16LE(bitsPerSample, 34);
  header.write('data', 36);
  header.writeUInt32LE(dataSize, 40);
  return header;
}

function writeWavFile(filename, samples) {
  const header = createWavHeader(samples.length);
  const data = Buffer.alloc(samples.length * 2);
  
  for (let i = 0; i < samples.length; i++) {
    // Clamp to 16-bit signed integer range
    let val = Math.max(-32768, Math.min(32767, Math.round(samples[i])));
    data.writeInt16LE(val, i * 2);
  }
  
  const dir = path.dirname(filename);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  
  fs.writeFileSync(filename, Buffer.concat([header, data]));
  console.log(`Saved: ${filename} (${samples.length} samples)`);
}

// 1. LASER: Sweep descendente rápido
function generateLaser() {
  const duration = 0.2; // 200 ms
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  
  let phase = 0;
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const progress = t / duration;
    // Varredura de 900Hz para 150Hz
    const freq = 900 - 750 * progress;
    phase += (2 * Math.PI * freq) / SAMPLE_RATE;
    
    // Envelope para suavizar o início e fim
    const envelope = Math.sin(progress * Math.PI) * Math.exp(-progress * 2);
    samples[i] = Math.sin(phase) * envelope * 0.4 * 32767;
  }
  return samples;
}

// 2. EXPLOSION: Ruído branco com decaimento
function generateExplosion() {
  const duration = 0.5; // 500 ms
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const progress = t / duration;
    // Ruído aleatório
    const noise = Math.random() * 2 - 1;
    // Envelope exponencial rápido
    const envelope = Math.exp(-t * 9) * (1 - progress);
    samples[i] = noise * envelope * 0.5 * 32767;
  }
  return samples;
}

// 3. HIT: Som de impacto metálico curto
function generateHit() {
  const duration = 0.12; // 120 ms
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  
  let phase = 0;
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const progress = t / duration;
    const freq = 300 - 200 * progress;
    phase += (2 * Math.PI * freq) / SAMPLE_RATE;
    // Mistura de senoide metálica rápida com um pouco de ruído
    const sine = Math.sin(phase);
    const noise = Math.random() * 2 - 1;
    const envelope = Math.exp(-t * 25);
    samples[i] = (sine * 0.7 + noise * 0.3) * envelope * 0.5 * 32767;
  }
  return samples;
}

// 4. COLLECT: Arpejo ascendente de 3 notas
function generateCollect() {
  const duration = 0.35; // 350 ms
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  
  // Notas: C5 (523Hz), E5 (659Hz), G5 (784Hz)
  const freqs = [523.25, 659.25, 783.99];
  let phase = 0;
  
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const noteIndex = Math.min(2, Math.floor((t / duration) * 3));
    const freq = freqs[noteIndex];
    phase += (2 * Math.PI * freq) / SAMPLE_RATE;
    
    // Envelope global e local por nota
    const noteProgress = ((t / duration) * 3) % 1;
    const localEnvelope = Math.sin(noteProgress * Math.PI) * Math.exp(-noteProgress * 1.5);
    const globalEnvelope = 1.0 - (t / duration) * 0.3;
    
    samples[i] = Math.sin(phase) * localEnvelope * globalEnvelope * 0.35 * 32767;
  }
  return samples;
}

// 5. ENGINE: Som contínuo grave e abafado
function generateEngine() {
  const duration = 0.5; // 500 ms (bom para loop)
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  
  let phase = 0;
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    // Motor básico a 65Hz com harmônico em 130Hz
    const freq1 = 65;
    const freq2 = 130;
    phase += (2 * Math.PI * freq1) / SAMPLE_RATE;
    
    const wave = Math.sin(phase) + 0.4 * Math.sin(phase * 2);
    // Adiciona um pouco de ruído de combustão filtrado
    const noise = Math.random() * 2 - 1;
    samples[i] = (wave * 0.85 + noise * 0.15) * 0.25 * 32767;
  }
  return samples;
}

// 6. MUSIC: Trilha espacial / Drone atmosférico em loop (Cmaj7)
function generateMusic() {
  const duration = 8.0; // 8 segundos
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);
  
  // Notas: C2 (65.4Hz), G2 (98.0Hz), C3 (130.8Hz), E3 (164.8Hz), G3 (196.0Hz), B3 (246.9Hz)
  const baseFreqs = [65.41, 97.99, 130.81, 164.81, 196.00, 246.94];
  const numVoices = baseFreqs.length;
  const phases = new Float32Array(numVoices);
  
  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    const progress = t / duration;
    
    let mixedSample = 0;
    
    for (let v = 0; v < numVoices; v++) {
      const freq = baseFreqs[v];
      phases[v] += (2 * Math.PI * freq) / SAMPLE_RATE;
      
      // LFO lento para variação de volume de cada nota (frequências de LFO diferentes)
      const lfoFreq = 0.1 + v * 0.07; // 0.1Hz, 0.17Hz, 0.24Hz...
      const lfo = 0.5 + 0.5 * Math.sin(2 * Math.PI * lfoFreq * t);
      
      mixedSample += Math.sin(phases[v]) * lfo;
    }
    
    // Normalizar
    mixedSample /= numVoices;
    
    // Fade-in e Fade-out nas pontas para evitar cliques no loop de 8 segundos
    let fade = 1.0;
    if (t < 0.5) {
      fade = t / 0.5;
    } else if (t > duration - 0.5) {
      fade = (duration - t) / 0.5;
    }
    
    samples[i] = mixedSample * fade * 0.3 * 32767;
  }
  return samples;
}

// Main execution
const targetDir = path.join(__dirname, 'assets', 'sounds');

console.log('Generating game audio assets...');
writeWavFile(path.join(targetDir, 'laser.wav'), generateLaser());
writeWavFile(path.join(targetDir, 'explosion.wav'), generateExplosion());
writeWavFile(path.join(targetDir, 'hit.wav'), generateHit());
writeWavFile(path.join(targetDir, 'collect.wav'), generateCollect());
writeWavFile(path.join(targetDir, 'engine.wav'), generateEngine());
writeWavFile(path.join(targetDir, 'music.wav'), generateMusic());
console.log('Audio synthesis completed!');
