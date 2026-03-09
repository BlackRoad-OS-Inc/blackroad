#!/usr/bin/env python3
"""
Multi-Model Continuity Testing Framework V2
Optimized for available cluster nodes with improved timeout handling
"""

import json
import time
import subprocess
import hashlib
from datetime import datetime
from typing import Dict, List, Any

class ModelContinuityTester:
    """Tests how well different models maintain context and reasoning"""

    def __init__(self, nodes: Dict[str, str]):
        """
        Initialize tester with cluster nodes
        nodes: {"node_name": "ip_address"}
        """
        self.nodes = nodes
        self.test_results = []
        self.session_id = hashlib.sha256(
            f"{datetime.now().isoformat()}".encode()
        ).hexdigest()[:8]

    def query_model(self, node: str, model: str, prompt: str, context: str = "", timeout: int = 120) -> Dict[str, Any]:
        """Query a model via Ollama with configurable timeout"""
        full_prompt = f"{context}\n\n{prompt}" if context else prompt

        # Escape single quotes in prompt
        escaped_prompt = full_prompt.replace("'", "'\\''")

        cmd = [
            "ssh",
            "-o", "ConnectTimeout=10",
            "-o", "ServerAliveInterval=5",
            node,
            f"ollama run {model} '{escaped_prompt}'"
        ]

        start_time = time.time()
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            duration = time.time() - start_time

            return {
                "success": result.returncode == 0,
                "response": result.stdout.strip(),
                "error": result.stderr.strip() if result.returncode != 0 else None,
                "duration": duration,
                "node": node,
                "model": model
            }
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "response": "",
                "error": f"Timeout after {timeout}s",
                "duration": float(timeout),
                "node": node,
                "model": model
            }
        except Exception as e:
            return {
                "success": False,
                "response": "",
                "error": str(e),
                "duration": time.time() - start_time,
                "node": node,
                "model": model
            }

    def test_reasoning_continuity(self) -> Dict[str, Any]:
        """Test if models can continue reasoning from previous context"""

        print("="*80)
        print("🧠 REASONING CONTINUITY TEST")
        print("="*80)

        # Initial context: Quantum computing question
        initial_question = """What is the fundamental difference between a transistor in a classical computer and a qubit in a quantum computer? Give a brief answer."""

        # Follow-up that requires understanding the previous answer
        followup_question = """Based on that difference, explain why room temperature operation is easier for one than the other. Be concise."""

        results = {
            "test_name": "reasoning_continuity",
            "timestamp": datetime.now().isoformat(),
            "models_tested": [],
            "results": []
        }

        # Test on different models across available nodes
        test_configs = [
            {"node": "lucidia", "model": "qwen2.5:1.5b"},
            {"node": "aria", "model": "deepseek-r1:1.5b"},
            {"node": "aria", "model": "gemma2:2b"},
        ]

        for config in test_configs:
            print(f"\n📊 Testing {config['model']} on {config['node']}")
            print("-"*80)

            # Initial query
            print("Initial question...")
            initial_response = self.query_model(
                config["node"],
                config["model"],
                initial_question,
                timeout=120
            )

            if not initial_response["success"]:
                print(f"❌ Initial query failed: {initial_response['error']}")
                continue

            print(f"✓ Response ({initial_response['duration']:.1f}s): {initial_response['response'][:150]}...")

            # Follow-up with context
            print("\nFollow-up question with context...")
            context = f"Previous question: {initial_question}\nYour answer: {initial_response['response']}"

            followup_response = self.query_model(
                config["node"],
                config["model"],
                followup_question,
                context=context,
                timeout=120
            )

            if followup_response["success"]:
                print(f"✓ Follow-up ({followup_response['duration']:.1f}s): {followup_response['response'][:150]}...")
            else:
                print(f"❌ Follow-up failed: {followup_response['error']}")

            # Store results
            test_result = {
                "model": config["model"],
                "node": config["node"],
                "initial_response": initial_response,
                "followup_response": followup_response,
                "total_time": initial_response["duration"] + followup_response["duration"],
                "continuity_maintained": followup_response["success"]
            }

            results["models_tested"].append(config["model"])
            results["results"].append(test_result)

        self.test_results.append(results)
        return results

    def test_context_transfer(self) -> Dict[str, Any]:
        """Test transferring context between different models"""

        print("\n" + "="*80)
        print("🔄 CONTEXT TRANSFER TEST")
        print("="*80)

        # Start with one model, continue with another
        initial_task = "Count from 1 to 5, but only give me the first 3 numbers. Just the numbers, nothing else."
        continuation_task = "Continue the counting sequence with the next 2 numbers. Just the numbers."

        results = {
            "test_name": "context_transfer",
            "timestamp": datetime.now().isoformat(),
            "transfers": []
        }

        # Test transfers between different models
        transfer_configs = [
            {"model_a": {"node": "lucidia", "model": "qwen2.5:1.5b"},
             "model_b": {"node": "aria", "model": "deepseek-r1:1.5b"}},
            {"model_a": {"node": "aria", "model": "gemma2:2b"},
             "model_b": {"node": "lucidia", "model": "qwen2.5:1.5b"}},
        ]

        for config in transfer_configs:
            model_a = config["model_a"]
            model_b = config["model_b"]

            print(f"\n📤 Starting with {model_a['model']} on {model_a['node']}")

            response_a = self.query_model(
                model_a["node"],
                model_a["model"],
                initial_task,
                timeout=60
            )

            if response_a["success"]:
                print(f"✓ {model_a['model']}: {response_a['response']}")
            else:
                print(f"❌ Failed: {response_a['error']}")
                continue

            print(f"\n📥 Continuing with {model_b['model']} on {model_b['node']}")

            context = f"Previous task: {initial_task}\nPrevious response: {response_a['response']}"

            response_b = self.query_model(
                model_b["node"],
                model_b["model"],
                continuation_task,
                context=context,
                timeout=60
            )

            if response_b["success"]:
                print(f"✓ {model_b['model']}: {response_b['response']}")
            else:
                print(f"❌ Failed: {response_b['error']}")

            # Check if context was preserved (looking for 4 and 5)
            preserved = response_b["success"] and ("4" in response_b["response"] and "5" in response_b["response"])

            transfer_result = {
                "from_model": model_a["model"],
                "from_node": model_a["node"],
                "to_model": model_b["model"],
                "to_node": model_b["node"],
                "context_preserved": preserved,
                "initial_response": response_a,
                "continuation_response": response_b
            }

            results["transfers"].append(transfer_result)

        self.test_results.append(results)
        return results

    def test_distributed_reasoning(self) -> Dict[str, Any]:
        """Test reasoning distributed across multiple nodes/models"""

        print("\n" + "="*80)
        print("🌐 DISTRIBUTED REASONING TEST")
        print("="*80)

        # Simple problem that can be verified
        problem = """Calculate 2 to the power of 10. Just give the number."""

        results = {
            "test_name": "distributed_reasoning",
            "timestamp": datetime.now().isoformat(),
            "nodes_used": [],
            "responses": []
        }

        # Query multiple models simultaneously
        test_nodes = [
            {"node": "lucidia", "model": "qwen2.5:1.5b"},
            {"node": "aria", "model": "deepseek-r1:1.5b"},
            {"node": "aria", "model": "gemma2:2b"},
        ]

        for config in test_nodes:
            print(f"\n🔍 Querying {config['model']} on {config['node']}")

            response = self.query_model(
                config["node"],
                config["model"],
                problem,
                timeout=60
            )

            if response["success"]:
                print(f"✓ Response: {response['response']}")
                results["nodes_used"].append(config["node"])
                results["responses"].append(response)
            else:
                print(f"❌ Failed: {response['error']}")

        self.test_results.append(results)
        return results

    def generate_report(self) -> str:
        """Generate comprehensive test report"""

        report = f"""
════════════════════════════════════════════════════════════════════════════════
🧪 MULTI-MODEL CONTINUITY TEST REPORT V2
════════════════════════════════════════════════════════════════════════════════

Session ID: {self.session_id}
Timestamp: {datetime.now().isoformat()}
Tests Run: {len(self.test_results)}

"""

        for test in self.test_results:
            report += f"""
───────────────────────────────────────────────────────────────────────────────
TEST: {test['test_name'].upper()}
───────────────────────────────────────────────────────────────────────────────
Timestamp: {test['timestamp']}
"""

            if test['test_name'] == 'reasoning_continuity':
                report += f"Models Tested: {', '.join(test['models_tested'])}\n\n"
                for result in test['results']:
                    report += f"""
Model: {result['model']} on {result['node']}
  Initial Query Time: {result['initial_response']['duration']:.2f}s
  Follow-up Time: {result['followup_response']['duration']:.2f}s
  Total Time: {result['total_time']:.2f}s
  Continuity: {'✓ Maintained' if result['continuity_maintained'] else '✗ Lost'}
"""

            elif test['test_name'] == 'context_transfer':
                for transfer in test['transfers']:
                    report += f"""
Transfer: {transfer['from_model']} ({transfer['from_node']}) → {transfer['to_model']} ({transfer['to_node']})
  Context Preserved: {'✓ Yes' if transfer['context_preserved'] else '✗ No'}
  Time: {transfer['initial_response']['duration'] + transfer['continuation_response']['duration']:.2f}s
"""

            elif test['test_name'] == 'distributed_reasoning':
                report += f"Nodes Used: {', '.join(test['nodes_used'])}\n"
                report += f"Successful Responses: {len(test['responses'])}\n"

        report += """
════════════════════════════════════════════════════════════════════════════════
"""

        return report

    def save_results(self, filename: str):
        """Save results to JSON file"""
        with open(filename, 'w') as f:
            json.dump({
                "session_id": self.session_id,
                "timestamp": datetime.now().isoformat(),
                "test_results": self.test_results
            }, f, indent=2)

        print(f"\n💾 Results saved to: {filename}")


def main():
    """Run all continuity tests"""

    print("""
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║          🌌 MULTI-MODEL CONTINUITY TESTING FRAMEWORK V2 🌌                   ║
║                                                                               ║
║     Testing reasoning and context continuity across different LLM models     ║
║     Optimized for available nodes with improved timeout handling             ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
""")

    # Define available cluster nodes
    nodes = {
        "lucidia": "192.168.4.38",
        "aria": "192.168.4.82",
    }

    # Initialize tester
    tester = ModelContinuityTester(nodes)

    # Run tests
    print("\n🚀 Starting test suite...\n")

    try:
        # Test 1: Reasoning continuity
        tester.test_reasoning_continuity()

        # Test 2: Context transfer
        tester.test_context_transfer()

        # Test 3: Distributed reasoning
        tester.test_distributed_reasoning()

        # Generate report
        report = tester.generate_report()
        print("\n" + report)

        # Save results
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        results_file = f"model_continuity_results_v2_{timestamp}.json"
        tester.save_results(results_file)

        print("\n✅ All tests complete!")

    except KeyboardInterrupt:
        print("\n\n⚠️  Tests interrupted by user")
    except Exception as e:
        print(f"\n\n❌ Error during testing: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
