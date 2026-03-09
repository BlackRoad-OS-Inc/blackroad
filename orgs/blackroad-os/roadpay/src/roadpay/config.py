"""
RoadPay Configuration
"""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings."""

    # Server
    host: str = "0.0.0.0"
    port: int = 8000
    debug: bool = False

    # Stripe
    stripe_secret_key: str = ""
    stripe_publishable_key: str = ""
    stripe_webhook_secret: str = ""

    # Redis (for caching)
    redis_url: str = "redis://localhost:6379"

    class Config:
        env_prefix = "ROADPAY_"
        env_file = ".env"


settings = Settings()
