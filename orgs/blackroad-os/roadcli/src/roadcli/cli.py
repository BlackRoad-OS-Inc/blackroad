"""
RoadCLI - CLI Application Framework for BlackRoad
Build command-line applications with commands and options.
"""

from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Type
import sys
import logging

logger = logging.getLogger(__name__)


@dataclass
class Option:
    name: str
    short: str = ""
    type: Type = str
    default: Any = None
    required: bool = False
    help: str = ""
    multiple: bool = False


@dataclass
class Argument:
    name: str
    type: Type = str
    required: bool = True
    default: Any = None
    help: str = ""
    nargs: str = ""  # "", "*", "+", "?"


@dataclass
class Command:
    name: str
    handler: Callable
    help: str = ""
    options: List[Option] = field(default_factory=list)
    arguments: List[Argument] = field(default_factory=list)
    subcommands: Dict[str, "Command"] = field(default_factory=dict)


class Context:
    def __init__(self):
        self.options: Dict[str, Any] = {}
        self.arguments: Dict[str, Any] = {}
        self.parent: Optional["Context"] = None
        self.command: Optional[Command] = None

    def get(self, key: str, default: Any = None) -> Any:
        return self.options.get(key, self.arguments.get(key, default))


class Parser:
    def __init__(self, command: Command):
        self.command = command

    def parse(self, args: List[str]) -> Context:
        ctx = Context()
        ctx.command = self.command
        
        i = 0
        arg_idx = 0
        collected_args: Dict[str, List[Any]] = {}
        
        while i < len(args):
            arg = args[i]
            
            if arg.startswith("--"):
                key = arg[2:]
                if "=" in key:
                    key, value = key.split("=", 1)
                else:
                    i += 1
                    value = args[i] if i < len(args) else None
                
                opt = self._find_option(key)
                if opt:
                    ctx.options[opt.name] = self._convert(value, opt.type)
            elif arg.startswith("-") and len(arg) == 2:
                short = arg[1]
                opt = self._find_option_short(short)
                if opt:
                    i += 1
                    value = args[i] if i < len(args) else None
                    ctx.options[opt.name] = self._convert(value, opt.type)
            else:
                if arg in self.command.subcommands:
                    sub_parser = Parser(self.command.subcommands[arg])
                    sub_ctx = sub_parser.parse(args[i + 1:])
                    sub_ctx.parent = ctx
                    return sub_ctx
                
                if arg_idx < len(self.command.arguments):
                    arg_def = self.command.arguments[arg_idx]
                    if arg_def.nargs in ("*", "+"):
                        if arg_def.name not in collected_args:
                            collected_args[arg_def.name] = []
                        collected_args[arg_def.name].append(self._convert(arg, arg_def.type))
                    else:
                        ctx.arguments[arg_def.name] = self._convert(arg, arg_def.type)
                        arg_idx += 1
            
            i += 1
        
        for name, values in collected_args.items():
            ctx.arguments[name] = values
        
        self._apply_defaults(ctx)
        return ctx

    def _find_option(self, name: str) -> Optional[Option]:
        for opt in self.command.options:
            if opt.name == name:
                return opt
        return None

    def _find_option_short(self, short: str) -> Optional[Option]:
        for opt in self.command.options:
            if opt.short == short:
                return opt
        return None

    def _convert(self, value: Any, typ: Type) -> Any:
        if value is None:
            return None
        if typ == bool:
            return value.lower() in ("true", "1", "yes", "on")
        return typ(value)

    def _apply_defaults(self, ctx: Context) -> None:
        for opt in self.command.options:
            if opt.name not in ctx.options:
                ctx.options[opt.name] = opt.default
        for arg in self.command.arguments:
            if arg.name not in ctx.arguments:
                ctx.arguments[arg.name] = arg.default


class CLI:
    def __init__(self, name: str, version: str = "1.0.0", help: str = ""):
        self.name = name
        self.version = version
        self.help = help
        self.root = Command(name=name, handler=self._default_handler, help=help)
        self.hooks: Dict[str, List[Callable]] = {"before": [], "after": [], "error": []}

    def _default_handler(self, ctx: Context) -> int:
        self.print_help()
        return 0

    def command(self, name: str, help: str = "") -> Callable:
        def decorator(fn: Callable) -> Callable:
            cmd = Command(name=name, handler=fn, help=help)
            self.root.subcommands[name] = cmd
            return fn
        return decorator

    def option(self, name: str, short: str = "", type: Type = str, default: Any = None, required: bool = False, help: str = "") -> Callable:
        def decorator(fn: Callable) -> Callable:
            cmd = self._find_command_for_handler(fn)
            if cmd:
                cmd.options.append(Option(name=name, short=short, type=type, default=default, required=required, help=help))
            return fn
        return decorator

    def argument(self, name: str, type: Type = str, required: bool = True, help: str = "", nargs: str = "") -> Callable:
        def decorator(fn: Callable) -> Callable:
            cmd = self._find_command_for_handler(fn)
            if cmd:
                cmd.arguments.append(Argument(name=name, type=type, required=required, help=rue, nargs=nargs))
            return fn
        return decorator

    def _find_command_for_handler(self, fn: Callable) -> Optional[Command]:
        for cmd in self.root.subcommands.values():
            if cmd.handler == fn:
                return cmd
        return None

    def add_hook(self, event: str, handler: Callable) -> None:
        if event in self.hooks:
            self.hooks[event].append(handler)

    def run(self, args: List[str] = None) -> int:
        args = args if args is not None else sys.argv[1:]
        
        for hook in self.hooks["before"]:
            hook(args)
        
        try:
            if not args or args[0] in ("-h", "--help"):
                self.print_help()
                return 0
            if args[0] in ("-v", "--version"):
                print(f"{self.name} {self.version}")
                return 0
            
            parser = Parser(self.root)
            ctx = parser.parse(args)
            
            if ctx.command and ctx.command.handler:
                result = ctx.command.handler(ctx)
                
                for hook in self.hooks["after"]:
                    hook(ctx, result)
                
                return result if isinstance(result, int) else 0
        except Exception as e:
            for hook in self.hooks["error"]:
                hook(e)
            print(f"Error: {e}", file=sys.stderr)
            return 1
        
        return 0

    def print_help(self) -> None:
        print(f"{self.name} {self.version}")
        if self.help:
            print(f"\n{self.help}")
        print("\nCommands:")
        for name, cmd in self.root.subcommands.items():
            print(f"  {name:15} {cmd.help}")
        print("\nOptions:")
        print("  -h, --help     Show this help message")
        print("  -v, --version  Show version")


class Group:
    def __init__(self, cli: CLI, name: str, help: str = ""):
        self.cli = cli
        self.name = name
        self.help = help
        self.parent = Command(name=name, handler=lambda ctx: 0, help=help)
        cli.root.subcommands[name] = self.parent

    def command(self, name: str, help: str = "") -> Callable:
        def decorator(fn: Callable) -> Callable:
            cmd = Command(name=name, handler=fn, help=help)
            self.parent.subcommands[name] = cmd
            return fn
        return decorator


def example_usage():
    app = CLI("myapp", version="1.0.0", help="My CLI application")
    
    @app.command("greet", help="Greet someone")
    def greet(ctx: Context):
        name = ctx.get("name", "World")
        count = ctx.get("count", 1)
        for _ in range(count):
            print(f"Hello, {name}!")
        return 0
    
    @app.command("calc", help="Calculator")
    def calc(ctx: Context):
        op = ctx.get("operation")
        a = ctx.get("a", 0)
        b = ctx.get("b", 0)
        if op == "add":
            print(f"{a} + {b} = {a + b}")
        elif op == "sub":
            print(f"{a} - {b} = {a - b}")
        return 0
    
    db = Group(app, "db", help="Database commands")
    
    @db.command("migrate", help="Run migrations")
    def db_migrate(ctx: Context):
        print("Running migrations...")
        return 0
    
    app.run(["greet"])
    app.run(["calc"])
    app.run(["db", "migrate"])

