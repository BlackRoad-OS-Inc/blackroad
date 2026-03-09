"""
RoadArg - Argument Parsing for BlackRoad
Parse command-line arguments with type conversion and validation.
"""

from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Type, Union
import sys
import logging

logger = logging.getLogger(__name__)


class ArgError(Exception):
    pass


@dataclass
class Arg:
    name: str
    short: str = ""
    type: Type = str
    default: Any = None
    required: bool = False
    help: str = ""
    choices: List[Any] = field(default_factory=list)
    nargs: str = ""  # "", "?", "*", "+"
    action: str = "store"  # store, store_true, store_false, count, append
    dest: str = ""
    metavar: str = ""


@dataclass
class Positional:
    name: str
    type: Type = str
    help: str = ""
    nargs: str = ""  # "", "?", "*", "+"
    default: Any = None
    choices: List[Any] = field(default_factory=list)


@dataclass
class ParsedArgs:
    args: Dict[str, Any] = field(default_factory=dict)
    positionals: List[Any] = field(default_factory=list)
    remaining: List[str] = field(default_factory=list)

    def get(self, name: str, default: Any = None) -> Any:
        return self.args.get(name, default)

    def __getattr__(self, name: str) -> Any:
        if name in ("args", "positionals", "remaining"):
            return super().__getattribute__(name)
        return self.args.get(name)


class ArgParser:
    def __init__(self, prog: str = "", description: str = "", epilog: str = ""):
        self.prog = prog or sys.argv[0]
        self.description = description
        self.epilog = epilog
        self.arguments: List[Arg] = []
        self.positionals: List[Positional] = []
        self._add_help()

    def _add_help(self) -> None:
        self.add_argument("help", short="h", action="store_true", help="Show this help message")

    def add_argument(self, name: str, short: str = "", **kwargs) -> "ArgParser":
        self.arguments.append(Arg(name=name, short=short, **kwargs))
        return self

    def add_positional(self, name: str, **kwargs) -> "ArgParser":
        self.positionals.append(Positional(name=name, **kwargs))
        return self

    def parse(self, args: List[str] = None) -> ParsedArgs:
        args = args if args is not None else sys.argv[1:]
        result = ParsedArgs()
        
        self._apply_defaults(result)
        
        i = 0
        pos_idx = 0
        collected: Dict[str, List[Any]] = {}
        
        while i < len(args):
            arg = args[i]
            
            if arg == "--":
                result.remaining = args[i + 1:]
                break
            elif arg.startswith("--"):
                key = arg[2:]
                value = None
                
                if "=" in key:
                    key, value = key.split("=", 1)
                
                arg_def = self._find_arg(key)
                if not arg_def:
                    raise ArgError(f"Unknown argument: --{key}")
                
                i, value = self._process_arg(arg_def, args, i, value)
                self._store_value(result, arg_def, value, collected)
                
            elif arg.startswith("-") and len(arg) > 1:
                for j, short in enumerate(arg[1:]):
                    arg_def = self._find_arg_short(short)
                    if not arg_def:
                        raise ArgError(f"Unknown argument: -{short}")
                    
                    if arg_def.action in ("store_true", "store_false", "count"):
                        self._store_value(result, arg_def, None, collected)
                    elif j == len(arg) - 2:
                        i, value = self._process_arg(arg_def, args, i, None)
                        self._store_value(result, arg_def, value, collected)
                    else:
                        raise ArgError(f"Option -{short} requires a value")
            else:
                if pos_idx < len(self.positionals):
                    pos_def = self.positionals[pos_idx]
                    value = self._convert(arg, pos_def.type)
                    
                    if pos_def.choices and value not in pos_def.choices:
                        raise ArgError(f"Invalid choice: {value}")
                    
                    if pos_def.nargs in ("*", "+"):
                        if pos_def.name not in collected:
                            collected[pos_def.name] = []
                        collected[pos_def.name].append(value)
                    else:
                        result.args[pos_def.name] = value
                        pos_idx += 1
                else:
                    result.remaining.append(arg)
            
            i += 1
        
        for name, values in collected.items():
            result.args[name] = values
        
        if result.args.get("help"):
            self.print_help()
            sys.exit(0)
        
        self._validate(result)
        return result

    def _find_arg(self, name: str) -> Optional[Arg]:
        for arg in self.arguments:
            if arg.name == name or arg.dest == name:
                return arg
        return None

    def _find_arg_short(self, short: str) -> Optional[Arg]:
        for arg in self.arguments:
            if arg.short == short:
                return arg
        return None

    def _process_arg(self, arg_def: Arg, args: List[str], i: int, value: Any) -> tuple:
        if arg_def.action in ("store_true", "store_false", "count"):
            return i, None
        
        if value is None:
            if arg_def.nargs == "?" and (i + 1 >= len(args) or args[i + 1].startswith("-")):
                return i, arg_def.default
            i += 1
            if i >= len(args):
                raise ArgError(f"Argument --{arg_def.name} requires a value")
            value = args[i]
        
        return i, self._convert(value, arg_def.type)

    def _store_value(self, result: ParsedArgs, arg_def: Arg, value: Any, collected: Dict) -> None:
        dest = arg_def.dest or arg_def.name
        
        if arg_def.action == "store_true":
            result.args[dest] = True
        elif arg_def.action == "store_false":
            result.args[dest] = False
        elif arg_def.action == "count":
            result.args[dest] = result.args.get(dest, 0) + 1
        elif arg_def.action == "append" or arg_def.nargs in ("*", "+"):
            if dest not in collected:
                collected[dest] = []
            collected[dest].append(value)
        else:
            if arg_def.choices and value not in arg_def.choices:
                raise ArgError(f"Invalid choice for --{arg_def.name}: {value}")
            result.args[dest] = value

    def _convert(self, value: Any, typ: Type) -> Any:
        if typ == bool:
            return value.lower() in ("true", "1", "yes", "on")
        return typ(value)

    def _apply_defaults(self, result: ParsedArgs) -> None:
        for arg in self.arguments:
            dest = arg.dest or arg.name
            if arg.action == "store_true":
                result.args[dest] = False
            elif arg.action == "store_false":
                result.args[dest] = True
            elif arg.action == "count":
                result.args[dest] = 0
            else:
                result.args[dest] = arg.default

    def _validate(self, result: ParsedArgs) -> None:
        for arg in self.arguments:
            dest = arg.dest or arg.name
            if arg.required and result.args.get(dest) is None:
                raise ArgError(f"Required argument: --{arg.name}")

    def print_help(self) -> None:
        print(f"Usage: {self.prog} [OPTIONS]", end="")
        for pos in self.positionals:
            if pos.nargs in ("*", "?"):
                print(f" [{pos.name.upper()}]", end="")
            elif pos.nargs == "+":
                print(f" {pos.name.upper()}...", end="")
            else:
                print(f" {pos.name.upper()}", end="")
        print()
        
        if self.description:
            print(f"\n{self.description}")
        
        if self.positionals:
            print("\nPositional arguments:")
            for pos in self.positionals:
                print(f"  {pos.name:20} {pos.help}")
        
        print("\nOptions:")
        for arg in self.arguments:
            flags = f"--{arg.name}"
            if arg.short:
                flags = f"-{arg.short}, {flags}"
            if arg.metavar:
                flags += f" {arg.metavar}"
            print(f"  {flags:25} {arg.help}")
        
        if self.epilog:
            print(f"\n{self.epilog}")


def example_usage():
    parser = ArgParser(
        prog="myapp",
        description="My awesome application",
        epilog="Example: myapp --verbose input.txt"
    )
    
    parser.add_argument("verbose", short="v", action="count", help="Increase verbosity")
    parser.add_argument("output", short="o", default="output.txt", help="Output file")
    parser.add_argument("format", short="f", choices=["json", "xml", "csv"], default="json", help="Output format")
    parser.add_argument("dry-run", action="store_true", help="Don't make any changes")
    parser.add_positional("input", help="Input file")
    parser.add_positional("extra", nargs="*", help="Extra files")
    
    test_args = ["--verbose", "-v", "-f", "csv", "--output=result.csv", "input.txt", "extra1.txt", "extra2.txt"]
    
    try:
        args = parser.parse(test_args)
        print(f"Verbose level: {args.verbose}")
        print(f"Output: {args.output}")
        print(f"Format: {args.format}")
        print(f"Dry run: {args.get('dry-run')}")
        print(f"Input: {args.input}")
        print(f"Extra: {args.extra}")
    except ArgError as e:
        print(f"Error: {e}")
        parser.print_help()

