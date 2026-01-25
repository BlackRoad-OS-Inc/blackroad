from sdk import plugin_api

CAPABILITIES = [
    {"intent": "echo", "inputs_schema": {"type": "object"}, "outputs_schema": {"type": "object"}}
]


class EchoBot(plugin_api.BaseBot):
    NAME = "Echo-BOT"

    def handle(self, task: plugin_api.Task) -> plugin_api.BotResponse:
        return plugin_api.BotResponse(ok=True, content=task.inputs.get("text", ""))


plugin_api.register_plugin_bot(EchoBot)
