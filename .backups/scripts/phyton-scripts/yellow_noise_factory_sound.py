# yellow_noise_factory_sound.py
import numpy as np
from scipy.io import wavfile

print("Generating 'Yellow Noise Factory Sound'...")

# Parameters
duration = 60              # seconds
sample_rate = 44100        # Hz
t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)

# === 1. Base: Yellow Noise (High-Frequency Hiss - e.g., steam, vents) ===
white_noise = np.random.normal(0, 1, t.shape)
yellow_noise = np.diff(white_noise)
yellow_noise = np.append(yellow_noise, 0)
yellow_noise = yellow_noise / (np.max(np.abs(yellow_noise)) + 1e-6)

# Boost highs even more for "bright" industrial hiss
yellow_noise = np.clip(yellow_noise * 1.5, -1, 1)  # slight overdrive

# === 2. Add Low-Frequency Machinery Rumble (2–30 Hz) ===
rumble = (
    0.3 * np.sin(2 * np.pi * 5 * t) +           # big motor hum
    0.2 * np.sin(2 * np.pi * 12 * t + 0.3) +    # secondary gear
    0.1 * np.sin(2 * np.pi * 25 * t + 0.7)      # vibration
)
# Make it more "clicky" with random spikes (like metal stress)
stress_clicks = 0.2 * np.random.choice([0, 0, 0, 0, 0, 0, 0, 0.8], size=t.shape)
rumble_combined = 0.4 * rumble + 0.3 * stress_clicks

# === 3. Add Repetitive Mechanical Tick (Conveyor belt / piston) ===
piston_freq = 2.0  # Hz (every 0.5 seconds)
tick = np.sin(2 * np.pi * 150 * t)  # 150 Hz click
envelope = np.exp(-50 * (t % (1/piston_freq)) * sample_rate / 1000)  # decay
envelope = np.clip(envelope, 0, 0.6)  # limit
piston_sound = tick * envelope * 0.2

# === 4. Combine All Layers ===
# Scale each component
audio = (
    0.6 * yellow_noise +      # bright hiss (dominant high end)
    0.3 * rumble_combined +   # deep rumble
    0.15 * piston_sound       # rhythmic tick
)

# Normalize to max volume
audio = audio / np.max(np.abs(audio))

# Convert to 16-bit PCM
audio_int = (audio * 32767).astype(np.int16)

# Save as WAV
output_file = 'yellow_noise_factory_sound.wav'
wavfile.write(output_file, sample_rate, audio_int)

print(f"✅ Factory sound generated: {output_file}")
print("🔊 Play with: vlc yellow_noise_factory_sound.wav  or  mpv *.wav")
