"""
Video Agent Module for Lucidia.

This module defines a VideoAgent class that can generate a simple video from a textual description. The agent uses a text-to-image model to create a sequence of frames based on the description and assembles them into a video file. The implementation relies on diffusers and OpenAI's CLIP model; please install the required dependencies (diffusers, transformers, accelerate, pillow, numpy, and opencv-python) before running.

Usage example:
    from lucidia.video_agent import VideoAgent
    agent = VideoAgent()
    agent.generate_video("A sunset over a calm ocean with gentle waves", output_path="sunset_video.mp4", num_frames=10, fps=4)
"""

from typing import List, Any
import os
from pathlib import Path
from dataclasses import dataclass

try:
    import torch
    from diffusers import StableDiffusionPipeline, EulerAncestralDiscreteScheduler
    from PIL import Image
    import numpy as np
    import cv2
except ImportError:
    # The heavy libraries are optional; if they're missing the agent will raise a helpful error at runtime.
    StableDiffusionPipeline = None
    EulerAncestralDiscreteScheduler = None
    torch = None
    Image = None
    np = None
    cv2 = None

@dataclass
class Frame:
    image: Any
    description: str

class VideoAgent:
    """
    A minimal agent that generates videos from text prompts.
    """
    def __init__(self, model_name: str = "runwayml/stable-diffusion-v1-5", device: str = None) -> None:
        """
        Initialize the VideoAgent with a text-to-image model.

        Args:
            model_name: Name of the pretrained model to load from Hugging Face.
            device: Optional device specifier ('cuda' or 'cpu'). If None, will auto-detect.
        """
        if StableDiffusionPipeline is None:
            raise ImportError(
                "VideoAgent requires diffusers, transformers, accelerate, pillow, numpy, and opencv-python packages. "
                "Install them with: pip install diffusers transformers accelerate pillow numpy opencv-python"
            )
        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")
        # Load the diffusion pipeline
        self.pipe = StableDiffusionPipeline.from_pretrained(
            model_name,
            torch_dtype=torch.float16 if self.device == "cuda" else torch.float32
        )
        self.pipe.scheduler = EulerAncestralDiscreteScheduler.from_config(self.pipe.scheduler.config)
        self.pipe = self.pipe.to(self.device)

    def _generate_frame(self, prompt: str, guidance_scale: float = 7.5) -> Frame:
        """
        Generate a single image frame for the given prompt.

        Args:
            prompt: Text describing the desired frame.
            guidance_scale: How strongly the model should follow the text prompt.

        Returns:
            A Frame containing the PIL image and the prompt used.
        """
        image = self.pipe(prompt, guidance_scale=guidance_scale).images[0]
        return Frame(image=image, description=prompt)

    def generate_frames(self, description: str, num_frames: int = 8) -> List[Frame]:
        """
        Break down a description into multiple prompts and generate a list of frames.

        The current implementation simply repeats the description for each frame. For more complex videos,
        consider splitting the description into a storyboard or keyframe prompts.

        Args:
            description: The narrative description for the entire video.
            num_frames: Number of frames to generate.

        Returns:
            A list of Frame objects.
        """
        prompts = [description for _ in range(num_frames)]
        frames = [self._generate_frame(prompt) for prompt in prompts]
        return frames

    def compile_video(self, frames: List[Frame], output_path: str, fps: int = 4) -> None:
        """
        Compile a sequence of frames into an MP4 video.

        Args:
            frames: List of Frame objects to include in the video.
            output_path: Path to the output video file.
            fps: Frames per second for the resulting video.
        """
        if cv2 is None:
            raise ImportError(
                "OpenCV is required to compile videos. Install it with: pip install opencv-python"
            )
        # Convert PIL images to numpy arrays and then to BGR for OpenCV
        frame_arrays = [cv2.cvtColor(np.array(frame.image), cv2.COLOR_RGB2BGR) for frame in frames]
        height, width, _ = frame_arrays[0].shape
        os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
        out = cv2.VideoWriter(output_path, cv2.VideoWriter_fourcc(*"mp4v"), fps, (width, height))
        for frame_array in frame_arrays:
            out.write(frame_array)
        out.release()

    def generate_video(self, description: str, output_path: str, num_frames: int = 8, fps: int = 4, guidance_scale: float = 7.5) -> None:
        """
        Generate a video from a text description and save it to a file.

        Args:
            description: The overall narrative description for the video.
            output_path: File path where the video will be saved.
            num_frames: Number of frames to generate.
            fps: Frames per second for the resulting video.
            guidance_scale: Guidance scale for the diffusion model.
        """
        frames = []
        for _ in range(num_frames):
            frames.append(self._generate_frame(description, guidance_scale=guidance_scale))
        self.compile_video(frames, output_path, fps=fps)
