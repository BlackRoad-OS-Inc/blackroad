from guardian import Guardian

g = Guardian()

print("🧠 Lucidia Chat (local) – type 'exit' to quit")

while True:
    msg = input("You: ")
    if msg.strip().lower() == "exit":
        break
    g.hear(msg)
    print("Lucidia: (remembered)")
