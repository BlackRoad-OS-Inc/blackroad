"""
RoadDashboard - Dashboard Data for BlackRoad
Aggregate and serve dashboard data with widgets and real-time updates.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional
import asyncio
import json
import logging
import threading
import time

logger = logging.getLogger(__name__)


class WidgetType(str, Enum):
    METRIC = "metric"
    CHART = "chart"
    TABLE = "table"
    LIST = "list"
    GAUGE = "gauge"
    TEXT = "text"


class RefreshMode(str, Enum):
    MANUAL = "manual"
    INTERVAL = "interval"
    REALTIME = "realtime"


@dataclass
class WidgetConfig:
    id: str
    type: WidgetType
    title: str
    data_source: Callable[[], Any]
    refresh_interval: int = 60
    refresh_mode: RefreshMode = RefreshMode.INTERVAL
    style: Dict[str, Any] = field(default_factory=dict)
    options: Dict[str, Any] = field(default_factory=dict)


@dataclass
class WidgetData:
    widget_id: str
    data: Any
    timestamp: datetime = field(default_factory=datetime.now)
    error: Optional[str] = None


@dataclass
class MetricValue:
    value: float
    label: str = ""
    change: Optional[float] = None
    change_period: str = ""
    trend: str = ""  # up, down, flat
    format: str = ""  # number, currency, percent


class Widget:
    def __init__(self, config: WidgetConfig):
        self.config = config
        self._last_data: Optional[WidgetData] = None
        self._last_refresh: Optional[datetime] = None

    async def refresh(self) -> WidgetData:
        try:
            result = self.config.data_source()
            if asyncio.iscoroutine(result):
                result = await result
            
            self._last_data = WidgetData(widget_id=self.config.id, data=result)
            self._last_refresh = datetime.now()
            return self._last_data
        except Exception as e:
            logger.error(f"Widget {self.config.id} refresh error: {e}")
            return WidgetData(widget_id=self.config.id, data=None, error=str(e))

    def needs_refresh(self) -> bool:
        if self.config.refresh_mode == RefreshMode.MANUAL:
            return False
        if self._last_refresh is None:
            return True
        elapsed = (datetime.now() - self._last_refresh).total_seconds()
        return elapsed >= self.config.refresh_interval

    def get_data(self) -> Optional[WidgetData]:
        return self._last_data

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.config.id,
            "type": self.config.type.value,
            "title": self.config.title,
            "data": self._last_data.data if self._last_data else None,
            "timestamp": self._last_data.timestamp.isoformat() if self._last_data else None,
            "error": self._last_data.error if self._last_data else None,
            "options": self.config.options
        }


@dataclass
class DashboardConfig:
    id: str
    name: str
    description: str = ""
    layout: List[List[str]] = field(default_factory=list)  # Grid of widget IDs
    refresh_interval: int = 60
    metadata: Dict[str, Any] = field(default_factory=dict)


class Dashboard:
    def __init__(self, config: DashboardConfig):
        self.config = config
        self.widgets: Dict[str, Widget] = {}
        self._lock = threading.Lock()

    def add_widget(self, widget: Widget) -> None:
        with self._lock:
            self.widgets[widget.config.id] = widget

    def remove_widget(self, widget_id: str) -> bool:
        with self._lock:
            if widget_id in self.widgets:
                del self.widgets[widget_id]
                return True
            return False

    async def refresh_all(self) -> Dict[str, WidgetData]:
        results = {}
        for widget_id, widget in self.widgets.items():
            results[widget_id] = await widget.refresh()
        return results

    async def refresh_stale(self) -> Dict[str, WidgetData]:
        results = {}
        for widget_id, widget in self.widgets.items():
            if widget.needs_refresh():
                results[widget_id] = await widget.refresh()
        return results

    def get_data(self) -> Dict[str, Any]:
        return {
            "id": self.config.id,
            "name": self.config.name,
            "widgets": {wid: w.to_dict() for wid, w in self.widgets.items()},
            "layout": self.config.layout,
            "timestamp": datetime.now().isoformat()
        }


class DashboardBuilder:
    def __init__(self, dashboard_id: str, name: str):
        self.config = DashboardConfig(id=dashboard_id, name=name)
        self.widgets: List[Widget] = []
        self._layout: List[List[str]] = []

    def description(self, desc: str) -> "DashboardBuilder":
        self.config.description = desc
        return self

    def metric(self, widget_id: str, title: str, data_source: Callable, **options) -> "DashboardBuilder":
        config = WidgetConfig(id=widget_id, type=WidgetType.METRIC, title=title, data_source=data_source, options=options)
        self.widgets.append(Widget(config))
        return self

    def chart(self, widget_id: str, title: str, data_source: Callable, chart_type: str = "line", **options) -> "DashboardBuilder":
        options["chart_type"] = chart_type
        config = WidgetConfig(id=widget_id, type=WidgetType.CHART, title=title, data_source=data_source, options=options)
        self.widgets.append(Widget(config))
        return self

    def table(self, widget_id: str, title: str, data_source: Callable, **options) -> "DashboardBuilder":
        config = WidgetConfig(id=widget_id, type=WidgetType.TABLE, title=title, data_source=data_source, options=options)
        self.widgets.append(Widget(config))
        return self

    def gauge(self, widget_id: str, title: str, data_source: Callable, min_val: float = 0, max_val: float = 100, **options) -> "DashboardBuilder":
        options.update({"min": min_val, "max": max_val})
        config = WidgetConfig(id=widget_id, type=WidgetType.GAUGE, title=title, data_source=data_source, options=options)
        self.widgets.append(Widget(config))
        return self

    def row(self, *widget_ids: str) -> "DashboardBuilder":
        self._layout.append(list(widget_ids))
        return self

    def build(self) -> Dashboard:
        self.config.layout = self._layout
        dashboard = Dashboard(self.config)
        for widget in self.widgets:
            dashboard.add_widget(widget)
        return dashboard


class DashboardManager:
    def __init__(self):
        self.dashboards: Dict[str, Dashboard] = {}
        self._refresh_task = None
        self._running = False

    def create(self, dashboard_id: str, name: str) -> DashboardBuilder:
        return DashboardBuilder(dashboard_id, name)

    def register(self, dashboard: Dashboard) -> None:
        self.dashboards[dashboard.config.id] = dashboard

    def get(self, dashboard_id: str) -> Optional[Dashboard]:
        return self.dashboards.get(dashboard_id)

    async def refresh(self, dashboard_id: str) -> Optional[Dict[str, WidgetData]]:
        dashboard = self.dashboards.get(dashboard_id)
        if dashboard:
            return await dashboard.refresh_all()
        return None

    async def start_auto_refresh(self, interval: int = 60) -> None:
        self._running = True
        while self._running:
            for dashboard in self.dashboards.values():
                await dashboard.refresh_stale()
            await asyncio.sleep(interval)

    def stop_auto_refresh(self) -> None:
        self._running = False

    def list_dashboards(self) -> List[Dict[str, str]]:
        return [{"id": d.config.id, "name": d.config.name} for d in self.dashboards.values()]

    def get_data(self, dashboard_id: str) -> Optional[Dict[str, Any]]:
        dashboard = self.dashboards.get(dashboard_id)
        if dashboard:
            return dashboard.get_data()
        return None


async def example_usage():
    manager = DashboardManager()
    
    # Data sources
    def get_total_users():
        return MetricValue(value=1234, label="Total Users", change=12.5, trend="up")
    
    def get_revenue():
        return MetricValue(value=98765, label="Revenue", format="currency", change=-2.3, trend="down")
    
    def get_chart_data():
        return {"labels": ["Jan", "Feb", "Mar"], "values": [100, 150, 130]}
    
    def get_recent_orders():
        return [
            {"id": 1, "customer": "Alice", "amount": 150},
            {"id": 2, "customer": "Bob", "amount": 200},
        ]
    
    def get_cpu_usage():
        return 65.5
    
    dashboard = (
        manager.create("main", "Main Dashboard")
        .description("Overview of key metrics")
        .metric("users", "Total Users", get_total_users)
        .metric("revenue", "Revenue", get_revenue)
        .chart("sales_chart", "Sales Over Time", get_chart_data, chart_type="line")
        .table("orders", "Recent Orders", get_recent_orders)
        .gauge("cpu", "CPU Usage", get_cpu_usage, min_val=0, max_val=100)
        .row("users", "revenue")
        .row("sales_chart")
        .row("orders", "cpu")
        .build()
    )
    
    manager.register(dashboard)
    await manager.refresh("main")
    
    data = manager.get_data("main")
    print(f"Dashboard: {data['name']}")
    print(f"Widgets: {len(data['widgets'])}")
    for wid, widget in data["widgets"].items():
        print(f"  {wid}: {widget['title']} = {widget['data']}")
