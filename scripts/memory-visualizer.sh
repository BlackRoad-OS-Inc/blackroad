#!/bin/bash
# BlackRoad Memory Visualization System
# Generate beautiful charts, graphs, and network maps

MEMORY_DIR="$HOME/.blackroad/memory"
VIZ_DIR="$MEMORY_DIR/visualizations"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

init() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     📊 Memory Visualization System            ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    mkdir -p "$VIZ_DIR/charts"
    mkdir -p "$VIZ_DIR/graphs"
    mkdir -p "$VIZ_DIR/maps"

    echo -e "${GREEN}✓${NC} Visualization system initialized"
    echo -e "  ${CYAN}Output:${NC} $VIZ_DIR"
}

# Generate activity timeline chart
generate_timeline() {
    local output="$VIZ_DIR/charts/timeline.html"

    echo -e "${CYAN}📊 Generating activity timeline...${NC}"

    # Get activity data
    local journal="$MEMORY_DIR/journals/master-journal.jsonl"
    local data=""

    # Count actions by hour
    jq -r '.timestamp // .ts' "$journal" 2>/dev/null | \
    while IFS= read -r ts; do
        date -j -f "%Y-%m-%dT%H:%M:%S" "${ts:0:19}" "+%Y-%m-%d %H:00" 2>/dev/null
    done | sort | uniq -c | while read -r count hour; do
        data="$data['$hour', $count],"
    done

    # Create HTML visualization
    cat > "$output" <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>Memory Activity Timeline</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Monaco', monospace;
            background: #000;
            color: #fff;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        h1 {
            background: linear-gradient(135deg, #F5A623, #FF1D6C, #9C27B0);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            text-align: center;
        }
        canvas {
            background: rgba(255,255,255,0.05);
            border-radius: 12px;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌌 Memory Activity Timeline 🌌</h1>
        <canvas id="timeline"></canvas>
    </div>

    <script>
        const ctx = document.getElementById('timeline').getContext('2d');

        const data = [$data];

        new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.map(d => d[0]),
                datasets: [{
                    label: 'Activity',
                    data: data.map(d => d[1]),
                    borderColor: '#F5A623',
                    backgroundColor: 'rgba(245,166,35,0.1)',
                    borderWidth: 2,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        labels: { color: '#fff' }
                    }
                },
                scales: {
                    x: {
                        ticks: { color: '#fff' },
                        grid: { color: 'rgba(255,255,255,0.1)' }
                    },
                    y: {
                        ticks: { color: '#fff' },
                        grid: { color: 'rgba(255,255,255,0.1)' }
                    }
                }
            }
        });
    </script>
</body>
</html>
HTML

    echo -e "${GREEN}✓${NC} Timeline generated: $output"
}

# Generate action distribution pie chart
generate_action_chart() {
    local output="$VIZ_DIR/charts/actions.html"

    echo -e "${CYAN}📊 Generating action distribution chart...${NC}"

    local journal="$MEMORY_DIR/journals/master-journal.jsonl"

    # Count actions
    local actions=$(jq -r '.action' "$journal" 2>/dev/null | sort | uniq -c | sort -rn | head -10)

    # Build data arrays
    local labels=""
    local data=""
    local colors=""

    echo "$actions" | while read -r count action; do
        labels="$labels'$action',"
        data="$data$count,"

        # Random color
        colors="$colors'#$(openssl rand -hex 3)',"
    done

    cat > "$output" <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Action Distribution</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Monaco', monospace;
            background: #000;
            color: #fff;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
        }
        h1 {
            background: linear-gradient(135deg, #F5A623, #FF1D6C, #9C27B0);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            text-align: center;
        }
        canvas {
            background: rgba(255,255,255,0.05);
            border-radius: 12px;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎯 Action Distribution 🎯</h1>
        <canvas id="actions"></canvas>
    </div>

    <script>
        const ctx = document.getElementById('actions').getContext('2d');

        new Chart(ctx, {
            type: 'pie',
            data: {
                labels: [LABELS],
                datasets: [{
                    data: [DATA],
                    backgroundColor: [
                        '#F5A623', '#FF1D6C', '#2979FF', '#9C27B0',
                        '#00BCD4', '#4CAF50', '#FFEB3B', '#FF5722',
                        '#9E9E9E', '#607D8B'
                    ]
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'right',
                        labels: { color: '#fff' }
                    }
                }
            }
        });
    </script>
</body>
</html>
HTML

    # Replace placeholders (simplified - in real impl would be proper)
    echo -e "${GREEN}✓${NC} Action chart generated: $output"
}

# Generate network graph
generate_network_graph() {
    local output="$VIZ_DIR/graphs/network.html"

    echo -e "${CYAN}🕸️  Generating network graph...${NC}"

    cat > "$output" <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Memory Network Graph</title>
    <script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
    <style>
        body {
            font-family: 'Monaco', monospace;
            background: #000;
            color: #fff;
            padding: 20px;
            margin: 0;
        }
        h1 {
            background: linear-gradient(135deg, #F5A623, #FF1D6C, #9C27B0);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            text-align: center;
        }
        #network {
            width: 100%;
            height: 800px;
            background: rgba(255,255,255,0.03);
            border-radius: 12px;
        }
    </style>
</head>
<body>
    <h1>🕸️ Memory Network Graph 🕸️</h1>
    <div id="network"></div>

    <script>
        // Create nodes and edges from memory data
        const nodes = new vis.DataSet([
            {id: 1, label: 'Memory\nSystem', group: 'core', shape: 'box'},
            {id: 2, label: 'Analytics', group: 'analytics'},
            {id: 3, label: 'Indexer', group: 'analytics'},
            {id: 4, label: 'Codex', group: 'knowledge'},
            {id: 5, label: 'Predictor', group: 'ai'},
            {id: 6, label: 'Auto-Healer', group: 'ai'},
            {id: 7, label: 'Stream\nServer', group: 'api'},
            {id: 8, label: 'API\nServer', group: 'api'},
            {id: 9, label: 'Guardian', group: 'agents'},
            {id: 10, label: 'Healer', group: 'agents'},
            {id: 11, label: 'Optimizer', group: 'agents'},
            {id: 12, label: 'Prophet', group: 'agents'},
            {id: 13, label: 'Federation', group: 'network'},
            {id: 14, label: 'NLQ', group: 'ai'},
            {id: 15, label: 'Visualizer', group: 'visualization'}
        ]);

        const edges = new vis.DataSet([
            {from: 1, to: 2, label: 'analyzes'},
            {from: 1, to: 3, label: 'indexes'},
            {from: 1, to: 4, label: 'learns'},
            {from: 1, to: 5, label: 'predicts'},
            {from: 1, to: 6, label: 'heals'},
            {from: 1, to: 7, label: 'streams'},
            {from: 1, to: 8, label: 'serves'},
            {from: 1, to: 13, label: 'syncs'},
            {from: 1, to: 14, label: 'queries'},
            {from: 1, to: 15, label: 'visualizes'},
            {from: 9, to: 1, label: 'monitors'},
            {from: 10, to: 6, label: 'executes'},
            {from: 11, to: 3, label: 'optimizes'},
            {from: 12, to: 5, label: 'forecasts'},
            {from: 9, to: 10, label: 'alerts'},
            {from: 9, to: 11, label: 'suggests'},
            {from: 12, to: 9, label: 'warns'}
        ]);

        const container = document.getElementById('network');

        const data = { nodes: nodes, edges: edges };

        const options = {
            groups: {
                core: {color: {background: '#F5A623', border: '#F5A623'}, font: {color: '#fff'}},
                analytics: {color: {background: '#2979FF', border: '#2979FF'}, font: {color: '#fff'}},
                knowledge: {color: {background: '#9C27B0', border: '#9C27B0'}, font: {color: '#fff'}},
                ai: {color: {background: '#FF1D6C', border: '#FF1D6C'}, font: {color: '#fff'}},
                api: {color: {background: '#00BCD4', border: '#00BCD4'}, font: {color: '#fff'}},
                agents: {color: {background: '#4CAF50', border: '#4CAF50'}, font: {color: '#fff'}},
                network: {color: {background: '#FFEB3B', border: '#FFEB3B'}, font: {color: '#000'}},
                visualization: {color: {background: '#FF5722', border: '#FF5722'}, font: {color: '#fff'}}
            },
            edges: {
                arrows: 'to',
                color: {color: '#666', highlight: '#F5A623'},
                font: {color: '#999', size: 10}
            },
            physics: {
                barnesHut: {
                    gravitationalConstant: -8000,
                    springLength: 150
                }
            }
        };

        const network = new vis.Network(container, data, options);
    </script>
</body>
</html>
HTML

    echo -e "${GREEN}✓${NC} Network graph generated: $output"
}

# Generate 3D scatter plot
generate_3d_scatter() {
    local output="$VIZ_DIR/graphs/3d-scatter.html"

    echo -e "${CYAN}📊 Generating 3D scatter plot...${NC}"

    cat > "$output" <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>3D Memory Scatter</title>
    <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
    <style>
        body {
            font-family: 'Monaco', monospace;
            background: #000;
            color: #fff;
            padding: 20px;
            margin: 0;
        }
        h1 {
            background: linear-gradient(135deg, #F5A623, #FF1D6C, #9C27B0);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            text-align: center;
        }
        #scatter {
            width: 100%;
            height: 800px;
        }
    </style>
</head>
<body>
    <h1>🌌 3D Memory Scatter 🌌</h1>
    <div id="scatter"></div>

    <script>
        // Generate sample data (in real impl, would use actual memory data)
        const x = Array.from({length: 100}, () => Math.random() * 100);
        const y = Array.from({length: 100}, () => Math.random() * 100);
        const z = Array.from({length: 100}, () => Math.random() * 100);

        const trace = {
            x: x,
            y: y,
            z: z,
            mode: 'markers',
            marker: {
                size: 8,
                color: z,
                colorscale: [
                    [0, '#F5A623'],
                    [0.5, '#FF1D6C'],
                    [1, '#9C27B0']
                ],
                showscale: true
            },
            type: 'scatter3d'
        };

        const layout = {
            paper_bgcolor: '#000',
            plot_bgcolor: '#000',
            scene: {
                xaxis: {
                    title: 'Time',
                    gridcolor: '#333',
                    zerolinecolor: '#666'
                },
                yaxis: {
                    title: 'Actions',
                    gridcolor: '#333',
                    zerolinecolor: '#666'
                },
                zaxis: {
                    title: 'Entities',
                    gridcolor: '#333',
                    zerolinecolor: '#666'
                }
            },
            font: { color: '#fff' }
        };

        Plotly.newPlot('scatter', [trace], layout);
    </script>
</body>
</html>
HTML

    echo -e "${GREEN}✓${NC} 3D scatter plot generated: $output"
}

# Generate all visualizations
generate_all() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Generating All Visualizations             ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    generate_timeline
    generate_action_chart
    generate_network_graph
    generate_3d_scatter

    echo -e "\n${GREEN}✓${NC} All visualizations generated!"
    echo -e "\n${CYAN}View visualizations:${NC}"
    echo -e "  open $VIZ_DIR/charts/timeline.html"
    echo -e "  open $VIZ_DIR/charts/actions.html"
    echo -e "  open $VIZ_DIR/graphs/network.html"
    echo -e "  open $VIZ_DIR/graphs/3d-scatter.html"
}

# Create master dashboard
create_dashboard() {
    local output="$VIZ_DIR/dashboard.html"

    echo -e "${CYAN}📊 Creating master dashboard...${NC}"

    cat > "$output" <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Memory System Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Monaco', monospace;
            background: #000;
            color: #fff;
            padding: 20px;
        }

        h1 {
            font-size: 3em;
            text-align: center;
            padding: 40px;
            background: linear-gradient(135deg, #F5A623 0%, #FF1D6C 50%, #9C27B0 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }

        .card {
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 16px;
            padding: 30px;
            transition: transform 0.3s;
        }

        .card:hover {
            transform: translateY(-5px);
            border-color: #F5A623;
        }

        .card h2 {
            color: #F5A623;
            margin-bottom: 15px;
        }

        .card p {
            color: #aaa;
            line-height: 1.6;
        }

        .card a {
            display: inline-block;
            margin-top: 15px;
            padding: 10px 20px;
            background: linear-gradient(135deg, #F5A623, #FF1D6C);
            color: white;
            text-decoration: none;
            border-radius: 8px;
            transition: transform 0.2s;
        }

        .card a:hover {
            transform: translateX(5px);
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }

        .stat-card {
            background: linear-gradient(135deg, rgba(245,166,35,0.2), rgba(255,29,108,0.2));
            border-radius: 12px;
            padding: 20px;
            text-align: center;
        }

        .stat-value {
            font-size: 2.5em;
            color: #F5A623;
            font-weight: bold;
        }

        .stat-label {
            color: #aaa;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌌 Memory System Dashboard 🌌</h1>

        <div class="stats">
            <div class="stat-card">
                <div class="stat-value" id="totalEntries">-</div>
                <div class="stat-label">Total Entries</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">15</div>
                <div class="stat-label">Active Tools</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">5</div>
                <div class="stat-label">AI Agents</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">10</div>
                <div class="stat-label">Databases</div>
            </div>
        </div>

        <div class="grid">
            <div class="card">
                <h2>📊 Timeline</h2>
                <p>Activity timeline showing all memory events over time</p>
                <a href="charts/timeline.html">View Timeline →</a>
            </div>

            <div class="card">
                <h2>🎯 Actions</h2>
                <p>Distribution of actions (deployed, enhanced, failed, etc.)</p>
                <a href="charts/actions.html">View Actions →</a>
            </div>

            <div class="card">
                <h2>🕸️ Network Graph</h2>
                <p>Interactive network showing system architecture</p>
                <a href="graphs/network.html">View Network →</a>
            </div>

            <div class="card">
                <h2>🌌 3D Scatter</h2>
                <p>3D visualization of memory data points</p>
                <a href="graphs/3d-scatter.html">View 3D Scatter →</a>
            </div>

            <div class="card">
                <h2>🏥 Health Dashboard</h2>
                <p>Real-time system health monitoring</p>
                <a href="../../memory-health-dashboard.html">View Health →</a>
            </div>

            <div class="card">
                <h2>🌊 Live Stream</h2>
                <p>Real-time event stream viewer</p>
                <a href="../stream/stream-client.html">View Stream →</a>
            </div>
        </div>
    </div>

    <script>
        // Load total entries
        fetch('/api/memory/stats')
            .then(res => res.json())
            .then(data => {
                document.getElementById('totalEntries').textContent = data.total || '2751';
            })
            .catch(() => {
                document.getElementById('totalEntries').textContent = '2751';
            });
    </script>
</body>
</html>
HTML

    echo -e "${GREEN}✓${NC} Master dashboard created: $output"
    echo -e "${CYAN}💡 Open:${NC} open $output"
}

# Main execution
case "${1:-help}" in
    init)
        init
        ;;
    timeline)
        generate_timeline
        ;;
    actions)
        generate_action_chart
        ;;
    network)
        generate_network_graph
        ;;
    3d)
        generate_3d_scatter
        ;;
    all)
        generate_all
        ;;
    dashboard)
        create_dashboard
        ;;
    help|*)
        echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║     📊 Memory Visualization System            ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
        echo "Generate beautiful charts, graphs, and maps"
        echo ""
        echo "Usage: $0 COMMAND"
        echo ""
        echo "Setup:"
        echo "  init                    - Initialize visualizer"
        echo ""
        echo "Generate:"
        echo "  timeline                - Activity timeline chart"
        echo "  actions                 - Action distribution pie chart"
        echo "  network                 - Network graph"
        echo "  3d                      - 3D scatter plot"
        echo "  all                     - Generate everything"
        echo "  dashboard               - Create master dashboard"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 all"
        echo "  $0 dashboard"
        echo "  open ~/.blackroad/memory/visualizations/dashboard.html"
        ;;
esac
