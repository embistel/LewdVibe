import sys
import os
from faster_whisper import WhisperModel
import datetime

def format_timestamp(seconds: float):
    td = datetime.timedelta(seconds=seconds)
    total_seconds = int(td.total_seconds())
    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60
    secs = total_seconds % 60
    millis = int(td.microseconds / 1000)
    return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"

def generate_subtitles(video_path, output_path):
    print(f"Loading model 'large-v2' on CUDA...")
    model = WhisperModel("large-v2", device="cuda", compute_type="float16")
    
    print(f"Transcribing: {video_path}")
    # task="transcribe" for same language, "translate" for English translation.
    # User didn't specify, but usually Korean audio -> Korean text or JP/EN audio -> Korean translation?
    # For now, let's assume it detects language and transcribes it. 
    # If it is JP/EN and user wants Korean, they might need translate=True to English, but whisper doesn't translate to Korean directly well.
    # Actually, let's just do transcription.
    segments, info = model.transcribe(video_path, beam_size=5)
    
    print(f"Detected language '{info.language}' with probability {info.language_probability:.2f}")

    with open(output_path, "w", encoding="utf-8") as f:
        for i, segment in enumerate(segments, start=1):
            start = format_timestamp(segment.start)
            end = format_timestamp(segment.end)
            f.write(f"{i}\n")
            f.write(f"{start} --> {end}\n")
            f.write(f"{segment.text.strip()}\n\n")
            # Print progress every 10 segments
            if i % 10 == 0:
                print(f"Processed {i} segments... (last time: {end})")

    print(f"Successfully generated subtitles: {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python generate_subtitles.py <video_path> <output_path>")
        sys.exit(1)
    
    video_path = sys.argv[1]
    output_path = sys.argv[2]
    
    if not os.path.exists(video_path):
        print(f"Error: Video file not found: {video_path}")
        sys.exit(1)
        
    generate_subtitles(video_path, output_path)
