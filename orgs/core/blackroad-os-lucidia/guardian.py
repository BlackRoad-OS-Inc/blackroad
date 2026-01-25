class Guardian:
    def __init__(self):
        self.memory = []
        self.truth = {}

    def hear(self, statement):
        self.memory.append(statement)
        if "=>" in statement:
            k, v = statement.split("=>", 1)
            self.truth[k.strip()] = v.strip()

    def recall(self):
        return self.memory[-5:]

    def inspect(self):
        return self.truth

if __name__ == "__main__":
    g = Guardian()
    while True:
        msg = input("You: ")
        if msg.lower() == "exit":
            break
        g.hear(msg)
        print("Guardian remembers:", g.recall())
