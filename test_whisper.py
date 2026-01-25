from faster_whisper import WhisperModel

def test_cuda():
    print("Checking CUDA availability...")
    try:
        # Check torch just as a baseline for CUDA
        import torch
        print(f"Torch CUDA available: {torch.cuda.is_available()}")
        if torch.cuda.is_available():
            print(f"GPU Name: {torch.cuda.get_device_name(0)}")
    except ImportError:
        print("Torch not installed, skipping torch check.")

    print("\nAttempting to initialize Faster-Whisper with CUDA...")
    model_size = "tiny" # Use tiny for fast test
    try:
        # device="cuda" is the key part
        model = WhisperModel(model_size, device="cuda", compute_type="float16")
        print("Successfully initialized Faster-Whisper on GPU (CUDA)!")
    except Exception as e:
        print(f"Failed to use CUDA with Faster-Whisper: {e}")
        print("\nFallback to CPU test...")
        try:
            model = WhisperModel(model_size, device="cpu", compute_type="int8")
            print("Successfully initialized Faster-Whisper on CPU.")
        except Exception as e2:
            print(f"CPU initialization also failed: {e2}")

if __name__ == "__main__":
    test_cuda()
