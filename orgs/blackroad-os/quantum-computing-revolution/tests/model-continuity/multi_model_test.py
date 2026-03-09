#!/usr/bin/env python3
"""
Multi-Model Continuity Testing Framework
Tests reasoning and context continuity across different LLM models
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
        
    def query_model(self, node: str, model: str, prompt: str, context: str = "") -> Dict[str, Any]:
        """Query a model via Ollama"""
        full_prompt = f"{context}\n\n{prompt}" if context else prompt
        
        cmd = [
            "ssh", node,
            f"ollama run {model} '{full_prompt}'"
        ]
        
        start_time = time.time()
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=60
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
                "error": "Timeout after 60s",
                "duration": 60.0,
                "node": node,
                "model": model
            }
    
    def test_reasoning_continuity(self) -> Dict[str, Any]:
        """Test if models can continue reasoning from previous context"""
        
        print("="*80)
        print("🧠 REASONING CONTINUITY TEST")
        print("="*80)
        
        # Initial context: Quantum computing question
        initial_question = """What is the fundamental difference between a transistor 
in a classical computer and a qubit in a quantum computer? Give a brief answer."""
        
        # Follow-up that requires understanding the previous answer
        followup_question = """Based on that difference, explain why room temperature 
operation is easier for one than the other. Be concise."""
        
        results = {
            "test_name": "reasoning_continuity",
            "timestamp": datetime.now().isoformat(),
            "models_tested": [],
            "results": []
        }
        
        # Test on different models
        test_configs = [
            {"node": "octavia", "model": "phi3.5:latest"},
            {"node": "octavia", "model": "tinyllama:latest"},
        ]
        
        for config in test_configs:
            print(f"\n📊 Testing {config['model']} on {config['node']}")
            print("-"*80)
            
            # Initial query
            print("Initial question...")
            initial_response = self.query_model(
                config["node"],
                config["model"],
                initial_question
            )
            
            if not initial_response["success"]:
                print(f"❌ Initial query failed: {initial_response['error']}")
                continue
            
            print(f"✓ Response: {initial_response['response'][:200]}...")
            
            # Follow-up with context
            print("\nFollow-up question with context...")
            context = f"Previous question: {initial_question}\nYour answer: {initial_response['response']}"
            
            followup_response = self.query_model(
                config["node"],
                config["model"],
                followup_question,
                context=context
            )
            
            if followup_response["success"]:
                print(f"✓ Follow-up: {followup_response['response'][:200]}...")
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
        initial_task = "Start counting from 1 to 5, but only give me the first 3 numbers."
        continuation_task = "Continue the counting sequence with the next 2 numbers."
        
        results = {
            "test_name": "context_transfer",
            "timestamp": datetime.now().isoformat(),
            "transfers": []
        }
        
        # Model A starts
        model_a_config = {"node": "octavia", "model": "phi3.5:latest"}
        print(f"\n📤 Starting with {model_a_config['model']}")
        
        response_a = self.query_model(
            model_a_config["node"],
            model_a_config["model"],
            initial_task
        )
        
        print(f"✓ {model_a_config['model']}: {response_a['response']}")
        
        # Model B continues
        model_b_config = {"node": "octavia", "model": "tinyllama:latest"}
        print(f"\n📥 Continuing with {model_b_config['model']}")
        
        context = f"Previous task: {initial_task}\nPrevious response: {response_a['response']}"
        
        response_b = self.query_model(
            model_b_config["node"],
            model_b_config["model"],
            continuation_task,
            context=context
        )
        
        print(f"✓ {model_b_config['model']}: {response_b['response']}")
        
        transfer_result = {
            "from_model": model_a_config["model"],
            "to_model": model_b_config["model"],
            "context_preserved": "4" in response_b["response"] or "5" in response_b["response"],
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
        
        # Complex problem that can be broken into parts
        problem = """I have a quantum computer with 4 billion transistors. 
If each transistor can be in 2 states, theoretically how many total states 
could the system represent? Just give the formula, not the calculation."""
        
        results = {
            "test_name": "distributed_reasoning",
            "timestamp": datetime.now().isoformat(),
            "nodes_used": [],
            "responses": []
        }
        
        # Query multiple nodes simultaneously (conceptually)
        test_nodes = [
            {"node": "octavia", "model": "phi3.5:latest"},
            {"node": "lucidia", "model": "phi3.5:latest"} if self.check_model_available("lucidia", "phi3.5") else {"node": "octavia", "model": "tinyllama:latest"}
        ]
        
        for config in test_nodes:
            print(f"\n🔍 Querying {config['model']} on {config['node']}")
            
            response = self.query_model(
                config["node"],
                config["model"],
                problem
            )
            
            if response["success"]:
                print(f"✓ Response: {response['response'][:150]}...")
                results["nodes_used"].append(config["node"])
                results["responses"].append(response)
        
        self.test_results.append(results)
        return results
    
    def check_model_available(self, node: str, model: str) -> bool:
        """Check if a model is available on a node"""
        try:
            result = subprocess.run(
                ["ssh", node, f"ollama list | grep {model}"],
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.returncode == 0
        except:
            return False
    
    def generate_report(self) -> str:
        """Generate comprehensive test report"""
        
        report = f"""
════════════════════════════════════════════════════════════════════════════════
🧪 MULTI-MODEL CONTINUITY TEST REPORT
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
Transfer: {transfer['from_model']} → {transfer['to_model']}
  Context Preserved: {'✓ Yes' if transfer['context_preserved'] else '✗ No'}
  Time: {transfer['initial_response']['duration'] + transfer['continuation_response']['duration']:.2f}s
"""
            
            elif test['test_name'] == 'distributed_reasoning':
                report += f"Nodes Used: {', '.join(test['nodes_used'])}\n"
                report += f"Responses: {len(test['responses'])}\n"
        
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
║          🌌 MULTI-MODEL CONTINUITY TESTING FRAMEWORK 🌌                      ║
║                                                                               ║
║     Testing reasoning and context continuity across different LLM models     ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
""")
    
    # Define cluster nodes
    nodes = {
        "octavia": "192.168.4.81",
        "lucidia": "192.168.4.38",
        "aria": "192.168.4.82",
        "shellfish": "174.138.44.45"
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
        results_file = f"model_continuity_results_{timestamp}.json"
        tester.save_results(results_file)
        
        print("\n✅ All tests complete!")
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Tests interrupted by user")
    except Exception as e:
        print(f"\n\n❌ Error during testing: {e}")


if __name__ == "__main__":
    main()
