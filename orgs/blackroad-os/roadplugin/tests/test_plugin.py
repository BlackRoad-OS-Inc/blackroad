"""Tests for RoadPlugin core functionality."""

import pytest
from roadplugin import (
    Plugin,
    PluginInfo,
    PluginContext,
    PluginState,
    PluginManager,
    HookManager,
    HookPriority,
    plugin,
)


class TestPluginInfo:
    """Tests for PluginInfo dataclass."""

    def test_default_values(self):
        info = PluginInfo(name="test")
        assert info.name == "test"
        assert info.version == "0.1.0"
        assert info.description == ""
        assert info.author == ""
        assert info.dependencies == []
        assert info.hooks == []

    def test_custom_values(self):
        info = PluginInfo(
            name="custom",
            version="1.2.3",
            description="A custom plugin",
            author="Test Author",
            dependencies=["dep1", "dep2"]
        )
        assert info.name == "custom"
        assert info.version == "1.2.3"
        assert info.description == "A custom plugin"
        assert info.dependencies == ["dep1", "dep2"]


class TestPluginContext:
    """Tests for PluginContext dataclass."""

    def test_default_context(self):
        ctx = PluginContext(plugin_name="test")
        assert ctx.plugin_name == "test"
        assert ctx.config == {}
        assert ctx.data == {}

    def test_context_with_config(self):
        ctx = PluginContext(
            plugin_name="test",
            config={"key": "value"}
        )
        assert ctx.config == {"key": "value"}


class TestPlugin:
    """Tests for base Plugin class."""

    @pytest.fixture
    def plugin_instance(self):
        ctx = PluginContext(plugin_name="test_plugin")
        return Plugin(ctx)

    def test_initial_state(self, plugin_instance):
        assert plugin_instance.state == PluginState.LOADED

    def test_register_hook(self, plugin_instance):
        def handler(data):
            return data

        plugin_instance.register_hook("test.hook", handler)
        hooks = plugin_instance.get_hooks()

        assert len(hooks) == 1
        assert hooks[0].name == "test.hook"
        assert hooks[0].handler == handler
        assert hooks[0].priority == HookPriority.NORMAL

    def test_register_hook_with_priority(self, plugin_instance):
        def handler(data):
            return data

        plugin_instance.register_hook("test.hook", handler, HookPriority.HIGH)
        hooks = plugin_instance.get_hooks()

        assert hooks[0].priority == HookPriority.HIGH


class TestHookManager:
    """Tests for HookManager."""

    @pytest.fixture
    def hook_manager(self):
        return HookManager()

    def test_register_hook(self, hook_manager):
        from roadplugin.plugin import HookRegistration

        registration = HookRegistration(
            name="test.hook",
            handler=lambda x: x,
            plugin_name="test"
        )
        hook_manager.register(registration)

        assert "test.hook" in hook_manager.hooks
        assert len(hook_manager.hooks["test.hook"]) == 1

    def test_unregister_hooks(self, hook_manager):
        from roadplugin.plugin import HookRegistration

        reg1 = HookRegistration(name="hook1", handler=lambda x: x, plugin_name="plugin1")
        reg2 = HookRegistration(name="hook1", handler=lambda x: x, plugin_name="plugin2")

        hook_manager.register(reg1)
        hook_manager.register(reg2)

        count = hook_manager.unregister("plugin1")
        assert count == 1
        assert len(hook_manager.hooks["hook1"]) == 1

    @pytest.mark.asyncio
    async def test_execute_hooks(self, hook_manager):
        from roadplugin.plugin import HookRegistration

        results = []

        def handler1(x):
            results.append("h1")
            return x + 1

        def handler2(x):
            results.append("h2")
            return x + 2

        hook_manager.register(HookRegistration(
            name="add", handler=handler1, plugin_name="p1"
        ))
        hook_manager.register(HookRegistration(
            name="add", handler=handler2, plugin_name="p2"
        ))

        hook_results = await hook_manager.execute("add", 10)
        assert hook_results == [11, 12]
        assert results == ["h1", "h2"]

    @pytest.mark.asyncio
    async def test_execute_filter(self, hook_manager):
        from roadplugin.plugin import HookRegistration

        def add_one(x):
            return x + 1

        def double(x):
            return x * 2

        hook_manager.register(HookRegistration(
            name="transform", handler=add_one, plugin_name="p1"
        ))
        hook_manager.register(HookRegistration(
            name="transform", handler=double, plugin_name="p2"
        ))

        result = await hook_manager.execute_filter("transform", 5)
        # 5 + 1 = 6, 6 * 2 = 12
        assert result == 12

    def test_priority_ordering(self, hook_manager):
        from roadplugin.plugin import HookRegistration

        hook_manager.register(HookRegistration(
            name="test", handler=lambda: "low", plugin_name="p1",
            priority=HookPriority.LOW
        ))
        hook_manager.register(HookRegistration(
            name="test", handler=lambda: "high", plugin_name="p2",
            priority=HookPriority.HIGH
        ))
        hook_manager.register(HookRegistration(
            name="test", handler=lambda: "highest", plugin_name="p3",
            priority=HookPriority.HIGHEST
        ))

        hooks = hook_manager.hooks["test"]
        priorities = [h.priority for h in hooks]
        assert priorities == [HookPriority.HIGHEST, HookPriority.HIGH, HookPriority.LOW]

    def test_list_hooks(self, hook_manager):
        from roadplugin.plugin import HookRegistration

        hook_manager.register(HookRegistration(
            name="hook1", handler=lambda: None, plugin_name="p1"
        ))
        hook_manager.register(HookRegistration(
            name="hook1", handler=lambda: None, plugin_name="p2"
        ))
        hook_manager.register(HookRegistration(
            name="hook2", handler=lambda: None, plugin_name="p1"
        ))

        listing = hook_manager.list_hooks()
        assert listing == {"hook1": 2, "hook2": 1}


class TestPluginDecorator:
    """Tests for @plugin decorator."""

    def test_decorator_creates_plugin_class(self):
        @plugin("decorated_plugin", version="2.0.0", description="Test")
        class MyPlugin:
            pass

        assert issubclass(MyPlugin, Plugin)
        assert MyPlugin.info.name == "decorated_plugin"
        assert MyPlugin.info.version == "2.0.0"
        assert MyPlugin.info.description == "Test"

    def test_decorated_plugin_instance(self):
        @plugin("test_plugin")
        class MyPlugin:
            def custom_method(self):
                return "custom"

        ctx = PluginContext(plugin_name="test_plugin")
        instance = MyPlugin(ctx)

        assert instance.info.name == "test_plugin"
        assert instance.custom_method() == "custom"


class TestPluginManager:
    """Tests for PluginManager."""

    @pytest.fixture
    def manager(self, tmp_path):
        return PluginManager(plugin_dirs=[str(tmp_path)])

    def test_set_config(self, manager):
        manager.set_config("test_plugin", {"key": "value"})
        assert manager._configs["test_plugin"] == {"key": "value"}

    def test_list_plugins_empty(self, manager):
        plugins = manager.list_plugins()
        assert plugins == []

    @pytest.mark.asyncio
    async def test_execute_hook_no_handlers(self, manager):
        results = await manager.execute_hook("nonexistent.hook")
        assert results == []

    @pytest.mark.asyncio
    async def test_filter_no_handlers(self, manager):
        result = await manager.filter("nonexistent.filter", "original")
        assert result == "original"


class TestPluginState:
    """Tests for PluginState enum."""

    def test_state_values(self):
        assert PluginState.DISCOVERED.value == "discovered"
        assert PluginState.LOADED.value == "loaded"
        assert PluginState.ENABLED.value == "enabled"
        assert PluginState.DISABLED.value == "disabled"
        assert PluginState.ERROR.value == "error"


class TestHookPriority:
    """Tests for HookPriority enum."""

    def test_priority_ordering(self):
        assert HookPriority.HIGHEST.value < HookPriority.HIGH.value
        assert HookPriority.HIGH.value < HookPriority.NORMAL.value
        assert HookPriority.NORMAL.value < HookPriority.LOW.value
        assert HookPriority.LOW.value < HookPriority.LOWEST.value

    def test_priority_values(self):
        assert HookPriority.HIGHEST.value == 0
        assert HookPriority.NORMAL.value == 50
        assert HookPriority.LOWEST.value == 100
