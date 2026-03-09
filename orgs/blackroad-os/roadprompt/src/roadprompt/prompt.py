"""
RoadPrompt - Interactive Prompts for BlackRoad
Collect user input with validation and auto-completion.
"""

from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Tuple
import sys
import logging

logger = logging.getLogger(__name__)


@dataclass
class Choice:
    value: Any
    label: str
    disabled: bool = False
    hint: str = ""


@dataclass
class ValidationResult:
    valid: bool
    message: str = ""


class Validator:
    @staticmethod
    def required(value: str) -> ValidationResult:
        if not value or not value.strip():
            return ValidationResult(False, "This field is required")
        return ValidationResult(True)

    @staticmethod
    def min_length(length: int) -> Callable:
        def validate(value: str) -> ValidationResult:
            if len(value) < length:
                return ValidationResult(False, f"Minimum length is {length}")
            return ValidationResult(True)
        return validate

    @staticmethod
    def max_length(length: int) -> Callable:
        def validate(value: str) -> ValidationResult:
            if len(value) > length:
                return ValidationResult(False, f"Maximum length is {length}")
            return ValidationResult(True)
        return validate

    @staticmethod
    def pattern(regex: str, message: str = "Invalid format") -> Callable:
        import re
        compiled = re.compile(regex)
        def validate(value: str) -> ValidationResult:
            if not compiled.match(value):
                return ValidationResult(False, message)
            return ValidationResult(True)
        return validate

    @staticmethod
    def email() -> Callable:
        return Validator.pattern(
            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            "Invalid email address"
        )

    @staticmethod
    def number(min_val: float = None, max_val: float = None) -> Callable:
        def validate(value: str) -> ValidationResult:
            try:
                num = float(value)
                if min_val is not None and num < min_val:
                    return ValidationResult(False, f"Minimum value is {min_val}")
                if max_val is not None and num > max_val:
                    return ValidationResult(False, f"Maximum value is {max_val}")
                return ValidationResult(True)
            except ValueError:
                return ValidationResult(False, "Must be a number")
        return validate


class Prompt:
    def __init__(self, stream_in=None, stream_out=None):
        self.stream_in = stream_in or sys.stdin
        self.stream_out = stream_out or sys.stdout

    def _write(self, text: str) -> None:
        self.stream_out.write(text)
        self.stream_out.flush()

    def _read(self) -> str:
        return self.stream_in.readline().rstrip("\n")

    def text(self, message: str, default: str = "", validators: List[Callable] = None, password: bool = False) -> str:
        validators = validators or []
        
        while True:
            prompt = f"{message}"
            if default:
                prompt += f" [{default}]"
            prompt += ": "
            
            self._write(prompt)
            
            if password:
                import getpass
                value = getpass.getpass("")
            else:
                value = self._read()
            
            if not value and default:
                value = default
            
            valid = True
            for validator in validators:
                result = validator(value)
                if not result.valid:
                    self._write(f"  ✗ {result.message}\n")
                    valid = False
                    break
            
            if valid:
                return value

    def confirm(self, message: str, default: bool = False) -> bool:
        hint = "[Y/n]" if default else "[y/N]"
        self._write(f"{message} {hint}: ")
        
        value = self._read().lower()
        
        if not value:
            return default
        
        return value in ("y", "yes", "true", "1")

    def select(self, message: str, choices: List[Choice], default: int = 0) -> Any:
        self._write(f"{message}\n")
        
        for i, choice in enumerate(choices):
            marker = ">" if i == default else " "
            disabled = " (disabled)" if choice.disabled else ""
            hint = f" - {choice.hint}" if choice.hint else ""
            self._write(f"  {marker} {i + 1}. {choice.label}{disabled}{hint}\n")
        
        while True:
            self._write(f"Enter choice [1-{len(choices)}]: ")
            value = self._read()
            
            if not value:
                return choices[default].value
            
            try:
                idx = int(value) - 1
                if 0 <= idx < len(choices):
                    if choices[idx].disabled:
                        self._write("  ✗ This option is disabled\n")
                        continue
                    return choices[idx].value
            except ValueError:
                pass
            
            self._write("  ✗ Invalid selection\n")

    def multi_select(self, message: str, choices: List[Choice], min_select: int = 0, max_select: int = None) -> List[Any]:
        self._write(f"{message} (comma-separated numbers)\n")
        
        for i, choice in enumerate(choices):
            disabled = " (disabled)" if choice.disabled else ""
            self._write(f"  {i + 1}. {choice.label}{disabled}\n")
        
        while True:
            self._write("Enter choices: ")
            value = self._read()
            
            if not value:
                if min_select == 0:
                    return []
                self._write(f"  ✗ Select at least {min_select} options\n")
                continue
            
            try:
                indices = [int(x.strip()) - 1 for x in value.split(",")]
                selected = []
                
                for idx in indices:
                    if 0 <= idx < len(choices) and not choices[idx].disabled:
                        selected.append(choices[idx].value)
                
                if len(selected) < min_select:
                    self._write(f"  ✗ Select at least {min_select} options\n")
                    continue
                
                if max_select and len(selected) > max_select:
                    self._write(f"  ✗ Select at most {max_select} options\n")
                    continue
                
                return selected
            except ValueError:
                self._write("  ✗ Invalid input\n")

    def autocomplete(self, message: str, suggestions: List[str], validators: List[Callable] = None) -> str:
        validators = validators or []
        
        while True:
            self._write(f"{message} (tab for suggestions): ")
            value = self._read()
            
            if value.endswith("\t"):
                prefix = value.rstrip("\t")
                matches = [s for s in suggestions if s.startswith(prefix)]
                if matches:
                    self._write(f"  Suggestions: {', '.join(matches[:5])}\n")
                continue
            
            valid = True
            for validator in validators:
                result = validator(value)
                if not result.valid:
                    self._write(f"  ✗ {result.message}\n")
                    valid = False
                    break
            
            if valid:
                return value


class Wizard:
    def __init__(self, title: str = "Setup Wizard"):
        self.title = title
        self.steps: List[Tuple[str, Callable]] = []
        self.results: Dict[str, Any] = {}
        self.prompt = Prompt()

    def add_step(self, name: str, fn: Callable) -> "Wizard":
        self.steps.append((name, fn))
        return self

    def run(self) -> Dict[str, Any]:
        print(f"\n{'=' * 40}")
        print(f"  {self.title}")
        print(f"{'=' * 40}\n")
        
        for i, (name, fn) in enumerate(self.steps):
            print(f"Step {i + 1}/{len(self.steps)}: {name}")
            result = fn(self.prompt, self.results)
            self.results[name] = result
            print()
        
        print(f"{'=' * 40}")
        print("  Setup complete!")
        print(f"{'=' * 40}\n")
        
        return self.results


def example_usage():
    prompt = Prompt()
    
    name = prompt.text("What's your name?", validators=[Validator.required])
    print(f"Hello, {name}!")
    
    age = prompt.text("How old are you?", validators=[Validator.number(min_val=0, max_val=150)])
    print(f"You are {age} years old")
    
    confirmed = prompt.confirm("Do you agree to the terms?", default=False)
    print(f"Agreed: {confirmed}")
    
    color = prompt.select("Pick a color:", [
        Choice("red", "Red", hint="Hot"),
        Choice("green", "Green", hint="Nature"),
        Choice("blue", "Blue", hint="Ocean"),
        Choice("purple", "Purple", disabled=True),
    ])
    print(f"Selected: {color}")
    
    features = prompt.multi_select("Select features:", [
        Choice("auth", "Authentication"),
        Choice("api", "REST API"),
        Choice("db", "Database"),
        Choice("cache", "Caching"),
    ], min_select=1)
    print(f"Features: {features}")

