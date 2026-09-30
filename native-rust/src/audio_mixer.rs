/// Mixes two 32-bit float audio buffers together with per-track gain and soft-clipping protection.
pub fn mix_audio_buffers(track_a: &[f32], gain_a: f32, track_b: &[f32], gain_b: f32) -> Vec<f32> {
    let max_len = std::cmp::max(track_a.len(), track_b.len());
    let mut mixed = Vec::with_capacity(max_len);

    for i in 0..max_len {
        let sample_a = if i < track_a.len() { track_a[i] * gain_a } else { 0.0 };
        let sample_b = if i < track_b.len() { track_b[i] * gain_b } else { 0.0 };
        let combined = sample_a + sample_b;
        
        // Soft clipping / tanh approximation limiter to prevent harsh digital distortion
        let limited = if combined > 1.0 {
            1.0 - (-combined).exp() * 0.1
        } else if combined < -1.0 {
            -1.0 + combined.exp() * 0.1
        } else {
            combined
        };

        mixed.push(limited);
    }
    mixed
}

/// Applies smooth linear fade-in or fade-out to an audio buffer in-place.
pub fn apply_fade(buffer: &mut [f32], start_gain: f32, end_gain: f32) {
    let len = buffer.len();
    if len == 0 {
        return;
    }
    for (i, sample) in buffer.iter_mut().enumerate() {
        let t = i as f32 / len as f32;
        let gain = start_gain + t * (end_gain - start_gain);
        *sample *= gain;
    }
}
