"""
RoadFixture - Test Fixtures for BlackRoad
Create and manage test fixtures and factories.
"""

from dataclasses import dataclass, field
from typing import Any, Callable, Dict, Generic, List, Optional, Type, TypeVar
import functools
import random
import string
import uuid
import logging

logger = logging.getLogger(__name__)

T = TypeVar("T")


class FixtureError(Exception):
    pass


@dataclass
class FixtureConfig:
    scope: str = "function"  # function, class, module, session
    autouse: bool = False
    params: List[Any] = field(default_factory=list)


class Fixture:
    def __init__(self, func: Callable, config: FixtureConfig = None):
        self.func = func
        self.config = config or FixtureConfig()
        self.name = func.__name__
        self._cache: Dict[str, Any] = {}
        self._finalizers: List[Callable] = []

    def __call__(self, *args, **kwargs) -> Any:
        key = f"{self.config.scope}:{id(args)}"

        if self.config.scope != "function" and key in self._cache:
            return self._cache[key]

        result = self.func(*args, **kwargs)

        if self.config.scope != "function":
            self._cache[key] = result

        return result

    def add_finalizer(self, finalizer: Callable) -> None:
        self._finalizers.append(finalizer)

    def teardown(self) -> None:
        for finalizer in reversed(self._finalizers):
            try:
                finalizer()
            except Exception as e:
                logger.error(f"Finalizer error: {e}")
        self._finalizers.clear()
        self._cache.clear()


class FixtureManager:
    def __init__(self):
        self._fixtures: Dict[str, Fixture] = {}

    def register(self, func: Callable = None, *, scope: str = "function", autouse: bool = False, params: List = None) -> Callable:
        def decorator(f: Callable) -> Fixture:
            config = FixtureConfig(scope=scope, autouse=autouse, params=params or [])
            fixture = Fixture(f, config)
            self._fixtures[f.__name__] = fixture
            return fixture

        if func is not None:
            return decorator(func)
        return decorator

    def get(self, name: str) -> Optional[Fixture]:
        return self._fixtures.get(name)

    def get_value(self, name: str, **kwargs) -> Any:
        fixture = self.get(name)
        if fixture is None:
            raise FixtureError(f"Fixture '{name}' not found")
        return fixture(**kwargs)

    def teardown_all(self) -> None:
        for fixture in self._fixtures.values():
            fixture.teardown()


fixtures = FixtureManager()
fixture = fixtures.register


class Factory(Generic[T]):
    def __init__(self, model: Type[T]):
        self.model = model
        self._defaults: Dict[str, Any] = {}
        self._sequences: Dict[str, int] = {}
        self._lazy: Dict[str, Callable] = {}

    def set_default(self, **kwargs) -> "Factory[T]":
        self._defaults.update(kwargs)
        return self

    def set_lazy(self, name: str, func: Callable) -> "Factory[T]":
        self._lazy[name] = func
        return self

    def sequence(self, name: str, start: int = 1) -> "Factory[T]":
        self._sequences[name] = start
        return self

    def build(self, **overrides) -> T:
        data = dict(self._defaults)

        for name, func in self._lazy.items():
            if name not in overrides:
                data[name] = func()

        for name, value in self._sequences.items():
            if name not in overrides:
                data[name] = value
                self._sequences[name] = value + 1

        data.update(overrides)
        return self.model(**data)

    def build_batch(self, count: int, **overrides) -> List[T]:
        return [self.build(**overrides) for _ in range(count)]

    def create(self, **overrides) -> T:
        instance = self.build(**overrides)
        if hasattr(instance, "save"):
            instance.save()
        return instance


class Faker:
    @staticmethod
    def uuid() -> str:
        return str(uuid.uuid4())

    @staticmethod
    def string(length: int = 10, chars: str = None) -> str:
        chars = chars or string.ascii_letters + string.digits
        return "".join(random.choice(chars) for _ in range(length))

    @staticmethod
    def integer(min_val: int = 0, max_val: int = 1000) -> int:
        return random.randint(min_val, max_val)

    @staticmethod
    def float(min_val: float = 0.0, max_val: float = 1.0) -> float:
        return random.uniform(min_val, max_val)

    @staticmethod
    def boolean() -> bool:
        return random.choice([True, False])

    @staticmethod
    def choice(items: List[Any]) -> Any:
        return random.choice(items)

    @staticmethod
    def email(domain: str = "example.com") -> str:
        name = Faker.string(8).lower()
        return f"{name}@{domain}"

    @staticmethod
    def name() -> str:
        first = random.choice(["Alice", "Bob", "Charlie", "Diana", "Eve", "Frank"])
        last = random.choice(["Smith", "Johnson", "Williams", "Brown", "Jones"])
        return f"{first} {last}"

    @staticmethod
    def phone() -> str:
        return f"+1-{random.randint(200,999)}-{random.randint(100,999)}-{random.randint(1000,9999)}"

    @staticmethod
    def address() -> str:
        num = random.randint(1, 9999)
        street = random.choice(["Main", "Oak", "Maple", "Cedar", "Pine"])
        suffix = random.choice(["St", "Ave", "Blvd", "Dr", "Ln"])
        return f"{num} {street} {suffix}"

    @staticmethod
    def sentence(words: int = 10) -> str:
        word_list = ["the", "quick", "brown", "fox", "jumps", "over", "lazy", "dog", "lorem", "ipsum"]
        return " ".join(random.choice(word_list) for _ in range(words)).capitalize() + "."


fake = Faker()


def example_usage():
    @dataclass
    class User:
        id: int
        name: str
        email: str
        active: bool = True

    user_factory = Factory(User)
    user_factory.sequence("id")
    user_factory.set_default(active=True)
    user_factory.set_lazy("name", fake.name)
    user_factory.set_lazy("email", fake.email)

    user1 = user_factory.build()
    user2 = user_factory.build(name="Custom Name")
    users = user_factory.build_batch(3)

    print(f"User 1: {user1}")
    print(f"User 2: {user2}")
    print(f"Batch: {users}")

    @fixture(scope="module")
    def db_connection():
        print("Creating DB connection")
        return {"connected": True}

    conn = fixtures.get_value("db_connection")
    print(f"\nFixture: {conn}")

    print(f"\nFake data:")
    print(f"  UUID: {fake.uuid()}")
    print(f"  Email: {fake.email()}")
    print(f"  Name: {fake.name()}")
    print(f"  Phone: {fake.phone()}")
